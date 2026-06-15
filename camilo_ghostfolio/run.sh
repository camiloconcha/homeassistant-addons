#!/bin/sh
set -eu

CONFIG=/data/options.json

get_option() {
  node - "$1" <<'NODE'
const fs = require('fs');
const options = JSON.parse(fs.readFileSync('/data/options.json', 'utf8'));
const key = process.argv[2];
const value = options[key];
if (value !== undefined && value !== null) {
  process.stdout.write(String(value));
}
NODE
}

DATABASE_URL="$(node <<'NODE'
const fs = require('fs');
const options = JSON.parse(fs.readFileSync('/data/options.json', 'utf8'));
const required = [
  'postgres_host',
  'postgres_port',
  'postgres_db',
  'postgres_user',
  'postgres_password'
];
for (const key of required) {
  if (options[key] === undefined || options[key] === null || `${options[key]}` === '') {
    console.error(`[ghostfolio] ${key} is required`);
    process.exit(1);
  }
}
const enc = encodeURIComponent;
const host = options.postgres_host;
const port = options.postgres_port;
const db = enc(options.postgres_db);
const user = enc(options.postgres_user);
const password = enc(options.postgres_password);
process.stdout.write(`postgresql://${user}:${password}@${host}:${port}/${db}?connect_timeout=300&sslmode=disable`);
NODE
)"

export DATABASE_URL

ROOT_URL="$(get_option root_url)"
POSTGRES_HOST="$(get_option postgres_host)"
POSTGRES_PORT="$(get_option postgres_port)"
REDIS_HOST="$(get_option redis_host)"
REDIS_PORT="$(get_option redis_port)"
REDIS_PASSWORD="$(get_option redis_password)"
ACCESS_TOKEN_SALT="$(get_option access_token_salt)"
JWT_SECRET_KEY="$(get_option jwt_secret_key)"
BASE_CURRENCY="$(get_option base_currency)"

if [ -z "$REDIS_HOST" ]; then
  echo "[ghostfolio] redis_host is required"
  exit 1
fi
if [ -z "$REDIS_PASSWORD" ]; then
  echo "[ghostfolio] redis_password is required"
  exit 1
fi
if [ -z "$ACCESS_TOKEN_SALT" ]; then
  echo "[ghostfolio] access_token_salt is required"
  exit 1
fi
if [ -z "$JWT_SECRET_KEY" ]; then
  echo "[ghostfolio] jwt_secret_key is required"
  exit 1
fi

export NODE_ENV=production
export HOST=0.0.0.0
export PORT=3333
export ROOT_URL
export BASE_CURRENCY
export REDIS_HOST
export REDIS_PORT
export REDIS_PASSWORD
export ACCESS_TOKEN_SALT
export JWT_SECRET_KEY

wait_for_tcp() {
  name="$1"
  host="$2"
  port="$3"
  node - "$name" "$host" "$port" <<'NODE'
const net = require('net');
const [name, host, portText] = process.argv.slice(2);
const port = Number(portText);
let attempts = 0;
const maxAttempts = 60;

function tryConnect() {
  attempts += 1;
  const socket = net.createConnection({ host, port, timeout: 2000 });
  socket.on('connect', () => {
    socket.destroy();
    process.exit(0);
  });
  socket.on('timeout', () => socket.destroy());
  socket.on('error', () => {});
  socket.on('close', () => {
    if (attempts >= maxAttempts) {
      console.error(`[ghostfolio] ${name} did not become reachable at ${host}:${port}`);
      process.exit(1);
    }
    setTimeout(tryConnect, 2000);
  });
}

tryConnect();
NODE
}

echo "[ghostfolio] Waiting for PostgreSQL at ${POSTGRES_HOST}:${POSTGRES_PORT}"
wait_for_tcp PostgreSQL "$POSTGRES_HOST" "$POSTGRES_PORT"

echo "[ghostfolio] Waiting for Valkey at ${REDIS_HOST}:${REDIS_PORT}"
wait_for_tcp Valkey "$REDIS_HOST" "$REDIS_PORT"

exec gosu node /ghostfolio/entrypoint.sh
