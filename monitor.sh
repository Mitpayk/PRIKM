#!/usr/bin/env bash
source "$(dirname "$0")/notify.sh"

echo "[*] Starting MongoDB container monitor..."
notify "Monitor started" "Слідкую за контейнерами: mongo-primary, mongo-secondary1, mongo-secondary2"

docker events \
  --filter "container=mongo-primary" \
  --filter "container=mongo-secondary1" \
  --filter "container=mongo-secondary2" \
  --filter "event=start" \
  --filter "event=stop" \
  --filter "event=die" \
  --filter "event=kill" \
  --format "{{.Actor.Attributes.name}} {{.Action}}" | \
while read -r container action; do
  case "$action" in
    die|stop|kill)
      notify "Container DOWN: $container" " $container зупинився (action: $action)"
      ;;
    start)
      notify "Container UP: $container" "$container запустився"
      ;;
  esac
done
