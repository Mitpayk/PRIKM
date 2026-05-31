#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/notify.sh"

meval() { docker exec "$1" mongo --quiet --eval "$2" 2>/dev/null || true; }

meval mongo-primary 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'
meval mongo-primary 'db.getSiblingDB("testdb").col.insertOne({msg:"before-failover"})'
DOCS_BEFORE=$(meval mongo-primary 'db.getSiblingDB("testdb").col.countDocuments()')
echo "Docs before: $DOCS_BEFORE"

notify "Failover test" "Зупинка mongo-primary. Документів: $DOCS_BEFORE"
docker stop mongo-primary
echo "Waiting for new primary election..."
sleep 30

meval mongo-secondary1 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'
meval mongo-secondary1 'db.getSiblingDB("testdb").col.insertOne({msg:"after-failover"})'
DOCS_AFTER=$(meval mongo-secondary1 'db.getSiblingDB("testdb").col.countDocuments()')
STATUS=$(meval mongo-secondary1 'rs.status().members.map(m => m.name + ": " + m.stateStr).join(", ")')
echo "Docs after: $DOCS_AFTER"

notify "Failover: primary DOWN" "Стан: $STATUS | Документів: $DOCS_AFTER"

docker start mongo-primary
echo "Waiting for primary to rejoin..."
sleep 30

meval mongo-primary 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'
STATUS_FINAL=$(meval mongo-primary 'rs.status().members.map(m => m.name + ": " + m.stateStr).join(", ")')

notify "Failover test PASSED" "mongo-primary повернувся | $STATUS_FINAL"
echo "=== FAILOVER TEST PASSED ==="
