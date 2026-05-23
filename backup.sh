#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$(dirname "$0")/backup"
mkdir -p "$BACKUP_DIR"
TS=$(date +"%Y%m%d_%H%M%S")

docker exec mongo-primary mongodump \
  -u admin -p secret123 --authenticationDatabase admin \
  --out /tmp/dump_$TS

docker cp mongo-primary:/tmp/dump_$TS "$BACKUP_DIR/dump_$TS"
docker exec mongo-primary rm -rf /tmp/dump_$TS

tar -czf "$BACKUP_DIR/backup_$TS.tar.gz" -C "$BACKUP_DIR" "dump_$TS"
rm -rf "$BACKUP_DIR/dump_$TS"

ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +6 | xargs rm -f 2>/dev/null || true
echo "[+] Backup: $BACKUP_DIR/backup_$TS.tar.gz"
