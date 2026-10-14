# MediSuivi backend : première fondation (Sénégal)

**STATUT : prototype de développement, pas une API de production.**
Les patients utilisés ici sont strictement **fictifs**. Le processus refuse `APP_ENV=production`.

## Installation locale (PostgreSQL + FastAPI)

Depuis `backend/` :

1. Copier `.env.example` dans `.env` pour référence. **Ne jamais committer les secrets.**
2. Définir dans le shell `POSTGRES_PASSWORD` et un `APP_JWT_SECRET` unique, aléatoire, de plus de 32 octets.
3. Démarrer `docker compose up -d --build`.
4. Initialiser une fois le schéma **de développement** par migrations Alembic : `docker compose exec api python -m scripts.init_dev_db`.
5. Vérifier `http://127.0.0.1:8027/health` et `http://127.0.0.1:8027/ready`.
6. Pour créer les comptes fictifs en développement uniquement, définir `APP_ALLOW_DEVELOPMENT_REGISTRATION=true` et recréer le service API.

Aucun endpoint n'est à exposer sur Internet. Docker limite les ports à l'interface locale.
Les comptes utilisateurs ne sont pas encore reliés aux écrans Flutter.

### API initiale

- `POST /api/v1/auth/register` : uniquement avec inscription de développement explicitement activée.
- `POST /api/v1/auth/login` : email/mot de passe, jeton HS256 signé, expiration 15 minutes.
- `GET /api/v1/me` : praticien courant.
- `POST /api/v1/auth/logout` : invalide tous les jetons précédents de ce compte.
- `GET/POST /api/v1/patients` et `GET /api/v1/patients/{id}` : filtrage serveur obligatoire par `owner_user_id`.

Les consultations, bilans et suivis disposent désormais de tables serveur avec clés étrangères composites `(patient_id, owner_user_id)`. Leur lecture, leur création et leurs changements d'état sont bornés par l'identité signée.

API P2 : `GET/POST /api/v1/patients/{id}/visits`, `GET/POST /api/v1/patients/{id}/exams`, `PUT /api/v1/exams/{id}/result`, `GET/POST /api/v1/patients/{id}/followups`, `PUT /api/v1/followups/{id}/reschedule|close`.

La migration `alembic/versions/0001_clinical_isolation.py` initialise un schéma **neuf**, elle ne transforme pas automatiquement les anciens fichiers SQLite mobiles et ne doit pas être utilisée comme migration de données réelles.

### Tests

```bash
cd backend
python -m pip install -r requirements.txt
pytest -q
```

Tests : stockage Argon2id, connexion invalide, sessions expirées/révoquées, isolation A/B, écriture non autorisée, configuration production refusée.

### Bloqueurs avant production

- Formalités CDP, finalités/consentement/base légale, lieu d'hébergement et transferts internationaux validés.
- Migrations Alembic et isolation PostgreSQL (en plus des contrôles applicatifs), tests réels avec PostgreSQL.
- Validation d'email, gestion et révocation de sessions par appareil, MFA selon risques, récupération de mot de passe.
- Rate limiting distribué, anti-énumération, protections de transport, gestion robuste des secrets et rotation.
- Modèles cliniques complets et tests croisés pour **chaque** endpoint, politique d'audit sans données sensibles.
- Chiffrement, sauvegardes testées, supervision, incident response et pentest.
- Flutter : sessions authentifiées, stockage local chiffré **distinct par utilisateur** et migration sûre des dossiers.
- Les données fictives ne doivent jamais être transférées automatiquement vers les futurs comptes réels.

Lire `docs/MEDISUIVI_PRODUCTION_MULTI_ACCOUNT_PLAN.md` et
`docs/MEDISUIVI_SENEGAL_CONFORMITY_GATE.md`.

**Pas de vraies données patients dans ce prototype.**
