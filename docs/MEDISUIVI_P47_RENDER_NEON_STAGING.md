# MediSuivi P4.7 : staging gratuit sur Render + Neon

**Environnement de validation technique exclusivement.** Aucune donnée de santé réelle, aucun compte médical réel, aucun dossier récupéré depuis le Docker local. Le backend interdit explicitement `APP_ENV=production`.

## 1. Pourquoi Render + Neon plutôt que LWS mutualisé ?

MediSuivi utilise une application **ASGI FastAPI/Uvicorn**, des migrations Alembic et PostgreSQL. Un hébergement LWS mutualisé/cPanel n'assure pas nécessairement un service ASGI persistant. Ne pas contourner ses limites par une API accessible sans TLS ou un processus de fond non supervisé.

- **Render Free** : service Python Web avec certificat HTTPS, suspendu au bout de 15 minutes d'inactivité. Réveil lent (environ 1 minute), système de fichiers éphémère, SMTP ports 25/465/587 indisponibles. Ne pas l'utiliser en production.
- **Neon Free** : nouvelle instance PostgreSQL jetable, actuellement 1 Go de données par projet gratuit. Même région européenne que Render, si disponible.
- Les bases Render PostgreSQL gratuites expirent après 30 jours ; utiliser ici une **nouvelle** base Neon gratuite pour éviter cette limite de démonstration.
- Ne pas utiliser Supabase, VPS, volumes Docker locaux ou véritable dossier patient pour ce staging.

## 2. Première phase : API HTTPS avec refus des écritures

Cette branche contient `render.yaml` :

- `APP_ENV=staging` : la création publique d'un compte et les écritures cliniques sont refusées par le code FastAPI actuel.
- `APP_ALLOW_DEVELOPMENT_REGISTRATION=false`.
- `APP_ENABLE_EMAIL_AUTH=false` : aucun e-mail réel, pas de flux SMTP non validé.
- `APP_JWT_SECRET` généré par Render, jamais inscrit dans Git.
- `APP_DATABASE_URL` fourni **uniquement** comme secret au moment du provisionnement.
- HTTPS fourni par Render, `/ready` doit confirmer PostgreSQL et les migrations.
- Lancement manuel uniquement : `autoDeployTrigger: off`.

**Ne pas confondre cette phase avec une application utilisable en production.** Cette phase valide le déploiement, le certificat TLS, la connexion à PostgreSQL et le schéma Alembic. L'inscription et les écritures sont délibérément bloquées. Les tests complets du parcours clinique se font encore sur PostgreSQL CI/local synthétique.

## 3. Créer la base PostgreSQL dédiée dans Neon

1. Ouvrir le tableau de bord Neon. Créer un **nouveau** projet dédié `medisuivi-staging`, région Frankfurt si disponible.
2. Créer une base vide `medisuivi_staging`. **Ne pas importer** `backend_pgdata`, `medisuivi_pgdata` ni la sauvegarde locale.
3. Copier la chaîne de connexion depuis Neon vers le gestionnaire de secrets Render, sans la publier ni la coller dans un chat ou commit.
4. Pour SQLAlchemy + psycopg v3, adapter seulement le schéma URL :
   `postgresql+psycopg://UTILISATEUR:MOT_DE_PASSE@HOTE/medisuivi_staging?sslmode=require`.
5. Conserver les paramètres TLS nécessaires fournis par Neon (ex. `sslmode=require`). Le mot de passe doit rester secret.

Le service Render exécutera `alembic upgrade head` sur cette base vide au démarrage, puis `uvicorn` sur le port demandé par Render. **Ne pas réutiliser l'URL de la base locale.**

## 4. Créer l'API dans Render

1. Depuis Render, créer un **Blueprint** à partir du dépôt GitHub `taogoulahtihamy-gif/medisuivi-flutter` et de la branche `feat/medisuivi-p47-render-neon-staging` avec le fichier racine `render.yaml`. Si un service MediSuivi existe déjà sur Render, inspecter sa configuration avant d'en créer un second.
2. Choisir le service `medisuivi-api-staging` défini en plan **Free**, région Frankfurt, dossier racine `backend`.
3. Fournir `APP_DATABASE_URL` dans le formulaire privé Render ; `APP_JWT_SECRET` est créé automatiquement. Les options d'inscription/e-mail sont déjà désactivées.
4. Déployer manuellement (autoDeploy désactivé). Consulter les logs sans y recopier d'identifiants.
5. Lire l'URL HTTPS affichée par Render, puis vérifier :

```bash
curl --fail --silent --show-error --max-time 120 https://<adresse-render>/health
curl --fail --silent --show-error --max-time 120 https://<adresse-render>/ready
```

Attendu : `{"status":"ok","environment":"non-production"}` et `{"ready":true}`. Le premier appel après inactivité peut être lent.

La création de nouveaux comptes devrait renvoyer HTTP **403** dans cet environnement. Ne pas activer `APP_ALLOW_DEVELOPMENT_REGISTRATION=true` en staging pour contourner le verrou ; ce contrôle fait partie du périmètre de sécurité.

## 5. Utiliser Firefox dès maintenant en local

Sur le projet P4.6 (worktree séparé pour préserver les fichiers locaux) :

```bash
cd /mnt/chak/medisuivi-p46-android
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 \
  --dart-define=MEDISUIVI_DEV_API_BASE_URL=http://127.0.0.1:8027
```

Conserver ce terminal ouvert et ouvrir `http://127.0.0.1:8080` dans Firefox à partir d'un **second terminal**.

Le backend local autorise l'origine Web de développement `127.0.0.1:8080` ; l'API Render en staging n'est **pas** encore destinée à une interface Web publique, notamment en raison du CORS et de l'interdiction des écritures. Ne pas changer `APP_ENV` côté Render en `development`.

## 6. Suite après ce staging

- Ajouter une origine Web HTTPS strictement autorisée quand le site Flutter de démonstration sera hébergé.
- Construire un parcours de comptes de test autorisés et de données synthétiques sans inscription publique, avec revues sécurité spécifiques.
- Tester les flux de session et les sauvegardes/restaurations propres à un environnement distant.
- Adapter l'e-mail d'inscription/récupération via un service HTTP HTTPS compatible avec les limites de Render gratuit, avant toute utilisation authentifiée complète.
- Procéder à une revue sécurité et conformité CDP au Sénégal avant tout compte de praticien réel ou donnée personnelle médicale.

### État

La présence de `render.yaml` n'est **pas** une preuve de déploiement. Les services Render et Neon doivent être reliés/provisionnés et leurs URL réelles validées. Aucune base locale ne doit être exportée vers ce staging.
