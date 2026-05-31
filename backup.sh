#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/notify.sh"
 
BACKUP_DIR="$(dirname "$0")/backup"
mkdir -p "$BACKUP_DIR"
TS=$(date +"%Y%m%d_%H%M%S")
 
notify "Backup started" "Розпочато резервне копіювання $TS"
 
if ! docker exec mongo-primary mongodump --out /tmp/dump_$TS; then
  notify "Backup FAILED" "mongodump завершився з помилкою"
  exit 1
fi
 
docker cp mongo-primary:/tmp/dump_$TS "$BACKUP_DIR/dump_$TS"
docker exec mongo-primary rm -rf /tmp/dump_$TS
 
tar -czf "$BACKUP_DIR/backup_$TS.tar.gz" -C "$BACKUP_DIR" "dump_$TS"
rm -rf "$BACKUP_DIR/dump_$TS"
ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +6 | xargs rm -f 2>/dev/null || true
 
notify "Backup done" "Файл: backup_$TS.tar.gz"
echo "[+] Backup: $BACKUP_DIR/backup_$TS.tar.gz"
 
