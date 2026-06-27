#!/bin/sh
set -eu

CONFIG=/data/options.json

POSTGRES_DB="$(jq -r '.postgres_db // "coolify"' "$CONFIG")"
POSTGRES_USER="$(jq -r '.postgres_user // "coolify"' "$CONFIG")"
POSTGRES_PASSWORD="$(jq -r '.postgres_password // ""' "$CONFIG")"

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "[coolify-postgres] postgres_password is required"
  exit 1
fi

export POSTGRES_DB
export POSTGRES_USER
export POSTGRES_PASSWORD
export PGDATA=/data/postgresql

exec docker-entrypoint.sh postgres
