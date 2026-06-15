# Camilo Ghostfolio

Ghostfolio wealth management web app packaged as a Home Assistant add-on.

## Required add-ons

Start these first:

1. `Camilo Ghostfolio PostgreSQL`
2. `Camilo Ghostfolio Valkey`
3. `Camilo Ghostfolio`

## Configuration

By default, `postgres_host` and `redis_host` are set to `auto`. The add-on
derives the repository prefix from its own Home Assistant hostname and connects
to:

```text
<repo-prefix>-camilo-ghostfolio-postgres
<repo-prefix>-camilo-ghostfolio-valkey
```

For this repository on the NUC, the current prefix is `1333c794`, so the
resolved hostnames are:

```text
1333c794-camilo-ghostfolio-postgres
1333c794-camilo-ghostfolio-valkey
```

If auto-detection ever fails, set those two host options manually.

Set the same `postgres_password` and `redis_password` values in the backend
add-ons and in this add-on. Generate strong values for `access_token_salt` and
`jwt_secret_key`.

## Cloudflare Tunnel

When publishing through the Cloudflared add-on, point the hostname to the
internal add-on DNS name, not to `127.0.0.1`:

```text
patrimonio.kmilo.cl -> http://1333c794-camilo-ghostfolio:3333
```

To confirm the exact hostname on another install, open the Ghostfolio add-on
info in Supervisor or check its logs; the hostname format is:

```text
<repo-prefix>-camilo-ghostfolio
```

Leave the optional port mapping disabled unless you need LAN access.
