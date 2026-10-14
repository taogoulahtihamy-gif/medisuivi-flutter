#!/usr/bin/env bash
# P4.9: controlled local upgrade of MediSuivi's EXISTING synthetic test DB.
# Reads no real medical records. Never touches ERP/Chak, never removes a volume.
set -Eeuo pipefail
set +x
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND="$ROOT/backend"
BACKUP_DIR="/mnt/chak/medisuivi-local-backups"
BACKUP="$BACKUP_DIR/p49-pre-upgrade-$(date -u +%Y%m%dT%H%M%SZ).dump"
OLD_IMAGE=""
RESTORE_OLD=0

rollback() {
  local exit_code=$?
  trap - EXIT
  if ((exit_code != 0 && RESTORE_OLD == 1)); then
    echo "===== P4.9 ERROR : restore old API image, preserve PG volume =====" >&2
    docker compose -p medisuivi -f "$BACKEND/docker-compose.yml" stop api >/dev/null 2>&1 || true
    if [[ -n "$OLD_IMAGE" ]]; then
      docker tag "$OLD_IMAGE" medisuivi-api:latest || true
      docker compose -p medisuivi -f "$BACKEND/docker-compose.yml" \
        up -d --no-deps --force-recreate api || true
    fi
    echo "The additive Alembic migration may remain applied." >&2
    echo "PostgreSQL volume and backup remain intact." >&2
  fi
  exit "$exit_code"
}
trap rollback EXIT

cd "$BACKEND"
echo "===== 1. VERIFY CURRENT ISOLATED MEDISUIVI ====="
for name in medisuivi-api-1 medisuivi-postgres-1; do
  [[ "$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$name")" == "medisuivi" ]]
  [[ "$(docker inspect -f '{{.State.Running}}' "$name")" == "true" ]]
done
[[ "$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}' medisuivi-postgres-1)" == "medisuivi_pgdata" ]]
docker volume inspect medisuivi_pgdata backend_pgdata erp_postgres_data >/dev/null

echo "===== 2. CHECK HEALTH AND CURRENT REVISION ====="
curl --noproxy '*' --fail -sS --max-time 8 http://127.0.0.1:8027/ready >/dev/null
old_revision="$(docker exec medisuivi-postgres-1 psql -Atq -U medisuivi -d medisuivi -c 'SELECT version_num FROM alembic_version')"
if [[ "$old_revision" != "0005" && "$old_revision" != "0006" ]]; then
  echo "Unknown PostgreSQL revision: $old_revision. Abort." >&2
  exit 1
fi
echo "Previous revision: $old_revision"

echo "===== 3. REUSE EXISTING SECRETS, NEVER PRINT OR WRITE THEM ====="
eval "$(python3 - <<'PY'
import json
import shlex
import subprocess
containers = json.loads(subprocess.check_output(
    ['docker', 'inspect', 'medisuivi-postgres-1', 'medisuivi-api-1'],
    text=True,
))
pg, api = (
    dict(s.split('=', 1) for s in container['Config']['Env'] if '=' in s)
    for container in containers
)
data = {
    'POSTGRES_PASSWORD': pg.get('POSTGRES_PASSWORD', ''),
    'APP_JWT_SECRET': api.get('APP_JWT_SECRET', ''),
}
if not all(data.values()):
    raise SystemExit('Required existing secrets are missing')
for key in (
    'APP_ALLOW_DEVELOPMENT_REGISTRATION',
    'APP_ENABLE_EMAIL_AUTH', 'APP_SMTP_HOST', 'APP_SMTP_PORT',
    'APP_SMTP_FROM', 'APP_SMTP_STARTTLS', 'APP_SMTP_USER',
    'APP_SMTP_PASSWORD',
):
    if key in api:
        data[key] = api[key]
for key, value in data.items():
    print('export ' + key + '=' + shlex.quote(value))
PY
)"
docker compose -p medisuivi config --format json |
  python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["name"]=="medisuivi"; assert d["volumes"]["pgdata"]["name"]=="medisuivi_pgdata"; assert set(d["services"])=={"api","postgres"}'

echo "===== 4. FINGERPRINT OWNED CLINICAL ROWS ====="
SQL="SELECT 'patients:' || count(*) || ':' || md5(coalesce(string_agg(id, ',' ORDER BY id), '')) FROM patients
UNION ALL SELECT 'visits:' || count(*) || ':' || md5(coalesce(string_agg(id, ',' ORDER BY id), '')) FROM visits
UNION ALL SELECT 'exams:' || count(*) || ':' || md5(coalesce(string_agg(id, ',' ORDER BY id), '')) FROM exams
UNION ALL SELECT 'followups:' || count(*) || ':' || md5(coalesce(string_agg(id, ',' ORDER BY id), '')) FROM followups;"
before="$(docker exec medisuivi-postgres-1 psql -Atq -U medisuivi -d medisuivi -c "$SQL")"
printf '%s\n' "$before" | cut -d: -f1,2

echo "===== 5. PRIVATE CONSISTENT POSTGRESQL BACKUP ====="
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
[[ ! -e "$BACKUP" ]]
docker exec medisuivi-postgres-1 pg_dump -U medisuivi -d medisuivi -Fc > "$BACKUP"
test -s "$BACKUP"
docker exec -i medisuivi-postgres-1 pg_restore -l < "$BACKUP" > /dev/null
echo "Backup readable: OK (keep outside Git, never share)"
echo "Backup size: $(du -h "$BACKUP" | cut -f1)"

echo "===== 6. BUILD NEW BACKEND FIRST ====="
OLD_IMAGE="$(docker inspect medisuivi-api-1 --format '{{.Image}}')"
test -n "$OLD_IMAGE"
docker compose -p medisuivi build api

echo "===== 7. STOP ONLY MEDISUIVI API AND UPGRADE ADDITIVELY ====="
RESTORE_OLD=1
docker compose -p medisuivi stop api
docker compose -p medisuivi run --rm --no-deps \
  api python -m alembic upgrade head
revision="$(docker exec medisuivi-postgres-1 psql -Atq -U medisuivi -d medisuivi -c 'SELECT version_num FROM alembic_version')"
[[ "$revision" == "0006" ]] || { echo "Unexpected new migration: $revision" >&2; exit 1; }

echo "===== 8. START ONLY UPDATED MEDISUIVI API ====="
docker compose -p medisuivi up -d --no-deps --force-recreate api
ready=0
for ((i=0; i<45; i++)); do
  if curl --noproxy '*' --fail -sS --connect-timeout 2 --max-time 4 \
      http://127.0.0.1:8027/health >/dev/null 2>&1 &&
      curl --noproxy '*' --fail -sS --connect-timeout 2 --max-time 4 \
      http://127.0.0.1:8027/ready >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 2
done
[[ "$ready" == "1" ]] || { docker logs --tail 40 medisuivi-api-1; exit 1; }

echo "===== 9. ENSURE NO OLD ROWS DISAPPEARED ====="
after="$(docker exec medisuivi-postgres-1 psql -Atq -U medisuivi -d medisuivi -c "$SQL")"
[[ "$before" == "$after" ]] || {
  echo "Clinical row ID fingerprints changed; review required" >&2
  exit 1
}
printf '%s\n' "$after" | cut -d: -f1,2
docker compose -p medisuivi ps
echo "P4.9 backend READY; old DB volume unchanged; backup kept."
RESTORE_OLD=0
