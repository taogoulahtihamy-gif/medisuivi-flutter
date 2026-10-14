# P5.0 : MediSuivi sur Internet (Firefox, Android et API HTTPS)

**Cette version est un bac à sable de validation technique et contient exclusivement des données fictives.** Pas d'usage médical réel, pas d'import des bases locales, pas de production.

## Architecture et coût

- **Render Web Service Free** : `medisuivi-api-staging` avec FastAPI, migrations Alembic 0006 et HTTPS. Endormi après 15 min d'inactivité ; réveil lent. Non conçu pour la production.
- **Neon Postgres Free** : **nouveau projet vide** `medisuivi-sandbox`, base `medisuivi_sandbox`, région Frankfurt si possible. Aucune reprise de `medisuivi_pgdata`.
- **Render Static Site** : `medisuivi-web-staging` affiche le `MainShell` **original** sur les navigateurs et les téléphones (lien HTTPS).
- **APK GitHub Actions** : `MediSuivi P5.0 remote HTTPS Android APK` livre un `app-debug.apk` signé par la clé Android de debug de la machine CI. Le binaire pointe vers **la même API Render** via `--dart-define`, sans USB/ADB, sans API sur PC.

Les services gratuits ont des quotas : surveiller la facturation et le quota dans les tableaux de bord. Une APK de debug n'est **pas** une APK signée de distribution publique. Ne pas l'utiliser avec de vrais dossiers.

## Étape 1 : brancher Neon

Dans le tableau de bord Neon, créer un projet `medisuivi-sandbox` **nouveau et vide**. Choisir Postgres 17 si disponible. Ne pas copier `backend_pgdata`, `medisuivi_pgdata`, `erp_postgres_data`, ni aucun dump local.

Neon fournit une URL PostgreSQL privée. Dans Render, définir le secret `APP_DATABASE_URL` avec le format SQLAlchemy **psycopg3** :

```text
postgresql+psycopg://UTILISATEUR:MOT_DE_PASSE@HOTE_NEON/medisuivi_sandbox?sslmode=require
```

Les autres paramètres éventuellement fournis par Neon doivent rester intacts. Ne pas coller l'URL réelle ni son mot de passe dans GitHub, une capture ou ce chat.

## Étape 2 : déployer les deux services Render

1. Relier le dépôt GitHub `taogoulahtihamy-gif/medisuivi-flutter` à Render, puis créer un **Blueprint** à partir du fichier `render.yaml` **de la branche** `feat/medisuivi-p50-remote-web-android-sandbox`. Ne pas sélectionner `main` ni P4.7.
2. La configuration crée **deux** services : `medisuivi-api-staging` (Python Free) et `medisuivi-web-staging` (Static Site Free). Aucun PostgreSQL Render supplémentaire.
3. Quand Render demande les variables privées de l'API, saisir :
   - `APP_DATABASE_URL` : URL de la **nouvelle** base Neon au format `postgresql+psycopg://` avec SSL.
   - `APP_SANDBOX_INVITE_CODE` : secret aléatoire **distinct** du mot de passe du compte. Générer localement via `openssl rand -hex 32`. **Ne jamais inclure cette valeur dans le frontend ou les fichiers Git.**
   - `APP_JWT_SECRET` : automatiquement généré par Render. Vérifier qu'il a été initialisé.
4. Dans le service API, vérifier `APP_ENV=sandbox`, `APP_SANDBOX_WRITES_ENABLED=true`, `APP_SANDBOX_REGISTRATION_ENABLED=true`, `APP_ENABLE_EMAIL_AUTH=false`. Le contrôle CORS n'autorise qu'une seule origine HTTPS exacte, `APP_PUBLIC_WEB_ORIGIN`.
5. Déployer manuellement le backend, patienter pour les migrations. Puis déployer manuellement le site statique. Les déploiements automatiques sont désactivés volontairement pour tester chaque mise à jour.
6. Si Render a attribué des URL **différentes** des deux noms prévus, ajuster `APP_PUBLIC_WEB_ORIGIN` sur l'API, `MEDISUIVI_API_BASE_URL` sur le site, et la variable `MEDISUIVI_API_BASE_URL` dans la CI Android, **avant** de valider les applications.

URLs prévisionnelles à **ne pas présenter comme déployées tant que Render ne les a pas réellement attribuées** :

```text
https://medisuivi-api-staging.onrender.com/health
https://medisuivi-api-staging.onrender.com/ready
https://medisuivi-web-staging.onrender.com
```

Contrôles :

```bash
curl --fail --silent --show-error --max-time 120 \
  https://medisuivi-api-staging.onrender.com/health
curl --fail --silent --show-error --max-time 120 \
  https://medisuivi-api-staging.onrender.com/ready
```

Le premier appel peut être lent après une veille Render. Le site ne doit **jamais** appeler `127.0.0.1` ou `10.0.2.2`.

## Étape 3 : créer un compte fictif depuis le site HTTPS

1. Ouvrir `https://medisuivi-web-staging.onrender.com` dans Firefox ou Chrome, ou dans le navigateur d'un téléphone.
2. Ouvrir « Créer un compte ». Utiliser un **nom de praticien fictif** et une adresse de test commençant par `demo-`, finissant par `@example.com` (par exemple `demo-essai123@example.com`).
3. Entrer un mot de passe de test fort et le **code d'invitation** défini *privément* sur Render. Ne pas partager ces valeurs.
4. La connexion automatique ouvre notre **accueil MediSuivi original** via `ConnectedClinicalStore`. Créer uniquement des patients dont le nom commence par `PATIENT FICTIF`. Les consultations/examens/suivis doivent être des données entièrement inventées.
5. Créer un deuxième compte fictif avec la même invitation pour tester le changement A/B : le serveur doit refuser la lecture d'un patient de A via le token de B (HTTP 404).
6. Après les comptes de test, passer `APP_SANDBOX_REGISTRATION_ENABLED=false` dans Render et redéployer l'API. La connexion existante continuera à fonctionner, mais la création de comptes sera refusée.

Le mode sandbox utilise une **invitation privée** pour l'inscription, une origine HTTPS explicite pour le CORS et un contrôle serveur des noms `PATIENT FICTIF`. Cela ne prouve pas qu'aucune donnée réelle ne puisse être saisie dans un champ de note : ne saisir AUCUNE information personnelle ou médicale réelle.

**Limitations** : récupération de mot de passe par e-mail désactivée dans cette configuration gratuite ; utilisation seulement pour la démonstration. La publication de vraies données serait inappropriée sans audit de sécurité, conformité CDP Sénégal, hébergement adapté, consentements et sauvegardes testées.

## Étape 4 : récupérer l'APK Android GitHub

Ouvrir l'onglet GitHub **Actions → MediSuivi P5.0 remote HTTPS Android APK** sur la branche `feat/medisuivi-p50-remote-web-android-sandbox`.

Quand la CI passe :
1. Ouvrir la dernière exécution réussie.
2. Télécharger l'artefact `medisuivi-p50-render-connected-android-debug-apk`.
3. Décompresser l'archive ZIP, récupérer `app-debug.apk`.
4. Sur un téléphone Android **de test**, autoriser ponctuellement l'installation depuis cette source fiable et installer l'APK. Ne pas désinstaller une version précédente qui contient des données importantes. La signature debug de CI peut être différente de la signature d'une ancienne APK.
5. Ouvrir MediSuivi et utiliser le même compte fictif que dans Firefox. L'APK pointe directement vers l'API distante sur HTTPS. Elle ne nécessite pas d'ordinateur allumé.

Quand les secrets de signature officielle sont configurés dans le dépôt et qu'une recette physique est complète, un **APK release signé stable** pourra remplacer le debug. Ne pas publier dans un store mobile à ce stade.

## Validations avant fusion ou données réelles

- GitHub Actions P5.0 : migrations SQL sur PostgreSQL CI jetable, invitation obligatoire, CORS strict, refus de noms non fictifs, A/B isolés.
- CI Flutter et compilation Web et Android.
- Test en ligne réel : certificats HTTPS, `/ready`, compte A/B, navigation et détail, reconnexion, veille et réveil Render.
- Android physique non disponible actuellement : aucune preuve de fonctionnement du KeyStore Android, verrouillage, biométrie, rotation des tokens ou comportement hors ligne.
- **Aucune migration automatique sur le PostgreSQL Docker local.** `APP_ENV=sandbox` n'est autorisé qu'avec base Neon dédiée.

N'utiliser ni LWS mutualisé sans support ASGI, ni Supabase, ni un VPS, ni un service qui héberge gratuitement de vrais dossiers médicaux.
