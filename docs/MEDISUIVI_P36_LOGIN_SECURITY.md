# MediSuivi P3.6 : protection des tentatives de connexion

**Statut : environnement de développement uniquement.** Les comptes et les dossiers doivent rester fictifs ; `APP_ENV=production` est volontairement refusé par le backend.

## Comportement livré

- Chaque adresse e-mail normalisée possède un compteur transactionnel, conservé en base sous une clé **HMAC-SHA256** utilisant le secret applicatif. Ni l'adresse brute, ni le mot de passe, ni l'adresse IP ne sont enregistrés dans `login_attempts`.
- Après **5 mots de passe incorrects dans une fenêtre de 15 minutes**, le compte ciblé subit **15 minutes de temporisation** à compter du dernier échec. La connexion correcte reste bloquée pendant ce délai : c'est une mesure anti-bruteforce, pas une preuve d'identité.
- Les tentatives d'une adresse inconnue passent aussi par une vérification Argon2id fictive et reçoivent les **mêmes réponses HTTP** (`401` ou `429`) qu'une adresse enregistrée. L'API n'annonce pas l'existence d'un compte.
- `429` renvoie `Retry-After`. Flutter affiche une explication compréhensible, sans détails sur l'adresse ou le compte ciblé.
- Une connexion réussie remet son propre compteur à zéro, sans toucher aux autres praticiens. La clé est indépendante de la casse de l'e-mail.
- `SELECT ... FOR UPDATE` et `INSERT ... ON CONFLICT DO NOTHING` sérialisent les tentatives pour **la même adresse** sur PostgreSQL.
- Migration Alembic `0004_login_throttling.py`. Aucun effacement ni réinitialisation automatique de dossiers cliniques.

## Couverture des tests

`backend/tests/test_login_throttling.py` : compte existant/inexistant, compteur 5 essais, verrou intact même si la fenêtre initiale expire, expiration, réinitialisation après succès, variantes majuscules, compte voisin non bloqué.

`backend/tests/test_postgres_isolation.py` : validation réelle sur PostgreSQL 17 (migrations appliquées) des limites d'essais et de l'indépendance entre praticiens.

## Ce que cette mesure ne garantit **pas**

- **Ce n'est pas une protection suffisante contre le credential stuffing distribué** : il reste à ajouter une limitation indépendante par client/IP au niveau de la passerelle ou reverse proxy, une stratégie anti-abus adaptée et des métriques (sans données médicales).
- Un attaquant connaissant une adresse peut provoquer un verrouillage temporaire (risque de déni de service ciblé). Avant production, prévoir un dispositif de déverrouillage fiable et une évaluation de risque.
- Les contrôles d'authentification sont encore en développement : validation e-mail, récupération sécurisée des mots de passe, MFA selon risques, politique d'expiration et de rotation des secrets, journal de sécurité minimal et alertes.
- Aucune forme de traitement de données de santé réelles n'est autorisée par cette modification. Le parcours d'hébergement et les formalités CDP au Sénégal restent à valider.

**Ne pas afficher « sécurité production validée » à partir d'une CI verte**. Les tests automatisés prouvent des scénarios limités, pas l'absence de vulnérabilités.
