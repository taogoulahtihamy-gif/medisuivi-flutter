# MediSuivi : architecture serveur et mode hors connexion

**État : conception technique. Aucun backend en production ni stockage
chiffré n'est encore connecté à Flutter. Ne pas utiliser de données réelles.**

## Pourquoi un backend ?

L'application personnelle doit fonctionner sans réseau, mais permettre la
restauration après perte du téléphone, la synchronisation entre appareils, des
sauvegardes et un contrôle d'accès vérifié côté serveur. Une base SQLite seule
ne répond pas à ces besoins.

### Architecture cible

```text
Android / iOS Flutter
  ├─ UI → repositories métier
  ├─ SQLCipher chiffré (dossiers, visites, suivis, bilans)
  ├─ coffre de clés du téléphone + verrouillage
  └─ outbox transactionnelle durable, synchronisation à la reconnexion
                           │ HTTPS + session authentifiée
                           ▼
API FastAPI (service distinct)
  ├─ Authentification, MFA possible, révoquer appareils
  ├─ Autorisation stricte par propriétaire de dossier
  ├─ Commandes métier idempotentes / versions d'entités
  ├─ Journal d'audit sans données cliniques en clair
  ├─ PostgreSQL + migrations Alembic + transactions
  └─ Documents protégés + sauvegardes chiffrées et test de restauration
```

**Flutter Web (Chrome) :** stratégie distincte à évaluer avant toute
persistance clinique. Le stockage du navigateur n'offre pas les mêmes
garanties que SQLCipher + Android Keystore / iOS Keychain. Le mode actuel
dans Chrome reste volontairement *en mémoire* avec données fictives.

## Ressources et endpoints envisagés

Toutes les requêtes cliniques doivent être authentifiées et autorisées.
Les identifiants doivent être des UUID non prédictibles.

| Ressource | Endpoints V1 proposés | Données |
|---|---|---|
| Session | `POST /v1/auth/login`, `POST /v1/auth/refresh`, `POST /v1/auth/logout` | Tokens, sessions et appareil |
| Patients | `GET/POST /v1/patients`, `GET/PATCH /v1/patients/{id}` | Identité, antécédents, allergies |
| Consultations | `GET/POST /v1/patients/{id}/visits` | Notes, constantes, auteur, date |
| Bilans | `GET/POST /v1/patients/{id}/exams`, `POST /v1/exams/{id}/results` | Prescription, compte rendu |
| Suivi | `GET/POST /v1/patients/{id}/followups`, `PATCH /v1/followups/{id}` | Date, motif, statut |
| Sync | `POST /v1/sync/push`, `GET /v1/sync/pull?cursor=...` | Opérations et révisions |
| Documents | `POST /v1/patients/{id}/documents` | Métadonnées + pièces jointes sécurisées |

Pas de tableau de bord hospitalier ni de gestion du personnel en V1.
Un seul compte professionnel peut posséder ses dossiers, avec architecture
évolutive pour une équipe si le besoin apparaît ultérieurement.

## Synchronisation et conflits

1. L'UI lit **d'abord** sa base locale chiffrée sur mobile.
2. Toute modification s'écrit dans la même transaction que l'**outbox**.
3. Chaque opération contient un UUID, un type d'entité, une révision
   précédente et un horodatage; le serveur traite de façon idempotente.
4. À la reconnexion, envoyer l'outbox, recevoir les confirmations, puis
   télécharger les nouveautés via un curseur de serveur.
5. En cas de conflit de notes cliniques, de résultats ou de consultations :
   **ne jamais choisir automatiquement le dernier écrivain** ; bloquer la
   modification litigieuse et demander une résolution explicite.
6. Une validation clinique doit rester traçable : auteur, timestamp,
   version et éventuellement rectificatif, pas de suppression silencieuse.

Les rendez-vous du prototype V0.5 utilisent `FollowUpPlan`, ses états
`planned/completed/cancelled` et des dates locales. Lors de la migration,
utiliser des timestamps UTC avec fuseau du lieu de consultation explicitement
enregistré ; séparer les rappels système des rendez-vous eux-mêmes.

## Étapes techniques

- **V0.5 (actuel)** : suivi daté et historique en mémoire, tests sur Flutter Web.
- **V0.6** : repositories et chiffrement local mobile, migration des modèles,
  protection de l'accès, tests de restauration (sur données fictives).
- **V0.7** : backend FastAPI + PostgreSQL et CI, auth, permissions, audit.
- **V0.8** : synchronisation avec conflits contrôlés, appareils révoqués,
  documents, réconciliation et tests de coupure réseau.
- **Préproduction** : validations métier et sécurité, conformité locale en
  protection des données de santé, protocole de sauvegarde/restauration,
  tests d'intrusion et revue juridique selon le pays et l'hébergement.

Ne jamais importer de dossiers cliniques dans GitHub ou les tests publics.
