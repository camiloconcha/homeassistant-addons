#!/bin/sh
set -eu

CONFIG=/data/options.json
REDIS_PASSWORD="$(jq -r '.redis_password // ""' "$CONFIG")"

if [ -z "$REDIS_PASSWORD" ]; then
  echo "[coolify-redis] redis_password is required"
  exit 1
fi

mkdir -p /data/redis
chown -R redis:redis /data/redis

exec su-exec redis redis-server \
  --dir /data/redis \
  --appendonly yes \
  --save 20 1 \
  --loglevel warning \
  --requirepass "$REDIS_PASSWORD"
