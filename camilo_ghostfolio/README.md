# Camilo Ghostfolio

Ghostfolio wealth management web app packaged as a Home Assistant add-on.

## Required add-ons

Start these first:

1. `Camilo Ghostfolio PostgreSQL`
2. `Camilo Ghostfolio Valkey`
3. `Camilo Ghostfolio`

## Configuration

The default internal hostnames assume this repository is installed from:

```text
https://github.com/camiloconcha/homeassistant-addons
```

With that repository, Supervisor usually assigns the prefix `2effc9b9`, so the
default hostnames are:

```text
2effc9b9-camilo-ghostfolio-postgres
2effc9b9-camilo-ghostfolio-valkey
```

If you install these add-ons as local add-ons under `/addons`, use:

```text
local-camilo-ghostfolio-postgres
local-camilo-ghostfolio-valkey
```

Set the same `postgres_password` and `redis_password` values in the backend
add-ons and in this add-on. Generate strong values for `access_token_salt` and
`jwt_secret_key`.

## Cloudflare Tunnel

When publishing through the Cloudflared add-on, point the hostname to the
internal add-on DNS name, not to `127.0.0.1`:

```text
patrimonio.kmilo.cl -> http://2effc9b9-camilo-ghostfolio:3333
```

If installed locally, use:

```text
patrimonio.kmilo.cl -> http://local-camilo-ghostfolio:3333
```

Leave the optional port mapping disabled unless you need LAN access.
