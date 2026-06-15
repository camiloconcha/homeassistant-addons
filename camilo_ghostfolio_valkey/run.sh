#!/bin/sh
set -eu

CONFIG=/data/options.json
REDIS_PASSWORD="$(jq -r '.redis_password // ""' "$CONFIG")"

if [ -z "$REDIS_PASSWORD" ]; then
  echo "[valkey] redis_password is required"
  exit 1
fi

mkdir -p /data/valkey
chown -R valkey:valkey /data/valkey

exec su-exec valkey valkey-server \
  --dir /data/valkey \
  --appendonly yes \
  --requirepass "$REDIS_PASSWORD"
