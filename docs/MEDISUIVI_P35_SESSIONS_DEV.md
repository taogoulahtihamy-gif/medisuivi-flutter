# Sprint P3.5 : sessions distinctes et révocables (développement)

## Réellement implémenté

Chaque inscription/connexion ouvre une session `auth_sessions` liée à un
praticien. Les comptes n'ont aucun accès aux sessions des autres.

- Access JWT **15 minutes** avec `sid`, `sv`, `sub`, `jti`, issuer et
  audience vérifiés côté serveur. Toute requête vérifie aussi l'état de
  `auth_sessions`. Un JWT signé reste **inutilisable** après révocation.
- Refresh secret opaque et aléatoire de 48 octets, durée 7 jours, enregistré
  uniquement sous sa **empreinte SHA-256**. Le client voit la valeur brute
  une seule fois lors de la connexion et reçoit une nouvelle valeur à chaque
  `POST /api/v1/auth/refresh`.
- Rotation transactionnelle sous verrou PostgreSQL ; réemploi confirmé de
  la valeur précédente = révocation **de cet appareil seulement**. Une valeur
  arbitraire incorrecte ne révoque pas un appareil innocent.
- `POST /api/v1/auth/logout` invalide la session courante uniquement.
  `POST /api/v1/auth/logout-all` invalide toutes les sessions du praticien
  en incrémentant `session_version`.
- Flutter garde les deux jetons **en mémoire seulement**. Sur un 401 d'un
  appel clinique, une seule demande de rafraîchissement est exécutée, puis
  la requête est rejouée **une fois**. Les demandes parallèles partagent le
  renouvellement en cours.
- Déconnexion Flutter : les jetons sont effacés localement même en cas
  d'erreur réseau, et les données de l'ancien compte ne restent plus
  affichées. Une révocation côté serveur **non confirmée** n'est pas
  présentée comme réussie.
- Migration `0003_rotating_auth_sessions` nécessaire avant redémarrage de
  l'API pour ne pas recevoir d'erreurs de table manquante.

## Vérifier sur Ubuntu

Sur une base PostgreSQL de développement, **sans suppression de volume** :
```bash
cd /mnt/chak/medisuivi-flutter/backend
# Récupérer les variables d'environnement déjà définies pour le service.
docker compose up -d --build
docker compose exec api python -m alembic upgrade head
curl --noproxy '*' http://127.0.0.1:8027/ready
```

À faire avec deux sessions du même compte puis deux comptes distincts :
1. A s'authentifie sur deux sessions, B avec son propre compte.
2. Déconnecter l'appareil A1 : A2 doit fonctionner, B aussi.
3. Rafraîchir A2 : l'ancien jeton de rafraîchissement ne fonctionne plus.
4. Réemployer l'ancien jeton A2 : A2 doit être révoquée ; B reste valide.
5. `logout-all` avec une nouvelle session A : tous les appareils A sont
   révoqués ; aucun effet sur B.
6. Fermer/recharger Flutter : la session n'est **pas restaurée** par défaut,
   car la persistance par compte en stockage sûr n'a pas encore été validée.

Tests CI : `tests/test_sessions_rotation.py` (SQLite test) plus
`tests/test_postgres_isolation.py` avec PostgreSQL 17. Les tests de
navigation Flutter examinent les changements de comptes et la reconnexion.

## Ce qui manque avant une vraie production

**Interdiction des dossiers médicaux réels toujours en vigueur** :
- anti-bruteforce et rate limiting distribués ; vérification des emails,
  récupération de compte et éventuellement MFA ;
- durcissement clés de signature, secrets gérés hors dépôt, rotation clés,
  audit, gestion d'incidents et pentest ;
- sessions mobiles stockées de façon sécurisée, clés DB locales séparées par
  compte, stockage hors ligne/synchronisation authentifiés sans fuite ;
- sauvegarde/restauration, hébergement maîtrisé et formalités CDP au Sénégal ;
- revue de performance et robustesse de la rotation concurrente avec
  PostgreSQL sous charge, politiques d'expiration et consentement clinique.

La revue manuelle et le Go/No-Go restent obligatoires.
