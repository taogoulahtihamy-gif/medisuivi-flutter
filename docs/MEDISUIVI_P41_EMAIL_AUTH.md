# MediSuivi P4.1 : confirmation de l'e-mail et récupération du mot de passe

**Ce sprint n'autorise pas la production ni de vraies données de santé.**
La gestion complète des comptes reste un service de **développement**.

## Fonctionnalités backend

- `POST /api/v1/auth/register` : inscription de développement avec code de confirmation si `APP_ENABLE_EMAIL_AUTH=true`.
- `POST /api/v1/auth/email/verify` : code numérique à 12 chiffres, expiration 30 minutes, cinq essais maximum.
- `POST /api/v1/auth/email/resend` : renvoi limité à une fois par minute ; même réponse pour adresse inconnue.
- `POST /api/v1/auth/password/forgot` : envoie un code de récupération, réponse identique pour adresses inconnues.
- `POST /api/v1/auth/password/reset` : code à usage unique, expiration 15 minutes ; remplace le mot de passe Argon2id et invalide toutes les sessions.
- Les codes ne sont pas retournés par l'API et ne sont enregistrés qu'en empreintes HMAC séparées par compte et usage.
- Les migrations sont dans `backend/alembic/versions/0005_email_challenges.py`. Elles préservent les comptes fictifs anciens en leur donnant `email_verified=true` pour compatibilité.

## Mailpit local (aucun mail réel)

Exécuter après avoir synchronisé cette branche :

```bash
cd /mnt/chak/medisuivi-flutter/backend
export POSTGRES_PASSWORD='REUTILISER_LE_MOT_DE_PASSE_DU_VOLUME_EXISTANT'
export APP_JWT_SECRET='REUTILISER_LE_SECRET_EXISTANT'
export APP_ALLOW_DEVELOPMENT_REGISTRATION=true
export APP_ENABLE_EMAIL_AUTH=true
export APP_SMTP_HOST=mailpit
export APP_SMTP_PORT=1025
export APP_SMTP_FROM=medisuivi-dev@localhost.invalid
export APP_SMTP_STARTTLS=false
docker compose -f docker-compose.yml -f docker-compose.mailpit.yml up -d --build
docker compose -f docker-compose.yml -f docker-compose.mailpit.yml exec api python -m scripts.init_dev_db
```

Les messages **fictifs** peuvent être consultés à `http://127.0.0.1:8025`.
Ne jamais mettre de vrais adresses ou vrais dossiers médicaux dans Mailpit.
Ne jamais effacer le volume PostgreSQL pour relancer les tests.

## Flutter

La connexion par mot de passe normal reste possible pour les comptes historiques déjà validés.
Pour les **nouveaux comptes** avec la validation activée, l'inscription mène à
un écran de saisie du code, puis à la connexion. La fonction « mot de passe
oublié » permet de demander un code et d'enregistrer un nouveau mot de passe.

## Points non couverts avant un hébergement de test en ligne

- Choix d'un **vrai service SMTP** et envoi réel à une adresse contrôlée.
- Protection supplémentaire par IP/réseau contre les attaques réparties,
  délivrabilité, audit et supervision.
- Sessions persistantes chiffrées sur Android, données cliniques hors ligne
  partitionnées par compte, tests physiques Android.
- Vérification de conformité sénégalaise/CDP, politique de conservation,
  sauvegardes et plan de restauration.
- App `APP_ENV=production` actuellement **refusée** par conception.

**Aucun déploiement Render/Neon ou LWS dans cette PR.**
