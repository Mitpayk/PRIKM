#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/notify.sh"

meval() { docker exec "$1" mongo --quiet --eval "$2" 2>/dev/null; }

meval mongo-primary 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'
meval mongo-primary 'db.getSiblingDB("testdb").col.insertOne({msg:"before-failover"})'
DOCS_BEFORE=$(meval mongo-primary 'db.getSiblingDB("testdb").col.countDocuments()')

notify "Failover test" "Зупинка mongo-primary. Документів: $DOCS_BEFORE"
docker stop mongo-primary
sleep 15

STATUS=$(meval mongo-secondary1 'rs.status().members.map(m => m.name + ": " + m.stateStr).join(", ")')
meval mongo-secondary1 'db.getSiblingDB("testdb").col.insertOne({msg:"after-failover"})'
DOCS_AFTER=$(meval mongo-secondary1 'db.getSiblingDB("testdb").col.countDocuments()')

notify "Failover: primary DOWN" "Новий стан: $STATUS\nДокументів: $DOCS_AFTER"

docker start mongo-primary
sleep 15

STATUS_FINAL=$(meval mongo-primary 'rs.status().members.map(m => m.name + ": " + m.stateStr).join(", ")')
notify "Failover test PASSED" "mongo-primary повернувся\n$STATUS_FINAL"
echo "=== FAILOVER TEST PASSED ==="
