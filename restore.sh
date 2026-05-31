#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/notify.sh"

BACKUP_DIR="$(dirname "$0")/backup"
ARCHIVE="${1:-$(ls -t "$BACKUP_DIR"/*.tar.gz | head -1)}"

notify "Restore started" "Відновлення з: $(basename "$ARCHIVE")"

TMPDIR=$(mktemp -d)
if ! tar -xzf "$ARCHIVE" -C "$TMPDIR"; then
  notify "Restore FAILED" "Не вдалося розпакувати: $(basename "$ARCHIVE")"
  rm -rf "$TMPDIR"
  exit 1
fi

DUMP=$(ls "$TMPDIR")
docker cp "$TMPDIR/$DUMP" mongo-primary:/tmp/restore_dump

if ! docker exec mongo-primary mongorestore --drop /tmp/restore_dump; then
  notify "Restore FAILED" "mongorestore завершився з помилкою"
  docker exec mongo-primary rm -rf /tmp/restore_dump
  rm -rf "$TMPDIR"
  exit 1
fi

docker exec mongo-primary rm -rf /tmp/restore_dump
rm -rf "$TMPDIR"

notify "Restore done" "Відновлено з: $(basename "$ARCHIVE")"
echo "[+] Restore complete"
