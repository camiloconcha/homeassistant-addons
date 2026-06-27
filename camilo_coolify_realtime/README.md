# Camilo Coolify Realtime

Realtime and terminal websocket backend for `camilo_coolify`.

Use the same `pusher_app_id`, `pusher_app_key`, and `pusher_app_secret` as the `camilo_coolify` add-on.

The add-on patches Coolify's realtime container so terminal auth calls use the Home Assistant internal Coolify hostname instead of the upstream Docker Compose service name `coolify`.
