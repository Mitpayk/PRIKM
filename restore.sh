#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$(dirname "$0")/backup"
ARCHIVE="${1:-$(ls -t "$BACKUP_DIR"/*.tar.gz | head -1)}"

echo "[*] Restoring from: $ARCHIVE"
TMPDIR=$(mktemp -d)
tar -xzf "$ARCHIVE" -C "$TMPDIR"
DUMP=$(ls "$TMPDIR")

docker cp "$TMPDIR/$DUMP" mongo-primary:/tmp/restore_dump
docker exec mongo-primary mongorestore \
  -u admin -p secret123 --authenticationDatabase admin \
  --drop /tmp/restore_dump

docker exec mongo-primary rm -rf /tmp/restore_dump
rm -rf "$TMPDIR"
echo "[+] Restore complete"
