# Camilo Coolify Docker Host

Experimental self-contained Docker host for `camilo_coolify`.

This add-on runs a nested Docker daemon and an SSH server inside its own Home Assistant add-on container. Coolify can add it as a remote server over SSH without touching the real Home Assistant OS Docker daemon.

## Important

This is Docker-in-Docker. It is more fragile and heavier than a normal remote Docker server. Use a VPS, VM, NUC, NAS, or Raspberry Pi with native Docker when possible.

This add-on requires `full_access`, extra Linux capabilities, host kernel module metadata, and disabled AppArmor because nested Docker needs privileged kernel features. It does not expose the Home Assistant OS Docker socket to Coolify.

After installing it in Home Assistant, turn **Protection mode** off for this add-on. If Protection mode is still on, Docker will fail with mount or iptables errors.

The default Docker storage driver is `vfs`. It is slower than `overlay2`, but it is the most compatible choice for nested Docker. You can try `overlay2` later if your Home Assistant host supports it cleanly.

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
