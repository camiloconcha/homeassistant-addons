# Changelog

## 0.1.5

- Allow the Coolify settings page to load when the upstream localhost server record is intentionally disabled on Home Assistant OS.

## 0.1.4

- Add `session_domain` so Coolify can share auth cookies with separate realtime and terminal subdomains behind Cloudflare Tunnel.

## 0.1.3

- Write PHP-FPM errors to Coolify storage logs instead of `/proc/self/fd/2` to avoid Home Assistant/Supervisor pipe permission issues.

## 0.1.2

- Run the upstream Coolify s6 process as root so PHP-FPM can open container stderr correctly.
- Verify Redis authentication before starting migrations and workers.

## 0.1.1

- Start Coolify through the upstream Serversideup entrypoint and disable Docker init wrapping so `s6-overlay` can run as PID 1.

## 0.1.0

- Initial Coolify add-on wrapper.
- Adds Home Assistant-safe startup that skips Coolify's localhost Docker bootstrap.
- Supports PostgreSQL, Redis, and realtime add-ons through auto-detected internal hostnames.
