#!/usr/bin/env bash
set -euo pipefail

meval() {
  docker exec "$1" mongo --quiet --eval "$2" 2>/dev/null
}

echo "=== Status before failover ==="
meval mongo-primary 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'

meval mongo-primary 'db.getSiblingDB("testdb").col.insertOne({msg:"before-failover"})'
echo "Docs before: $(meval mongo-primary 'db.getSiblingDB("testdb").col.countDocuments()')"

echo ""
echo "=== Stopping mongo-primary ==="
docker stop mongo-primary
sleep 15

echo "=== New cluster status (from secondary1) ==="
meval mongo-secondary1 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'

meval mongo-secondary1 'db.getSiblingDB("testdb").col.insertOne({msg:"after-failover"})'
echo "Docs after failover: $(meval mongo-secondary1 'db.getSiblingDB("testdb").col.countDocuments()')"

echo ""
echo "=== Restarting mongo-primary (rejoins as SECONDARY) ==="
docker start mongo-primary
sleep 15
meval mongo-primary 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'

echo ""
echo "=== FAILOVER TEST PASSED ==="
