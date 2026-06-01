#!/usr/bin/env bash
notify() {
  local title="$1" text="$2" level="${3:-info}"
  curl -s -o /dev/null -X POST \
    "https://notify.events/api/v1/channel/source/e6qrxvp5q8bn_7-5luupdj_ao9wosckq/execute" \
    -F "title=$title" \
    -F "text=$text" \
    -F "level=$level"
}
