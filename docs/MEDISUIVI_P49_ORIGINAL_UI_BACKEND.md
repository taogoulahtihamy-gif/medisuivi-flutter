# MediSuivi P4.9 : interface originale connectée à FastAPI

## Architecture retenue

L'application d'origine est conservée **sans reprendre le tableau de bord P4.8 abandonné** :

```text
MediSuiviWelcomeGate (onboarding d'origine)
  -> authentification praticien JWT
  -> RemoteClinicalGateway (chargement avant affichage)
  -> RemoteClinicalScope (session + RemoteClinicalStore)
  -> MainShell ORIGINAL, inchangé
     -> HomeScreen / PatientsScreen / ExamsScreen / FollowupScreen / SettingsScreen
        -> context.store : ClinicalStore
           -> RemoteClinicalStore -> DevAuthApi -> FastAPI -> PostgreSQL
```

Les écrans de dossier, consultation et examens restent accessibles via le Navigator imbriqué sous `RemoteClinicalScope`. La navigation, les couleurs, les cartes et le dock originaux ne sont pas remplacés.

La couche de données `DevAuthApi` est réutilisée **uniquement comme transport HTTP et gestion de session**, jamais comme deuxième interface. Les formulaires d'accès/reconnexion/récupération utilisent le langage visuel des pages MediSuivi originales et aucun écran de `dev_auth_screens.dart` n'est monté dans le parcours connecté.

## Garde-fous

- Aucun `DemoStore` monté dans un build connecté ; chargement complet depuis les routes de l'utilisateur du JWT avant d'afficher `MainShell`.
- Si FastAPI ne répond pas : écran bloqué avec réessai, **jamais** d'affichage des dossiers d'un autre praticien ni de données de démonstration.
- Les lectures sont rechargées atomiquement. Les réponses tardives d'une session invalidée sont rejetées.
- Les consultations, examens et suivis sont toujours rattachés aux identifiants patient/owner authentifiés et contrôlés dans l'API.
- Une déconnexion purge immédiatement le cache clinique en mémoire, y compris en cas d'indisponibilité du serveur. Sur Web, aucune sauvegarde navigateur du JWT.
- **Pas de mode hors ligne synchronisé dans ce parcours pour l'instant.** Pas d'écritures sauvegardées silencieusement hors connexion.
- Données **strictement fictives**. Pas de déploiement médical réel.

## Backend : migration additive 0006

Le backend P4.9 ajoute à `patients` : sexe, téléphone, allergies, antécédents, drapeau de suivi, complément de dossier JSON ; à `visits` : bilan clinique JSON. Les anciens comptes et les UUID sont conservés. Les nouvelles routes de modification de dossier et de drapeau de suivi vérifient l'appartenance au praticien et renvoient HTTP 404 au compte B.

**Il est impératif de ne pas lancer le frontend P4.9 contre un backend encore en migration 0005** : le serveur doit d'abord être mis à jour sur 0006.

## 1. Préparer un worktree indépendant sans toucher aux fichiers de l'éditeur

Sur Ubuntu, avec les modifications Git locales du dépôt principal intactes :

```bash
cd /mnt/chak/medisuivi-flutter
git fetch origin feat/medisuivi-p49-original-ui-api-integration

# Exécuter uniquement si le répertoire n'existe PAS :
git worktree add --detach /mnt/chak/medisuivi-p49-original \
  origin/feat/medisuivi-p49-original-ui-api-integration

cd /mnt/chak/medisuivi-p49-original
flutter pub get
flutter test test/p49_remote_clinical_store_test.dart \
  test/p3_dev_auth_flow_test.dart test/p42_session_gate_test.dart
```

Si le worktree existe déjà, inspecter `git status` et réutiliser le dossier ; ne pas écraser ou effacer des changements.

## 2. Sauvegarder et migrer uniquement MediSuivi, pas l'ERP

Vérifier d'abord que `medisuivi-api-1` et `medisuivi-postgres-1` sont sains et que le service `/ready` répond. Ne pas copier ni effacer `medisuivi_pgdata`, `backend_pgdata`, `erp_postgres_data`.

La procédure versionnée `scripts/p49_safe_local_backend_upgrade.sh` vérifie les labels Docker, les volumes, crée une sauvegarde privée PostgreSQL (`pg_dump -Fc`), vérifie son archive, reconstruit l'API, applique `alembic upgrade head` et contrôle les comptes de lignes/empreintes des identifiants avant de conclure. Elle ne cible que `-p medisuivi`.

Après revue du script et CI verte :

```bash
cd /mnt/chak/medisuivi-p49-original
bash scripts/p49_safe_local_backend_upgrade.sh
```

Il est normal que le script doive arrêter **brièvement l'API MediSuivi**. L'ancien volume et le nouveau fichier de sauvegarde ne sont pas supprimés. Si une étape échoue, le script tente de restaurer l'ancienne image de l'API. La migration additive reste dans PostgreSQL, sans rollback destructif.

Vérifier après succès :

```bash
docker exec medisuivi-postgres-1 psql -Atq -U medisuivi -d medisuivi \
  -c 'SELECT version_num FROM alembic_version;'
curl --noproxy '*' -fsS http://127.0.0.1:8027/health
curl --noproxy '*' -fsS http://127.0.0.1:8027/ready
```

Attendu : `0006`, `{"status":"ok","environment":"non-production"}`, `{"ready":true}`.

## 3. Tester la vraie interface MediSuivi dans Firefox

Fermer **uniquement l'ancien `flutter run`** (Ctrl+C dans son terminal) pour libérer le port 8080. Ne pas fermer VS Code.

```bash
cd /mnt/chak/medisuivi-p49-original
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 \
  --dart-define=MEDISUIVI_DEV_API_BASE_URL=http://127.0.0.1:8027
```

Laisser le terminal actif et ouvrir un deuxième terminal ou Firefox :
`http://127.0.0.1:8080`.

Le navigateur doit afficher l'onboarding originel, la connexion, puis **le vrai accueil MediSuivi original avec son bandeau photo et son dock à cinq destinations (Accueil, Patients, Bilans, Suivi, Réglages)**, pas le tableau de bord technique P4.8.

## 4. Recette utilisateurs fictifs A/B

1. Se connecter au compte fictif A existant ; vérifier que ses dossiers sont exactement ceux de PostgreSQL.
2. Ouvrir les cinq onglets originaux et le détail d'un patient, sans changement d'apparence.
3. Créer un dossier entièrement fictif depuis le formulaire original, renseigner sexe/téléphone/supplément, vérifier le résultat après rechargement.
4. Saisir une consultation avec constantes et bilan clinique fictifs, un bilan/examen et un suivi ; vérifier la persistance à la reconnexion.
5. Ouvrir Réglages, modifier le profil serveur puis changer de praticien.
6. Se connecter à un deuxième compte B ; aucun patient/examen/suivi du compte A ne doit apparaître. Vérifier la gestion des erreurs de connexion sans fallback démo.
7. Revenir sur A et retrouver uniquement ses dossiers, sans transfert des données du compte B.

**Ne jamais envoyer au chat de mots de passe, jetons JWT, identifiants de connexion ou documents de santé.**

## Limitations documentées

Le mode connecté utilise aujourd'hui un cache **en mémoire** et un rechargement total des ressources cliniques de chaque patient. Pour un grand volume, prévoir pagination/agrégation côté API avant production. L'accès hors ligne chiffré/synchronisation par compte est une phase distincte. Le staging Render P4.7 refuse volontairement les écritures ; les tests fonctionnels d'écriture P4.9 se font **uniquement en développement contrôlé** sur les dossiers fictifs.
