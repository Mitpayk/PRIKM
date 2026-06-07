#!/usr/bin/env bash
notify() {
  local title="$1" text="$2" level="${3:-info}"
  text=$(echo -e "$text")
  curl -s -o /dev/null -X POST \
    "https://notify.events/api/v1/channel/source/9h6syw0bnb9ecpn5zkctmnf12qfnpyqy/execute" \
    -F "title=$title" \
    -F "text=$text" \
    -F "level=$level"
}
