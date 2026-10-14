# MediSuivi : trajectoire vers la vraie application multi-utilisateurs

**Document de préparation produit/architecture, pas une attestation de mise en production.**
État examiné : branche `feat/medisuivi-sprint5o-subtle-outlines`, 14 octobre 2026.

## État réellement constaté dans le dépôt

- Flutter possède une démonstration Web `DemoStore` avec patients **fictifs**.
- L'application mobile possède `PersistentStore`, Drift et SQLite chiffré localement, avec des opérations `PendingOperations` prévues pour une synchronisation future.
- Le flux « Se connecter » est actuellement **une page d'attente**, sans authentification serveur. « Créer un compte » ouvre un **profil de prévisualisation en mémoire**.
- Le schéma SQLite patients / visites / examens / suivis ne comporte pas encore de champ `owner_user_id` ni de séparation des dossiers par compte.
- Aucun dépôt autonome MediSuivi backend n'a été identifié parmi les dépôts accessibles au propriétaire ; le backend ERP SaaS est un **autre produit**, à ne pas recycler sans revue de sécurité et de modèles métier.
- Conséquence : cette version n'est **pas adaptée aux données médicales réelles** ni à plusieurs praticiens sur le même appareil, malgré les tests Flutter.

## Règle métier non négociable

**Un compte = un praticien, un espace privé, une session propre, ses patients et leurs actes.**
Deux comptes A et B ne peuvent ni consulter, ni modifier, ni rechercher, ni exporter les données de l'autre. Aucune synchronisation croisée, même après déconnexion, changement de compte, fonctionnement hors-ligne, migration ou réinstallation.

Une fonctionnalité d'équipe/collaboration pourra être conçue ensuite, avec accord et permissions explicites. Pas de mutualisation implicite.

## Sprint P0 : cadrage et barrières avant les données réelles

- Confirmer le pays de déploiement et les obligations applicables aux données de santé : hébergement, consentement, journalisation, droits des patients, notification d'incident, transferts internationaux et durées de conservation.
- Choisir le fournisseur d'hébergement et les environnements dev/staging/prod, sans secrets en dépôt. Fournir une revue des menaces et tests de sécurité.
- Séparer de façon visible **Démonstration** et **Espace réel**. Interdire que les comptes de test ou patients fictifs se mélangent aux dossiers cliniques.
- Modéliser ownership strict, audit, autorisations et récupération des comptes.

## Sprint P1 : backend MediSuivi dédié et comptes

Stack proposée : FastAPI + PostgreSQL + Alembic, TLS, migrations et tests isolés ; possibilité d'un service d'identité externe si conformité et régions confirmées.

- `users` : UUID, email normalisé unique, état vérifié/actif, mot de passe haché fort (Argon2id) ou service d'identité éprouvé ; aucun mot de passe stocké en clair.
- `practitioner_profiles` : `user_id` unique, nom, prénom, spécialité, téléphone et référence sécurisée d'avatar.
- Connexion sécurisée, vérification d'email, réinitialisation du mot de passe, limitation de tentatives, gestion des sessions, révocation, renouvellement contrôlé, déconnexion de tous les appareils. MFA selon niveau de risque.
- `GET/PATCH /v1/me` et `POST /v1/me/photo` : photo à type/taille vérifiés, stockage privé, suppression possible ; avatar affiché en haut à droite et dans Profil.
- Tests d'authentification : mauvais mot de passe, énumération, rate-limit, sessions expirées et révocation.

## Sprint P2 : propriété et isolation des données cliniques

- Tables `patients`, `visits`, `exams`, `followups`, pièces jointes : `owner_user_id` non nul, clés étrangères, index composites adaptés.
- Autorisation serveur sur **toutes** les listes, accès par identifiant, recherche, création, édition, export et suppressions ; filtrage par utilisateur dérivé **du jeton serveur**, jamais d'un champ fourni par l'application.
- RLS PostgreSQL possible comme garde-fou supplémentaire, sans remplacer les contrôles applicatifs.
- Journalisation de sécurité et traçabilité des actions sensibles, sans inclure de données médicales dans les logs.
- Tests multi-utilisateurs systématiques (A ne voit/modifie jamais les patients et examens de B ; réponses sans fuite d'existence).

## Sprint P3 : connexion Flutter et gestion de session

- Introduire `AuthRepository` et `ClinicalApiClient` typés, erreurs utilisateurs claires, stockage sûr des jetons ou sessions, mécanisme de rafraîchissement et d'expiration.
- Vrais écrans Inscription / Connexion / Mot de passe oublié / Vérification / Déconnexion, avec validation clavier et accessibilité.
- Flux : démarrage → session restaurée et validée → dossiers du compte ; sans session → connexion ou démonstration explicitement isolée.
- En cas de changement d'utilisateur, effacer de la mémoire les données visibles de l'ancien compte et **ne jamais réutiliser ses clés/chiffrement ou DB** pour le nouveau.
- Aucune donnée clinique transmise à un serveur inexistant. Absence de connexion = état clair, pas de succès simulé.

## Sprint P4 : stockage mobile, synchronisation et migration

- Bases locales / clés de chiffrement distinctes **par compte**, effacement mémoire et fermeture des streams à la déconnexion.
- Files d'opérations locales idempotentes : `operation_id`, révisions, résolution de conflits documentée et transactionnelle, suppression et changements inter-appareils.
- Synchronisation HTTPS protégée et authentifiée ; retries bornés, horodatages serveur, contrôles de version, aucune perte silencieuse.
- Migration prudente des données présentes sur l'appareil, consentement du praticien et sauvegarde avant tout changement ; ne **jamais** réattribuer automatiquement des anciens dossiers à un compte.
- Tests hors ligne ↔ en ligne ↔ changement de compte, 2 appareils, conflits, interruption réseau, réinstallation et révocation.

## Sprint P5 : validation préproduction

- CI sur API et Flutter : tests unitaires/intégration/API/E2E, permissions croisées, sauvegarde/restauration, chiffrage, migrations, pentest ciblé.
- Audit logs, surveillance des accès, gestion d'incidents, sauvegardes chiffrées testées, politique de rétention et suppression conforme.
- Packaging Android/iOS signés, secrets séparés, certification et règles du pays de déploiement, URLs/Domaines et TLS vérifiés.
- Test manuel et clinique avec données **synthétiques seulement**, sur appareils physiques, lisibilité, accessibilité et erreurs de réseau.
- **Critère Go/No-Go** : aucune donnée réelle tant que l'authentification, l'isolation A/B, la sauvegarde/restauration et les obligations applicables ne sont pas vérifiées et validées.

## Contrat API initial proposé (à finaliser après P0)

- `POST /v1/auth/register`, `POST /v1/auth/login`, `POST /v1/auth/logout`, `POST /v1/auth/refresh`
- `POST /v1/auth/verify-email`, `POST /v1/auth/password/forgot`, `POST /v1/auth/password/reset`
- `GET/PATCH /v1/me`, `PUT/DELETE /v1/me/photo`
- `GET/POST /v1/patients`, `GET/PATCH /v1/patients/{id}`
- `GET/POST /v1/patients/{id}/visits`, `GET/POST /v1/patients/{id}/exams`, `GET/POST /v1/patients/{id}/followups`
- `POST /v1/sync/push`, `GET /v1/sync/pull` uniquement après P4 et la revue des conflits.

Ce sont des **spécifications de travail**, pas des routes déjà disponibles sur un serveur.

## Décisions à confirmer avant P1

1. Pays principal d'utilisation et régions d'hébergement autorisées.
2. Comptes uniquement pour praticiens individuels dans la V1, ou collaboration entre cabinets à prévoir (sans partage par défaut).
3. Où créer et héberger le **backend MediSuivi dédié** et comment gérer le domaine API.

Le sprint 5O ne modifie que les bordures des listes. Aucun nouveau backend, authentification ou déploiement réel n'y est ajouté.
