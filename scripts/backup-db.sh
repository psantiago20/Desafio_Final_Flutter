#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

PG_USER="${PG_USER:-pitaya}"
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_PASSWORD="${PG_PASSWORD:?PG_PASSWORD não definida}"

export PGPASSWORD="$PG_PASSWORD"

DATABASES=(
  "pitaya_auth"
  "pitaya_user"
  "pitaya_post"
  "pitaya_group"
  "pitaya_library"
  "pitaya_mentorship"
  "pitaya_gamification"
  "notification_db"
)

mkdir -p "$BACKUP_DIR"

echo "========================================"
echo "  Pitaya - Database Backup"
echo "  Timestamp: $TIMESTAMP"
echo "  Host:      $PG_HOST:$PG_PORT"
echo "  User:      $PG_USER"
echo "========================================"

if ! pg_isready -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" > /dev/null 2>&1; then
  echo "PostgreSQL not reachable"
  exit 1
fi

for db in "${DATABASES[@]}"; do
  BACKUP_FILE="${BACKUP_DIR}/${db}_${TIMESTAMP}.sql.gz"
  echo -n "  Backing up $db... "

  if pg_dump \
      -h "$PG_HOST" \
      -p "$PG_PORT" \
      -U "$PG_USER" \
      -d "$db" \
      --no-owner \
      --no-acl \
      --clean \
      --if-exists \
      2>/dev/null | gzip > "$BACKUP_FILE"; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "done ($SIZE)"
  else
    rm -f "$BACKUP_FILE"
    echo "failed"
  fi
done

unset PGPASSWORD

echo ""
echo "Backup complete."
echo "Location: $BACKUP_DIR"
echo ""
echo "To restore a database:"
echo "  gunzip -c backups/<db>_<timestamp>.sql.gz | psql -U $PG_USER -d <db>"