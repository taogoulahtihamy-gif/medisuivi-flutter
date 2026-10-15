# P5.4 — inscription publique contrôlée (staging uniquement)

## Implémentation
- `APP_PUBLIC_REGISTRATION_ENABLED` (défaut `false`) : ouvre `POST /api/v1/auth/register` pour adresses e-mail ordinaires uniquement si `APP_ENV=staging` et `APP_ENABLE_EMAIL_AUTH=true`.
- Le serveur échoue au démarrage si un mode d'inscription publique est configuré sans SMTP de base. Les identifiants SMTP sont des secrets de déploiement, jamais dans l'APK ni GitHub.
- Inscription publique ne transmet aucun code d'invitation, puis utilise le parcours existant `/email/verify`. Connexion impossible tant que l'e-mail n'est pas vérifié.
- Pour compiler Flutter contre un **backend staging séparé**, utiliser `--dart-define=MEDISUIVI_PUBLIC_SIGNUP=true` conjointement à l'URL de ce backend. Ne pas activer cette option sur un APK dirigé vers la sandbox à invitations.
- Les routes de renvoi e-mail et récupération de mot de passe sont accessibles en staging quand la validation e-mail est configurée.
- La sandbox actuelle reste limitée aux identités fictives et aux noms `PATIENT FICTIF`. Ne pas charger de véritables données médicales.

## Configuration opérateur (sur SON compte Vercel)
1. Créer un déploiement de staging dédié, isolé de `medisuivi-sandbox`. Base Neon propre au staging, TLS activé, migrations validées.
2. Configurer `APP_ENV=staging`, `APP_ENABLE_EMAIL_AUTH=true`, `APP_SMTP_HOST`, `APP_SMTP_FROM`, `APP_SMTP_PORT`, `APP_SMTP_USER`, `APP_SMTP_PASSWORD`, `APP_SMTP_STARTTLS=true`, `APP_JWT_SECRET`, `APP_DATABASE_URL`.
3. Vérifier les limites d'envoi du prestataire SMTP, le domaine SPF/DKIM/DMARC et l'exécution de l'envoi depuis Vercel.
4. Avant l'ouverture, déployer un contrôle anti-abus distribué et persistant : limitations par IP, par e-mail, quota global, filtrage bot et surveillance. Les mécanismes en mémoire ne suffisent pas sur Vercel.
5. Activer **en dernier** `APP_PUBLIC_REGISTRATION_ENABLED=true` et redéployer.
6. Tester avec une adresse e-mail que l'opérateur contrôle et aucune donnée clinique réelle : inscription 201 → code reçu → vérification 204 → connexion 200 → session.
7. Retour arrière : `APP_PUBLIC_REGISTRATION_ENABLED=false`, redéploiement. Les comptes déjà créés restent conservés.

## Blocages du GO production médicale
Pas de `APP_ENV=production` : ce code refuse toujours l'exploitation médicale réelle. Audit d'accès de bout en bout, sauvegarde/restauration, chiffrement des données et clés, journal d'audit, suppression/portabilité, gestion d'incidents, conformité nationale et avis externe nécessaires.

## État
Code poussé ; ne pas annoncer validation Android ou envoi SMTP réel avant preuves CI et recette déployée.
