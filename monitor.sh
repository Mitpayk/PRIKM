#!/usr/bin/env bash
source "$(dirname "$0")/notify.sh"

CONTAINERS=("mongo-primary" "mongo-secondary1" "mongo-secondary2")
declare -A PREV_STATE

echo "[*] Starting MongoDB container monitor..."
notify "Monitor started" "Слідкую за: ${CONTAINERS[*]}"


for c in "${CONTAINERS[@]}"; do
  PREV_STATE[$c]=$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null || echo "false")
done

while true; do
  for c in "${CONTAINERS[@]}"; do
    STATE=$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null || echo "false")
    if [[ "${PREV_STATE[$c]}" != "$STATE" ]]; then
      if [[ "$STATE" == "true" ]]; then
        notify "Container UP: $c" " $c запустився"
      else
        notify "Container DOWN: $c" " $c зупинився або впав"
      fi
      PREV_STATE[$c]="$STATE"
    fi
  done
  sleep 5
done
