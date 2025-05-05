#!/bin/bash

set -e

# SRC filepath = Path inside our container
SRC_KEYFILE="/envs/mongo-keyfile"
# DEST filepath =  new path with updated permissions
DEST_KEYFILE="/etc/mongo-keyfile/keyfile"

# # Default replica set name
# REPLICA_SET_NAME="myReplicaSet"

# Ensure the destination exists
mkdir -p $(dirname "$DEST_KEYFILE")

# Copy contents from the mounted keyfile
if [[ -f "$SRC_KEYFILE" ]]; then
  cat "$SRC_KEYFILE" > "$DEST_KEYFILE"
  chmod 400 "$DEST_KEYFILE"
  echo "✅ Copied and set permissions on $DEST_KEYFILE"
else
  echo "❌ Keyfile not found at $SRC_KEYFILE"
  exit 1
fi