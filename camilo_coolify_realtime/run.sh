#!/bin/sh
set -eu

CONFIG=/data/options.json

get_option() {
  jq -r --arg key "$1" '.[$key] // ""' "$CONFIG"
}

require_option() {
  key="$1"
  value="$(get_option "$key")"
  if [ -z "$value" ]; then
    echo "[coolify-realtime] ${key} is required"
    exit 1
  fi
  printf '%s' "$value"
}

resolve_coolify_host() {
  configured="$1"
  if [ "$configured" != "auto" ]; then
    printf '%s' "$configured"
    return
  fi

  own_hostname="${HOSTNAME:-}"
  suffix="-camilo-coolify-realtime"
  if [ -z "$own_hostname" ] || [ "${own_hostname%$suffix}" = "$own_hostname" ]; then
    echo "[coolify-realtime] Could not auto-detect Coolify hostname. Set coolify_host manually." >&2
    exit 1
  fi

  repo_prefix="${own_hostname%$suffix}"
  printf '%s-camilo-coolify' "$repo_prefix"
}

export APP_NAME="$(get_option app_name)"
export COOLIFY_HOST="$(resolve_coolify_host "$(get_option coolify_host)")"
export SOKETI_DEBUG="$(get_option soketi_debug)"
export SOKETI_DEFAULT_APP_ID="$(require_option pusher_app_id)"
export SOKETI_DEFAULT_APP_KEY="$(require_option pusher_app_key)"
export SOKETI_DEFAULT_APP_SECRET="$(require_option pusher_app_secret)"
export SOKETI_HOST=0.0.0.0

echo "[coolify-realtime] Starting realtime backend for Coolify at ${COOLIFY_HOST}:8080"
exec /bin/sh /soketi-entrypoint.sh
