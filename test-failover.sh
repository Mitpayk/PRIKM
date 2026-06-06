#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/notify.sh"

meval() { docker exec "$1" mongo --quiet --eval "$2" 2>/dev/null || true; }

STATUS_BEFORE=$(meval mongo-primary 'rs.status().members.map(m => m.name + " [" + m.stateStr + "]").join("\n")')
DOCS_BEFORE=$(meval mongo-primary 'db.getSiblingDB("testdb").col.count()')

echo "$STATUS_BEFORE"
echo "Docs: $DOCS_BEFORE"

meval mongo-primary 'db.getSiblingDB("testdb").col.insertOne({msg:"before-failover"})'
notify "Failover: starting" "Status before:\n$STATUS_BEFORE\n" "info"

docker stop mongo-primary
notify "Failover" "mongo-primary stopped" "warning"
sleep 30


NEW_PRIMARY=$(meval mongo-secondary1 'rs.status().members.filter(m => m.stateStr === "PRIMARY").map(m => m.name)[0]')
STATUS_AFTER=$(meval mongo-secondary1 'rs.status().members.map(m => m.name + " [" + m.stateStr + "]").join("\n")')
DOCS_AFTER=$(meval mongo-secondary1 'db.getSiblingDB("testdb").col.count()')


meval mongo-secondary1 'db.getSiblingDB("testdb").col.insertOne({msg:"after-failover"})'
notify "PRIMARY elected" "New primary: $NEW_PRIMARY Status:\n$STATUS_AFTER\n\n" "notice"

docker start mongo-primary

sleep 30

STATUS_FINAL=$(meval mongo-primary 'rs.status().members.map(m => m.name + " [" + m.stateStr + "]").join("\n")')

notify "Failover: mongo-primary BACK" "mongo-primary is back:\n$STATUS_FINAL" "success"
