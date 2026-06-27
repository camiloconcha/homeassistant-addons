# Changelog

## 0.1.1

- Start Coolify through the upstream Serversideup entrypoint and disable Docker init wrapping so `s6-overlay` can run as PID 1.

## 0.1.0

- Initial Coolify add-on wrapper.
- Adds Home Assistant-safe startup that skips Coolify's localhost Docker bootstrap.
- Supports PostgreSQL, Redis, and realtime add-ons through auto-detected internal hostnames.
