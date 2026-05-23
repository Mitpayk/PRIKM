#!/usr/bin/env bash
set -euo pipefail

echo "[*] Waiting for mongo-primary..."
until docker exec mongo-primary mongosh --quiet \
  -u admin -p secret123 --authenticationDatabase admin \
  --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q 1; do
  sleep 3
done

STATUS=$(docker exec mongo-primary mongosh --quiet \
  -u admin -p secret123 --authenticationDatabase admin \
  --eval "try { rs.status().ok } catch(e) { 0 }" 2>/dev/null)

if [[ "$STATUS" == "1" ]]; then
  echo "[!] Already initialised"
  exit 0
fi

docker exec mongo-primary mongosh \
  -u admin -p secret123 --authenticationDatabase admin \
  --eval '
    rs.initiate({
      _id: "rs0",
      members: [
        { _id: 0, host: "mongo-primary:27017", priority: 2 },
        { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
        { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
      ]
    })
  '

sleep 10
docker exec mongo-primary mongosh --quiet \
  -u admin -p secret123 --authenticationDatabase admin \
  --eval 'rs.status().members.forEach(m => print(m.name, "->", m.stateStr))'

echo "[+] Done"
