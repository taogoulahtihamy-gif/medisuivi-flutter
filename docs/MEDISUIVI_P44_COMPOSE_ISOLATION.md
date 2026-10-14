# P4.4.2 : isolation Docker de MediSuivi et conservation des données

**Développement uniquement, dossiers synthétiques. Ne jamais exécuter `down -v`, `--remove-orphans` ni `docker volume rm` pour cette migration.**

## Incident observé le 14 octobre 2026

La sortie locale de `docker compose ls -a` associe le projet Compose `backend` à deux fichiers distincts :
`/mnt/chak/medisuivi-flutter/backend/docker-compose.yml` et
`/mnt/chak/erp-saas/backend/docker-compose.yml`.

Les conteneurs `backend-api-1` et `backend-postgres-1` servent MediSuivi, alors que `erp_worker`, `erp_webhook_beat`, `erp_mailpit` et `erp_redis` appartiennent à l'ERP. Les volumes `backend_pgdata` (MediSuivi) et `erp_postgres_data` (ERP) existent. Dans le relevé, ni `erp_api` ni `erp_postgres` n'apparaissent.

## Nouvelle configuration

- `name: medisuivi` isole les conteneurs, le réseau et les opérations Compose de MediSuivi.
- `volumes.pgdata.name: medisuivi_pgdata` évite de réutiliser le volume générique `backend_pgdata` pour les nouvelles installations.
- Tous les ports et les réglages d'authentification existants sont conservés.
- **Attention :** lancer `docker compose up` avant de migrer le volume local démarrerait une *nouvelle* base, sans retrouver les données synthétiques de l'ancien volume. Cela ne les effacerait pas, mais ferait croire à une perte de données.
- `COMPOSE_PROJECT_NAME` et `docker compose -p ...` ont priorité sur `name:`. Utiliser `-p medisuivi` explicitement pendant la migration.

## Phase A : contrôles sans changement

Depuis `/mnt/chak/medisuivi-flutter/backend` :

```bash
docker compose ls -a
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
docker volume inspect backend_pgdata erp_postgres_data
docker inspect backend-postgres-1 --format '{{range .Mounts}}{{println .Name .Destination}}{{end}}'
docker exec backend-postgres-1 pg_isready -U medisuivi -d medisuivi
```

Ne pas continuer si le montage PostgreSQL de MediSuivi ne pointe pas sur `backend_pgdata`, si la base est inaccessible, si un volume est introuvable, ou si `medisuivi_pgdata` existe déjà (il faut alors analyser ses données, sans l'écraser).

## Phase B : sauvegarde PostgreSQL cohérente à chaud

Une sauvegarde par `pg_dump` évite de copier les fichiers PostgreSQL pendant que le serveur les modifie :

```bash
cd /mnt/chak/medisuivi-flutter/backend || exit 1
umask 077
mkdir -p ../local-backups
docker exec backend-postgres-1 pg_dump -U medisuivi -d medisuivi -Fc > ../local-backups/medisuivi-before-p44-compose.dump
test -s ../local-backups/medisuivi-before-p44-compose.dump || exit 1
```

**Garder cette sauvegarde hors Git et avec des permissions privées.** Vérifier sa validité et sa possibilité de restauration avant une migration définitive. Ne jamais télécharger ni partager le dump dans le chat.

## Phase C : déplacement physique à froid (uniquement après validation de A/B)

1. Conserver les **valeurs préexistantes** de `POSTGRES_PASSWORD` et `APP_JWT_SECRET`. Ne pas les régénérer à chaque lancement ; le mot de passe de rôle PostgreSQL stocké dans le volume reste inchangé.
2. Ne stopper que les deux conteneurs MediSuivi :
   `docker stop backend-api-1 backend-postgres-1`.
3. Confirmer que `medisuivi_pgdata` **n'existe pas** : `docker volume inspect medisuivi_pgdata` doit retourner une erreur "No such volume". Si le volume existe, arrêter cette procédure.
4. Créer `medisuivi_pgdata`, puis copier les fichiers PostgreSQL avec le conteneur arrêté et source en lecture seule :

```bash
docker volume create medisuivi_pgdata
docker run --rm --network none \
  --mount type=volume,src=backend_pgdata,dst=/from,readonly \
  --mount type=volume,src=medisuivi_pgdata,dst=/to \
  postgres:17-alpine sh -ec 'cd /from && tar cf - . | tar xf - -C /to'
```

5. Sur la branche contenant cette configuration, avec les variables de connexion **déjà restaurées depuis une source sûre** :

```bash
docker compose -p medisuivi config --format json |
  python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])'
docker compose -p medisuivi up -d --build
docker compose -p medisuivi ps
docker compose -p medisuivi exec postgres pg_isready -U medisuivi -d medisuivi
```

La première commande doit afficher `medisuivi`. Vérifier ensuite la connexion API, les migrations et la présence des dossiers **fictifs** avant de considérer la bascule terminée. Garder intact `backend_pgdata` comme sauvegarde de retour arrière. Les vieux conteneurs `backend-*` peuvent rester arrêtés temporairement.

## ERP : reprise dans un second temps, sans `--remove-orphans`

Les services et volumes de l'ERP ne sont pas modifiés dans cette PR. Avant de relancer l'ERP, vérifier sa configuration et ses variables `.env` dans `/mnt/chak/erp-saas/backend`. Son volume `erp_postgres_data` doit rester monté uniquement par son propre service PostgreSQL. La reprise doit ensuite être validée sur `http://127.0.0.1:8010` et par les tests de santé ERP habituels.

**Ne pas fusionner cette PR avant revue, sauvegarde confirmée et essais Docker locaux.**
