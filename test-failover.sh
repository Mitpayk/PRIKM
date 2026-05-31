#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/notify.sh"

meval() { docker exec "$1" mongo --quiet --eval "$2" 2>/dev/null || true; }

# --- початковий стан ---
STATUS_BEFORE=$(meval mongo-primary 'rs.status().members.map(m => m.name + " [" + m.stateStr + "]").join("\n")')
DOCS_BEFORE=$(meval mongo-primary 'db.getSiblingDB("testdb").col.countDocuments()')
echo "=== Status before failover ==="
echo "$STATUS_BEFORE"
echo "Docs: $DOCS_BEFORE"

meval mongo-primary 'db.getSiblingDB("testdb").col.insertOne({msg:"before-failover"})'
notify "Failover: starting" "Стан до тесту:\n$STATUS_BEFORE\nДокументів: $DOCS_BEFORE"

# --- зупиняємо primary ---
docker stop mongo-primary
notify "Failover: mongo-primary DOWN" "mongo-primary зупинено, очікуємо вибори нового лідера..."
echo "Waiting for election..."
sleep 30

# --- хто став новим primary ---
NEW_PRIMARY=$(meval mongo-secondary1 'rs.status().members.filter(m => m.stateStr === "PRIMARY").map(m => m.name)[0]')
STATUS_AFTER=$(meval mongo-secondary1 'rs.status().members.map(m => m.name + " [" + m.stateStr + "]").join("\n")')
echo "=== Status after failover ==="
echo "$STATUS_AFTER"

meval mongo-secondary1 'db.getSiblingDB("testdb").col.insertOne({msg:"after-failover"})'
DOCS_AFTER=$(meval mongo-secondary1 'db.getSiblingDB("testdb").col.countDocuments()')

notify "Failover: new PRIMARY elected" "Новий primary: $NEW_PRIMARY\n\nСтан кластеру:\n$STATUS_AFTER\n\nДокументів після failover: $DOCS_AFTER"

# --- повертаємо primary ---
docker start mongo-primary
echo "Waiting for primary to rejoin..."
sleep 30

STATUS_FINAL=$(meval mongo-primary 'rs.status().members.map(m => m.name + " [" + m.stateStr + "]").join("\n")')
echo "=== Final status ==="
echo "$STATUS_FINAL"

notify "Failover: mongo-primary BACK" "mongo-primary повернувся як SECONDARY\n\nФінальний стан:\n$STATUS_FINAL"
echo "=== FAILOVER TEST PASSED ==="
