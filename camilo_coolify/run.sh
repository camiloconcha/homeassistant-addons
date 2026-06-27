#!/bin/sh
set -eu

CONFIG=/data/options.json
ENV_FILE=/var/www/html/.env

get_option() {
  jq -r --arg key "$1" '.[$key] // ""' "$CONFIG"
}

require_option() {
  key="$1"
  value="$(get_option "$key")"
  if [ -z "$value" ]; then
    echo "[coolify] ${key} is required"
    exit 1
  fi
  printf '%s' "$value"
}

resolve_addon_host() {
  configured="$1"
  target_slug="$2"

  if [ "$configured" != "auto" ]; then
    printf '%s' "$configured"
    return
  fi

  own_hostname="${HOSTNAME:-}"
  suffix="-camilo-coolify"
  if [ -z "$own_hostname" ] || [ "${own_hostname%$suffix}" = "$own_hostname" ]; then
    echo "[coolify] Could not auto-detect add-on hostname. Set ${target_slug}_host manually." >&2
    exit 1
  fi

  repo_prefix="${own_hostname%$suffix}"
  printf '%s-camilo-coolify-%s' "$repo_prefix" "$target_slug"
}

dotenv_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g'
}

write_env() {
  key="$1"
  value="$2"
  escaped="$(dotenv_escape "$value")"
  printf '%s="%s"\n' "$key" "$escaped" >> "$ENV_FILE"
}

wait_for_tcp() {
  name="$1"
  host="$2"
  port="$3"
  attempts=0
  max_attempts=90

  echo "[coolify] Waiting for ${name} at ${host}:${port}"
  while [ "$attempts" -lt "$max_attempts" ]; do
    if php -r '$s=@fsockopen($argv[1], (int)$argv[2], $errno, $errstr, 2); if ($s) { fclose($s); exit(0); } exit(1);' "$host" "$port"; then
      return
    fi
    attempts=$((attempts + 1))
    sleep 2
  done

  echo "[coolify] ${name} did not become reachable at ${host}:${port}"
  exit 1
}

verify_redis_auth() {
  host="$1"
  port="$2"
  password="$3"

  echo "[coolify] Verifying Redis authentication at ${host}:${port}"
  if ! php -r '
    try {
      $redis = new Redis();
      $redis->connect($argv[1], (int) $argv[2], 3);
      if ($argv[3] !== "") {
        $redis->auth($argv[3]);
      }
      $redis->ping();
      exit(0);
    } catch (Throwable $e) {
      fwrite(STDERR, $e->getMessage() . PHP_EOL);
      exit(1);
    }
  ' "$host" "$port" "$password"; then
    echo "[coolify] Redis authentication failed. Make redis_password identical in Camilo Coolify and Camilo Coolify Redis."
    exit 1
  fi
}

ROOT_URL="$(require_option root_url)"
APP_ID="$(require_option app_id)"
APP_KEY="$(require_option app_key)"
DB_HOST="$(resolve_addon_host "$(get_option db_host)" postgres)"
DB_PORT="$(get_option db_port)"
DB_DATABASE="$(require_option db_database)"
DB_USERNAME="$(require_option db_username)"
DB_PASSWORD="$(require_option db_password)"
REDIS_HOST="$(resolve_addon_host "$(get_option redis_host)" redis)"
REDIS_PORT="$(get_option redis_port)"
REDIS_PASSWORD="$(require_option redis_password)"
REALTIME_HOST="$(resolve_addon_host "$(get_option realtime_host)" realtime)"
REALTIME_BACKEND_PORT="$(get_option realtime_backend_port)"
PUSHER_APP_ID="$(require_option pusher_app_id)"
PUSHER_APP_KEY="$(require_option pusher_app_key)"
PUSHER_APP_SECRET="$(require_option pusher_app_secret)"
PUSHER_HOST="$(get_option pusher_host)"
PUSHER_PORT="$(get_option pusher_port)"
TERMINAL_PROTOCOL="$(get_option terminal_protocol)"
TERMINAL_HOST="$(get_option terminal_host)"
TERMINAL_PORT="$(get_option terminal_port)"
ROOT_USERNAME="$(get_option root_username)"
ROOT_USER_EMAIL="$(get_option root_user_email)"
ROOT_USER_PASSWORD="$(get_option root_user_password)"
AUTOUPDATE="$(get_option autoupdate)"

if [ -n "$ROOT_USER_EMAIL" ] || [ -n "$ROOT_USER_PASSWORD" ]; then
  if [ -z "$ROOT_USER_EMAIL" ] || [ -z "$ROOT_USER_PASSWORD" ]; then
    echo "[coolify] root_user_email and root_user_password must be set together"
    exit 1
  fi
fi

mkdir -p \
  /data/coolify/ssh \
  /data/coolify/applications \
  /data/coolify/databases \
  /data/coolify/services \
  /data/coolify/backups \
  /data/coolify/ssl

for storage_dir in ssh applications databases services backups; do
  target="/var/www/html/storage/app/${storage_dir}"
  if [ ! -L "$target" ] || [ "$(readlink "$target" 2>/dev/null || true)" != "/data/coolify/${storage_dir}" ]; then
    rm -rf "$target"
    ln -s "/data/coolify/${storage_dir}" "$target"
  fi
done

chown -R www-data:www-data /data/coolify

: > "$ENV_FILE"
write_env APP_ENV production
write_env APP_DEBUG false
write_env APP_ID "$APP_ID"
write_env APP_NAME Coolify
write_env APP_KEY "$APP_KEY"
write_env APP_URL "$ROOT_URL"
write_env APP_PORT 8000
write_env SELF_HOSTED true
write_env COOLIFY_HA_ENABLE_LOCALHOST false
write_env BASE_CONFIG_PATH /data/coolify
write_env REGISTRY_URL ghcr.io
write_env DB_CONNECTION pgsql
write_env DB_HOST "$DB_HOST"
write_env DB_PORT "$DB_PORT"
write_env DB_DATABASE "$DB_DATABASE"
write_env DB_USERNAME "$DB_USERNAME"
write_env DB_PASSWORD "$DB_PASSWORD"
write_env REDIS_HOST "$REDIS_HOST"
write_env REDIS_PORT "$REDIS_PORT"
write_env REDIS_PASSWORD "$REDIS_PASSWORD"
write_env QUEUE_CONNECTION redis
write_env CACHE_DRIVER redis
write_env SESSION_DRIVER database
write_env BROADCAST_DRIVER pusher
write_env PUSHER_BACKEND_HOST "$REALTIME_HOST"
write_env PUSHER_BACKEND_PORT "$REALTIME_BACKEND_PORT"
write_env PUSHER_APP_ID "$PUSHER_APP_ID"
write_env PUSHER_APP_KEY "$PUSHER_APP_KEY"
write_env PUSHER_APP_SECRET "$PUSHER_APP_SECRET"
write_env PUSHER_HOST "$PUSHER_HOST"
write_env PUSHER_PORT "$PUSHER_PORT"
write_env TERMINAL_PROTOCOL "$TERMINAL_PROTOCOL"
write_env TERMINAL_HOST "$TERMINAL_HOST"
write_env TERMINAL_PORT "$TERMINAL_PORT"
write_env MIGRATION_ENABLED true
write_env SEEDER_ENABLED true
write_env HORIZON_ENABLED true
write_env SCHEDULER_ENABLED true
write_env NIGHTWATCH_ENABLED false
write_env AUTOUPDATE "$AUTOUPDATE"

if [ -n "$ROOT_USER_EMAIL" ]; then
  write_env ROOT_USERNAME "${ROOT_USERNAME:-Root User}"
  write_env ROOT_USER_EMAIL "$ROOT_USER_EMAIL"
  write_env ROOT_USER_PASSWORD "$ROOT_USER_PASSWORD"
fi

chmod 600 "$ENV_FILE"
chown www-data:www-data "$ENV_FILE"

wait_for_tcp PostgreSQL "$DB_HOST" "$DB_PORT"
wait_for_tcp Redis "$REDIS_HOST" "$REDIS_PORT"
verify_redis_auth "$REDIS_HOST" "$REDIS_PORT" "$REDIS_PASSWORD"
wait_for_tcp "Coolify realtime" "$REALTIME_HOST" "$REALTIME_BACKEND_PORT"

echo "[coolify] Starting Coolify. Local Home Assistant Docker management is disabled; add remote servers in Coolify over SSH."
exec docker-php-serversideup-entrypoint /init
