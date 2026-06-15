# Camilo Ghostfolio PostgreSQL

PostgreSQL backend for the Ghostfolio add-on.

## Configuration

- `postgres_db`: database name. Default: `ghostfolio`.
- `postgres_user`: database user. Default: `ghostfolio`.
- `postgres_password`: required secure password.

The database is stored in this add-on's persistent `/data/postgresql` directory
and is included in Home Assistant backups. No port is exposed to the host.

Start this add-on before starting `Camilo Ghostfolio`.
