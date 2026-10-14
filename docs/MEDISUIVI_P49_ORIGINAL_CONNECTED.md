# P4.9 / P4.9.1 : UI originale raccordée à FastAPI

## Architecture retenue

L'application installée et sa navigation restent celles de `MainShell` :
`HomeScreen`, `PatientsScreen`, `ExamsScreen`, `FollowupScreen`,
`SettingsScreen` et leurs écrans détaillés. Le tableau de bord provisoire
`DevConnectedWorkspace` n'est **jamais monté** dans le parcours connecté.

- `MediSuiviWelcomeGate` conserve le parcours d'introduction et ouvre le
  compte praticien après authentification.
- `OriginalAccountAccessScreen` : connexion/inscription sans photo dans la
  palette existante. Pas de réutilisation de la deuxième UI.
- `OriginalConnectedClinicalGate` : n'affiche l'original `MainShell` que
  lorsque la synchronisation initiale de **ce compte** a réussi.
- `ConnectedClinicalStore` : implémentation de l'interface `ClinicalStore`
  déjà utilisée par les écrans. Toutes ses lectures passent par les routes
  JWT de FastAPI. Les écritures passent par l'API, puis les listes sont
  rafraîchies. Une erreur bloque l'affichage du cache précédent.
- `BuildContext.store` privilégie `ConnectedClinicalScope`; en mode connecté
  ni les dossiers `DemoStore`, ni la base commune `medisuivi.db` ne sont ouverts.
- `DevAuthApi` garde les protections réseau, les jetons, le rafraîchissement
  et l'invalidation des réponses tardives déjà testées.
- Les données de profil sont liées à la session, jamais à l'espace démo.

## Champs du backend

La migration **additive** `0006` préserve les anciens dossiers et ajoute
aux modèles originaux les coordonnées, antécédents, compléments de profil,
suivis signalés et bilan structuré des consultations.

Les API suivent la propriété stricte `owner_user_id`, dérivée du JWT.
Les routes d'écriture restent interdites hors environnement de développement.
**Seules les données cliniques entièrement fictives peuvent être utilisées.**

Les tests PostgreSQL CI utilisent la base jetable `medisuivi_ci`, jamais
`medisuivi_pgdata` sur l'ordinateur.

## Première vérification Firefox sans migration (lecture seule)

Laisser le backend MediSuivi existant actif sur `127.0.0.1:8027`.
Ne pas toucher à l'ERP ou à PostgreSQL.

```bash
cd /mnt/chak/medisuivi-flutter
git fetch origin feat/medisuivi-p49-1-clinical-fields-api
git worktree add --detach /mnt/chak/medisuivi-p49-original \
  origin/feat/medisuivi-p49-1-clinical-fields-api
cd /mnt/chak/medisuivi-p49-original
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 \
  --dart-define=MEDISUIVI_DEV_API_BASE_URL=http://127.0.0.1:8027
```

Ouvrir `http://127.0.0.1:8080` dans Firefox. Arrêter l'ancien serveur Web
qui occupe 8080 **dans son propre terminal** avec `Ctrl+C` au préalable.
Ne pas désinstaller ni écraser des applications mobiles.

En se reconnectant à un **compte fictif existant**, on doit retrouver le
véritable accueil initial avec son fond, sa navigation, ses dossiers, les
examens et les suivis de ce praticien. Tester d'abord la lecture seule :
les opérations d'écriture complémentaires dépendent de la migration 0006
sur le backend local. Le site Web ne conserve pas de jetons persistants.

## Avant application locale de la migration 0006

Ne lancer aucun `alembic upgrade` dans la base locale avant :
1. vérifier toutes les CI du dernier commit sur PR #45 ;
2. effectuer une **nouvelle sauvegarde** `pg_dump -Fc` du volume actuel
   `medisuivi_pgdata`, vérifier `pg_restore -l` ;
3. enregistrer le nombre d'identifiants des praticiens et patients ainsi que
   leurs empreintes SQL ;
4. confirmer que seuls les conteneurs `medisuivi-*` seront touchés ;
5. construire le backend API de cette branche avec les secrets
   **existants**, sans les exposer au terminal/logs et sans générer
   une nouvelle clé JWT ;
6. appliquer la migration, confirmer `0006`, `/ready`, `/health`,
   et les dossiers fictifs A/B après relancement.

**Ne jamais exécuter** `docker compose down -v`,
`--remove-orphans`, `docker volume rm` ou `alembic downgrade`.
Le volume source `backend_pgdata` et la sauvegarde de P4.4 sont conservés.

## Recette fonctionnelle

1. Connexion du praticien fictif A : afficher uniquement ses dossiers.
2. Accueil original / registre / détail patient / examen / suivi / paramètres.
3. Créer un `PATIENT FICTIF ...`, saisir les champs et confirmer qu'ils
   persistent après reconnexion. Aucun vrai dossier.
4. Ajouter une consultation fictive avec bilan structuré.
5. Ajouter un examen, enregistrer un résultat de démonstration.
6. Programmer et clore un suivi fictif.
7. Modifier le téléphone et la spécialité du profil, vérifier côté API.
8. Déconnecter A et ouvrir B ; aucune information de A dans B.
9. Redémarrer Firefox et revérifier les dossiers persistés sur PostgreSQL.
10. Simuler une API indisponible : aucun ancien cache clinique ne doit
    apparaître à la place de l'erreur de chargement.

Les mécanismes offline/SQLite chiffré et le déploiement public ne deviennent
pas automatiquement validés par ces essais Web : tests complémentaires
obligatoires avant tout usage réel.
