# Sprint P3.1 : connexion Flutter réelle en développement (Sénégal)

**Uniquement pour des comptes et patients synthétiques.**
Cette branche **ne doit pas** être rendue accessible à des personnes réelles ou à
des praticiens avec de vrais dossiers. Elle n'est pas une mise en production.

## Architecture actuelle

- `MediSuiviWelcomeGate` conserve son parcours original (splash, introduction
  et démonstration).
- Sans configuration explicite, la page de connexion garde son statut
  **indisponible** et « Créer un compte » ouvre l'aperçu local historique.
- Avec `MEDISUIVI_DEV_API_BASE_URL`, les mêmes boutons ouvrent des
  formulaires `DevAuthScreen` qui appellent réellement le backend.
- Le résultat est un `DevConnectedWorkspace` **isolé de DemoStore** :
  aucun patient de la démonstration Web ou du stockage mobile existant n'y est
  chargé ; les dossiers fictifs proviennent exclusivement de l'API avec le
  JWT du compte.
- Les jetons restent en mémoire et sont perdus à la fermeture. Pas de cache
  clinique local multi-compte avant la conception de clés distinctes.
- La création d'un patient côté interface génère un nom `PATIENT FICTIF`
  automatiquement, sans champ libre invitant à saisir un vrai nom.

## Démarrer le backend en local

Dans un terminal Ubuntu (variables **non** committées) :

```bash
cd /mnt/chak/medisuivi-flutter/backend
export POSTGRES_PASSWORD="$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')"
export APP_JWT_SECRET="$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')"
export APP_ALLOW_DEVELOPMENT_REGISTRATION=true

docker compose up -d --build
docker compose exec api python -m scripts.init_dev_db
curl --noproxy '*' -sS http://127.0.0.1:8027/health
curl --noproxy '*' -sS http://127.0.0.1:8027/ready
```

**Si PostgreSQL existe déjà avec des données de test** : réutiliser ses
identifiants existants, ne pas changer le mot de passe au hasard et **ne pas
supprimer le volume** pour « réparer » une connexion. Aucun reset
automatique, aucune migration de patients réels.

L'inscription est inactive par défaut. Son activation `true` n'est acceptable
qu'en développement sur l'interface loopback.

## Lancer l'app sur Firefox

Dans un second terminal :

```bash
cd /mnt/chak/medisuivi-flutter
flutter pub get
flutter run -d web-server \\
  --web-hostname 127.0.0.1 --web-port 8080 \\
  --dart-define=MEDISUIVI_DEV_API_BASE_URL=http://127.0.0.1:8027
```

Ouvrir `http://127.0.0.1:8080`. Après le splash et l'introduction,
choisir « Créer un compte » ou « Se connecter ». Créer **deux comptes fictifs
distincts** et vérifier que leurs listes de patients ne se mélangent pas.

Sans le `--dart-define`, seul le parcours précédent de démonstration est actif.
L'API autorise uniquement `http://127.0.0.1:8080` et `http://localhost:8080`
en développement CORS. Pas d'accès distant, pas de CORS `*`.

## Limites et prochaine étape P3.2

- API locale uniquement, **pas de comptes prêts pour la production**.
- Aucune vérification e-mail, MFA, récupération de mot de passe ou limitation
  des tentatives de connexion.
- Pas de persistance de session (token volatile), ni d'avatar serveur.
- Les tables cliniques backend sont encore un **sous-ensemble** des informations
  du formulaire Flutter. Le stockage SQLite local historique doit être
  partitionné par compte **avant** d'associer un dossier mobile réel.
- Avant une ouverture publique : audits, sécurité, gestion des sessions
  multi-appareils, migrations réversibles/contrôlées, conformité CDP et tests
  physiques Web/Android.
- **Ne jamais utiliser de vrais dossiers médicaux dans cette version.**
