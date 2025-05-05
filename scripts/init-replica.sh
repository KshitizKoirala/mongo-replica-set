#!/bin/bash
set -e  # Exit immediately if any command fails
set -o pipefail  # Capture errors in pipes

##################################
# For Development purposes only. #
##################################

echo ====================================================
echo ============= Initializing Replica Set =============
echo ====================================================

wait_for_mongo() {
  local host=$1
  until mongosh --host "$host" --eval "db.runCommand({ ping: 1 })" &>/dev/null; do
    echo "Waiting for $host to be available..."
    sleep 2
  done
}

wait_for_mongo mongo1:27017
wait_for_mongo mongo2:27017
wait_for_mongo mongo3:27017


echo "All MongoDB instances up. Initiating Replica Set..."


mongosh --host mongo1:27017 -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin <<EOF
try {
  rs.status();
  print("Replica set already initialized.");
} catch (e) {
  print("Initializing replica set...");
  rs.initiate({
    _id: "rs0",
    members: [
      { _id: 0, host: "mongo1:27017", priority: 2 },
      { _id: 1, host: "mongo2:27017", priority: 1 },
      { _id: 2, host: "mongo3:27017", priority: 1 }
    ]
  });
}
EOF

echo ====================================================
echo ============= Replica Set initialized ==============
echo ====================================================