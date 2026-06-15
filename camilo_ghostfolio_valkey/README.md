# Camilo Ghostfolio Valkey

Valkey, compatible with Redis, for the Ghostfolio add-on.

## Configuration

- `redis_password`: required secure password.

Data is stored in this add-on's persistent `/data/valkey` directory and included
in Home Assistant backups. No port is exposed to the host.

Start this add-on before starting `Camilo Ghostfolio`.
