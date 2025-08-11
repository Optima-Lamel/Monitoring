#!/usr/bin/env bash
set -euo pipefail
# Requires: PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE in env or .env
# Usage: ./scripts/export_old_zabbix_pg.sh [--dir backups] [--format Fc|Fd] [--stop-zabbix]
OUTDIR="backups"; FMT="Fc"; STOP_ZBX=0; PARALLEL="${PARALLEL:-4}"
while [[ $# -gt 0 ]]; do case "$1" in
  --dir) OUTDIR="$2"; shift 2 ;;
  --format) FMT="$2"; shift 2 ;;
  --stop-zabbix) STOP_ZBX=1; shift ;;
  *) echo "Unknown arg: $1"; exit 1 ;; esac; done
[[ -f ".env" ]] && export $(grep -E '^(PGHOST|PGPORT|PGUSER|PGPASSWORD|PGDATABASE)=' .env | xargs)
: "${PGPORT:?}"; : "${PGUSER:?}"; : "${PGPASSWORD:?}"; : "${PGDATABASE:?}"
mkdir -p "$OUTDIR"; DATE="$(date +%F)"
psql -c "select version();" >/dev/null
pg_dumpall --globals-only > "$OUTDIR/zabbix_globals_${DATE}.sql"
psql -c "select extname, extversion from pg_extension;" > "$OUTDIR/exts_${DATE}.txt"
[[ "$STOP_ZBX" -eq 1 ]] && sudo systemctl stop zabbix-server || true
if [[ "$FMT" == "Fd" ]]; then
  pg_dump -Fd -j "$PARALLEL" --no-owner --no-privileges --quote-all-identifiers     -f "$OUTDIR/zabbix_${DATE}_dir" "$PGDATABASE"
else
  pg_dump -Fc --no-owner --no-privileges --quote-all-identifiers     -f "$OUTDIR/zabbix_${DATE}.dump" "$PGDATABASE"
fi
[[ "$STOP_ZBX" -eq 1 ]] && sudo systemctl start zabbix-server || true
( cd "$OUTDIR" && sha256sum zabbix_* exts_"$DATE".txt zabbix_globals_"$DATE".sql > checksums.txt )
echo "[✓] Dump in $OUTDIR"
