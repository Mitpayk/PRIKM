#!/usr/bin/env bash
notify() {
  local title="$1" msg="$2"
  curl -s -o /dev/null -X POST \
    "https://notify.events/api/v1/channel/ct-q5dageamlhvfjlsdlvlanmkxqwcfx/message" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$title\",\"text\":\"$msg\"}"
}
