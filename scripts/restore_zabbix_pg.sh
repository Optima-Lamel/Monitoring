#!/usr/bin/env bash
set -euo pipefail
# Usage: ./scripts/restore_zabbix_pg.sh <path_to_dump.(dump|dir)> [postgres_container_name]
DUMP="${1:-}"; PGCONT="${2:-postgres}"
[[ -z "$DUMP" ]] && { echo "Usage: $0 <dump> [postgres_container_name]"; exit 1; }
source .env
if [[ -d "$DUMP" ]]; then
  echo "[!] Directory-format restore: copy directory into container and run:"
  echo "docker exec -it $PGCONT pg_restore -j 4 -U ${POSTGRES_USER} -d ${POSTGRES_DB} /path/in/container"
  exit 0
fi
docker cp "$DUMP" "$PGCONT:/tmp/zbx.dump"
docker exec -it "$PGCONT" bash -lc "pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DB} /tmp/zbx.dump"
echo "[✓] Restore done"
