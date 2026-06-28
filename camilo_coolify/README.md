# Camilo Coolify

Coolify packaged as Home Assistant add-ons.

Install and start these add-ons first:

1. `camilo_coolify_postgres`
2. `camilo_coolify_redis`
3. `camilo_coolify_realtime`
4. Optional: `camilo_coolify_docker_host`
5. `camilo_coolify`

Generate matching secrets and paste them into the matching add-on options:

```sh
openssl rand -hex 16
openssl rand -base64 32
openssl rand -hex 32
```

Use `base64:<openssl rand -base64 32>` for `app_key`.

This add-on intentionally disables Coolify's automatic `localhost` server bootstrap. Home Assistant OS should not be used as a Docker host controlled by Coolify because that can make Supervisor report the installation as unsupported. Add your VPS or another Docker server inside Coolify over SSH instead.

If you want a self-contained setup without an external VPS, install `camilo_coolify_docker_host` and add it in Coolify as a remote SSH server. Do not select `This machine`; use the internal Docker Host add-on hostname printed in its logs.

For local access, keep port `8000` enabled and open `http://homeassistant.local:8000`. Realtime uses ports `6001` and `6002`.

For Cloudflare Tunnel or another reverse proxy, route:

- `/` to `camilo_coolify` port `8080`
- `/app` to `camilo_coolify_realtime` port `6001`
- `/terminal/ws` to `camilo_coolify_realtime` port `6002`

If your proxy cannot route by path, use separate hostnames and set `pusher_host`, `terminal_host`, `terminal_protocol`, and `terminal_port` in the Coolify add-on options.

When using separate subdomains for realtime or terminal websockets, set `session_domain` to the parent domain with a leading dot, for example `.kmilo.cl`. The terminal backend authenticates websocket upgrades with the browser's Coolify session cookies, so the cookies must be valid across `coolify.kmilo.cl` and `coolify-terminal.kmilo.cl`.
