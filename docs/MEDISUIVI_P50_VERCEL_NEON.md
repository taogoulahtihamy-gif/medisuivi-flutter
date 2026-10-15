# P5.0 alternative : API Vercel + Neon (aucun VPS, aucun backend local)

## État du 14 octobre 2026 : API validée

- URL de production **confirmée** : `https://medisuivi-api-staging.vercel.app`.
- `/health` : HTTP 200, environnement non-production.
- `/ready` : HTTP 200, base distante disponible.
- `/openapi.json` : HTTP 200, FastAPI et routes de l'API exposés.
- Migrations Alembic sur la base `medisuivi_sandbox` : build Vercel réussi.
- Contrôles réels multi-utilisateurs et parcours Flutter complets : **encore à effectuer**.

**Action Web Render (uniquement après validation du build GitHub)** :
dans Render > `medisuivi-web-staging`, remplacer
`MEDISUIVI_API_BASE_URL` par
`https://medisuivi-api-staging.vercel.app`, puis changer la branche du
service pour `feat/medisuivi-p50-vercel-api-neon` et utiliser le déploiement
manuel. Conserver la même commande `bash scripts/build_render_web.sh`.
Vérifier `https://medisuivi-web-staging.onrender.com` avec un compte fictif
et le panneau Réseau ; ne pas envoyer de données personnelles réelles.

**Action Android GitHub** : la CI
`MediSuivi P5.0 remote HTTPS Android APK` de la même branche est maintenant
configurée pour `https://medisuivi-api-staging.vercel.app`.
Télécharger uniquement l'artefact de la branche Vercel et non l'ancienne
APK qui utilisait Render. App Android physique pas encore validée.

**Protection Vercel** : conserver la protection des preview. La production
doit être accessible depuis Web et APK uniquement après validation du
fonctionnement de son domaine public. La santé HTTP 200 ne suffit pas à
prouver l'authentification ni l'isolation A/B.
Ne jamais copier de jeton de contournement de protection dans Flutter.

**Secrets** : le mot de passe Neon et des secrets JWT/invitation ont été
exposés dans des captures précédentes. Les renouveler dans Neon et Vercel
avant des tests publics. Cette procédure invalide potentiellement des
sessions existantes ; ne pas modifier des bases de l'ERP ou des données
locales.


**Portée : sandbox technique avec des comptes et dossiers totalement fictifs.**
Le site Flutter reste sur Render Static Site. L'APK Android sera reconstruite
après validation de l'URL Vercel. Le service Web FastAPI bloqué sur Render
ne sera pas utilisé.

## Prérequis

- L'app Vercel doit être connectée à ChatGPT (installation explicitement
  autorisée par l'utilisateur), ou un projet peut être importé manuellement.
- Le projet Neon neuf `medisuivi-sandbox`, **et uniquement celui-ci**.
- Réinitialiser le mot de passe Neon et les secrets Render exposés
  précédemment avant de donner un accès distant.
- Ne pas coller les secrets ou des captures d'en-têtes Authorization
  dans le chat/GitHub.

## Projet à importer sur Vercel

Repository : `taogoulahtihamy-gif/medisuivi-flutter`

Branch : `feat/medisuivi-p50-vercel-api-neon`

Project Name : `medisuivi-api-staging`

Root Directory : `backend`

Framework : FastAPI (détection Python automatique)

Runtime : Python 3.12 (`backend/.python-version`)

Entrée ASGI : `backend/index.py` réexporte `app.main:app`, sans
modifier les routes ni la sécurité.

`backend/pyproject.toml` utilise la commande de build Vercel
`python scripts/prepare_vercel_sandbox.py`. Le script arrête la publication
tant que `APP_ENV=sandbox` et l'URL **Neon TLS**
`/medisuivi_sandbox` ne sont pas fournis. Il exécute les migrations Alembic
de manière idempotente avant la mise en ligne.

Environnement du projet Vercel, variables privées, **Production uniquement** :

```text
APP_ENV=sandbox
APP_PUBLIC_WEB_ORIGIN=https://medisuivi-web-staging.onrender.com
APP_SANDBOX_WRITES_ENABLED=true
APP_SANDBOX_REGISTRATION_ENABLED=true
APP_ALLOW_DEVELOPMENT_REGISTRATION=false
APP_ENABLE_EMAIL_AUTH=false
APP_DATABASE_URL=<nouvelle URL Neon postgresql+psycopg://.../medisuivi_sandbox?sslmode=require>
APP_JWT_SECRET=<secret aléatoire UNIQUE >=32 octets>
APP_SANDBOX_INVITE_CODE=<autre secret aléatoire UNIQUE >=32 octets>
```

Ne pas créer de base PostgreSQL supplémentaire. L'origine CORS reste
strictement `https://medisuivi-web-staging.onrender.com`. La chaîne Neon
est une variable privée : **aucune donnée clinique réelle**.

## Validation des URL

Vercel fournit une vraie URL HTTPS après déploiement. Ne pas inventer
`medisuivi-api-staging.vercel.app` tant que l'adresse n'a pas été confirmée.

Vérifier :
```bash
curl -fsS --max-time 30 https://<API_VERCEL>/health
curl -fsS --max-time 30 https://<API_VERCEL>/ready
```
Une réponse de santé seule ne prouve pas l'intégration : vérifier
ensuite la connexion du compte fictif et le dossier fictif.

## Rebrancher le site Render (non automatique)

Dans Render > `medisuivi-web-staging` > Environment :
`MEDISUIVI_API_BASE_URL=https://<VRAIE_URL_VERCEL>`.

Puis **Manual Deploy → Deploy latest commit** après avoir configuré
la branche Git du site sur `feat/medisuivi-p50-vercel-api-neon`, afin
que `scripts/build_render_web.sh` compile Flutter avec la nouvelle URL.

Contrôler le bundle à l'aide du navigateur Réseau : aucune requête vers
`medisuivi-api-staging.onrender.com` ou `127.0.0.1`.

## Recompiler l'APK

Le workflow Android sur `feat/medisuivi-p50-vercel-api-neon` référence désormais
l'API Vercel. Utiliser son artefact `medisuivi-p50-vercel-connected-android-debug-apk`
seulement après une CI verte.

La version de démonstration Android utilise `com.example.medisuivi.sandbox`
et n'écrase pas l'ancienne application.

## Limites

Le plan Vercel Hobby est gratuit pour les projets personnels
**non commerciaux** et son runtime Python fonctionne sous forme de fonctions
serverless. Pas de processus FastAPI permanent, pas de tâches de fond
durables et pas de garantie d'usage médical. Ne pas publier pour des patients
réels. Les temps d'exécution et la veille éventuelle doivent être testés.

Ni Render, ni Neon, ni l'APK ne deviennent automatiquement opérationnels
du seul fait de l'ajout de cette branche. Valider le déploiement, la
migration `0006`, la confidentialité A/B et la reconnexion avec Firefox.
