# Camilo Coolify Docker Host

Experimental self-contained Docker host for `camilo_coolify`.

This add-on runs a nested Docker daemon and an SSH server inside its own Home Assistant add-on container. Coolify can add it as a remote server over SSH without touching the real Home Assistant OS Docker daemon.

## Important

This is Docker-in-Docker. It is more fragile and heavier than a normal remote Docker server. Use a VPS, VM, NUC, NAS, or Raspberry Pi with native Docker when possible.

This add-on defaults to rootless nested Docker. It does not expose the Home Assistant OS Docker socket to Coolify.

Rootless mode avoids depending on writable host cgroups, which Home Assistant OS can expose as read-only to add-ons. Rootful mode remains available through `docker_mode: rootful`, but it requires `full_access`, extra Linux capabilities, host kernel module metadata, disabled AppArmor, and writable nested cgroups.

After installing it in Home Assistant, turn **Protection mode** off for this add-on. If Protection mode is still on, Docker will fail with mount or iptables errors.

If Coolify deployments fail with:

```text
mkdir /sys/fs/cgroup/docker: read-only file system
```

update this add-on to `0.1.4`, keep **Protection mode** off, restart the add-on, then validate the server again in Coolify and redeploy. Version `0.1.4` tries to prepare writable nested cgroups, but restores best-effort startup by default if Home Assistant OS still blocks the cgroup mount.

If the same error persists, update to `0.1.5` and use the default:

```yaml
docker_mode: rootless
docker_storage_driver: auto
```

Rootless Docker should report `cgroup=none` in the add-on logs and can deploy containers without creating `/sys/fs/cgroup/docker`.

If you prefer the add-on to fail early instead of starting a possibly limited Docker daemon, set:

```yaml
require_writable_cgroups: true
```

The default Docker storage driver is `auto`. In rootless mode this lets Docker choose its rootless-compatible default. In rootful mode `auto` maps to `vfs`, which is slower than `overlay2` but more compatible for nested Docker.

## Start order

Start these add-ons first:

1. `camilo_coolify_postgres`
2. `camilo_coolify_redis`
3. `camilo_coolify_realtime`
4. `camilo_coolify_docker_host`
5. `camilo_coolify`

## SSH key setup

Recommended secure path:

```sh
ssh-keygen -t ed25519 -f ./coolify-ha-docker-host -N ""
```

Paste `coolify-ha-docker-host.pub` into this add-on option:

```yaml
ssh_authorized_keys: "ssh-ed25519 AAAA..."
generate_client_key: false
print_client_private_key: false
```

Then paste the private key `coolify-ha-docker-host` into Coolify when creating the server.

Convenience path:

```yaml
generate_client_key: true
print_client_private_key: true
```

Restart the add-on once, copy the private key from logs into Coolify, then set:

```yaml
print_client_private_key: false
```

## Add server in Coolify

Do not choose `This machine`.

Choose a remote/existing server over SSH and use the internal host printed in this add-on logs, usually:

```text
Host: 1333c794-camilo-coolify-docker-host
Port: 22
User: root
```

`coolify` is also available as a sudo-capable user:

```text
User: coolify
```

For this encapsulated host, `root` is only root inside the Docker Host add-on, not root on Home Assistant OS.

## Publishing apps

Apps deployed by Coolify run inside the nested Docker daemon. Coolify's proxy should bind to ports `80` and `443` inside this add-on.

For Cloudflare Tunnel, route app hostnames or wildcard domains to:

```text
http://1333c794-camilo-coolify-docker-host:80
```

If you need HTTPS passthrough to the nested proxy, route to:

```text
https://1333c794-camilo-coolify-docker-host:443
```

Use the actual hostname printed by the add-on logs if your repository prefix is different.

## Data

Nested Docker data is stored in:

```text
/data/docker
```

SSH host keys and generated client keys are stored in:

```text
/data/ssh
```

Home Assistant backups may become large if this add-on contains many images, volumes, and app data.
