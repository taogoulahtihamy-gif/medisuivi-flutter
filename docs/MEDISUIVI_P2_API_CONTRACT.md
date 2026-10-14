# MediSuivi P2 : contrat API clinique en environnement de développement

**État** : comptes et dossiers isolés côté FastAPI + PostgreSQL. Il s'agit
d'un socle de développement avec patients **synthétiques uniquement**.
L'application Flutter ne consomme pas encore ces routes.

## Principe d'isolement

- JWT valide, signé et non révoqué dans `Authorization: Bearer <access_token>`.
- `owner_user_id` est extrait de l'utilisateur authentifié, **jamais** du
  corps JSON, d'un paramètre `owner` ou d'un identifiant choisi par le client.
- Pour une consultation, un bilan ou un suivi appartenant à B, toute requête
  de A reçoit le même **404** qu'un identifiant inexistant.
- Clés étrangères composites `(patient_id, owner_user_id)` entre actes et
  patients : les erreurs de programmation ou tentatives d'écriture cross-account
  sont aussi rejetées par PostgreSQL.
- Les endpoints d'écriture ne fonctionnent que sous `APP_ENV=development`.
- On ne prend pas de dossiers médicaux réels tant que le Go/No-Go sécurité /
  conformité Sénégal n'est pas validé.

## Endpoints en place

| Méthode et chemin | But | Règles |
| --- | --- | --- |
| `POST /api/v1/auth/register` | Créer un compte fictif | dev explicite seulement |
| `POST /api/v1/auth/login` | Jeton temporaire | Argon2id, durée 15 min |
| `GET /api/v1/me` | Praticien connecté | Auth obligatoire |
| `POST /api/v1/auth/logout` | Révoquer les anciens jetons du compte | Auth obligatoire |
| `GET/POST /api/v1/patients` | Lister/créer les dossiers | Compte propriétaire |
| `GET /api/v1/patients/{patient_id}` | Dossier patient | Compte propriétaire |
| `GET/POST /api/v1/patients/{patient_id}/visits` | Consultations | Propriété du patient vérifiée |
| `GET/POST /api/v1/patients/{patient_id}/exams` | Bilans | Propriété du patient vérifiée |
| `PUT /api/v1/exams/{exam_id}/result` | Enregistrer le résultat | 409 si déjà clôturé |
| `GET/POST /api/v1/patients/{patient_id}/followups` | Suivis | Propriété du patient vérifiée |
| `PUT /api/v1/followups/{id}/reschedule` | Reporter | 409 si clôturé |
| `PUT /api/v1/followups/{id}/close` | Terminer/annuler | 409 si déjà clôturé |

### Exemples synthétiques

`POST /api/v1/patients/{id}/visits` :

```json
{"reason":"Consultation fictive","temperature":37.2,"systolic":120,"diastolic":80,"pulse":72,"spo2":98,"notes":""}
```

`POST /api/v1/patients/{id}/exams` :

```json
{"title":"Examen biologique fictif"}
```

`PUT /api/v1/exams/{exam_id}/result` :

```json
{"result":"Résultat synthétique sans anomalie"}
```

`POST /api/v1/patients/{id}/followups` :

```json
{"scheduled_at":"2026-11-03T10:30:00Z","reason":"Contrôle fictif","notes":""}
```

`PUT /api/v1/followups/{id}/close` :

```json
{"completed":true}
```

Les dates de suivi doivent comporter un fuseau (UTC `Z` recommandé).
Les données envoyées depuis Flutter devront être converties en UTC et
retransformées dans le fuseau local uniquement pour leur affichage.

## Tests

La CI exécute deux environnements différents :
- SQLite : tests API unitaires et validation de la contrainte composite.
- PostgreSQL 17 : migrations Alembic et tests réels avec deux comptes et
  trois catégories d'actes cliniques, incluant une tentative SQL cross-account.

**Limites importantes** : il reste à intégrer le contrôle de débit, la
vérification email, les permissions RLS, l'audit de sécurité, les sauvegardes,
le chiffrement serveur, les uploads privés, la récupération des comptes, la
migration des données locales et les écrans Flutter réellement connectés.

**Prochaine étape P3** : dépôt sécurisé des identifiants côté Flutter,
états connexion/inscription/profil et isolement du cache par compte. Ne pas
réutiliser directement le `DemoStore` commun entre praticiens.
