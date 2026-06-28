#!/bin/sh
set -eu

CONFIG=/data/options.json
DOCKER_DATA=/data/docker
SSH_DATA=/data/ssh
CLIENT_KEY="${SSH_DATA}/coolify_client_ed25519"
AUTHORIZED_TMP=/tmp/coolify_authorized_keys

get_option() {
  jq -r --arg key "$1" '.[$key] // ""' "$CONFIG"
}

option_true() {
  [ "$(get_option "$1")" = "true" ]
}

ensure_group() {
  group="$1"
  if ! getent group "$group" >/dev/null 2>&1; then
    addgroup -S "$group"
  fi
}

ensure_user() {
  if ! id -u coolify >/dev/null 2>&1; then
    adduser -D -h /home/coolify -s /bin/sh -G docker coolify
  fi
  addgroup coolify docker >/dev/null 2>&1 || true
}

prepare_users() {
  ensure_group docker
  ensure_user

  mkdir -p /home/coolify/.ssh /root/.ssh
  chmod 700 /home/coolify/.ssh /root/.ssh
  chown -R coolify:docker /home/coolify

  echo "coolify ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coolify
  chmod 440 /etc/sudoers.d/coolify
}

prepare_host_keys() {
  mkdir -p "$SSH_DATA"
  chmod 700 "$SSH_DATA"

  if [ ! -f "${SSH_DATA}/ssh_host_ed25519_key" ]; then
    ssh-keygen -q -t ed25519 -N "" -f "${SSH_DATA}/ssh_host_ed25519_key"
  fi

  if [ ! -f "${SSH_DATA}/ssh_host_rsa_key" ]; then
    ssh-keygen -q -t rsa -b 4096 -N "" -f "${SSH_DATA}/ssh_host_rsa_key"
  fi

  chmod 600 "${SSH_DATA}/ssh_host_"*_key
}

prepare_authorized_keys() {
  : > "$AUTHORIZED_TMP"

  configured_keys="$(get_option ssh_authorized_keys)"
  if [ -n "$configured_keys" ]; then
    printf '%s\n' "$configured_keys" >> "$AUTHORIZED_TMP"
  fi

  if option_true generate_client_key; then
    if [ ! -f "$CLIENT_KEY" ]; then
      ssh-keygen -q -t ed25519 -N "" -C "coolify-docker-host@homeassistant" -f "$CLIENT_KEY"
    fi
    cat "${CLIENT_KEY}.pub" >> "$AUTHORIZED_TMP"
  fi

  sed -i '/^[[:space:]]*$/d' "$AUTHORIZED_TMP"

  if [ ! -s "$AUTHORIZED_TMP" ] && [ -z "$(get_option ssh_password)" ]; then
    echo "[docker-host] No SSH key or password configured. Set ssh_authorized_keys or keep generate_client_key=true."
    exit 1
  fi

  for home in /root /home/coolify; do
    mkdir -p "${home}/.ssh"
    cp "$AUTHORIZED_TMP" "${home}/.ssh/authorized_keys"
    chmod 600 "${home}/.ssh/authorized_keys"
  done

  chown -R root:root /root/.ssh
  chown -R coolify:docker /home/coolify/.ssh
}

configure_password_auth() {
  password="$(get_option ssh_password)"
  if [ -n "$password" ]; then
    echo "coolify:${password}" | chpasswd
    if option_true allow_root_login; then
      echo "root:${password}" | chpasswd
    fi
  fi
}

write_sshd_config() {
  password_auth=no
  if [ -n "$(get_option ssh_password)" ]; then
    password_auth=yes
  fi

  root_login=no
  if option_true allow_root_login; then
    if [ "$password_auth" = "yes" ]; then
      root_login=yes
    else
      root_login=prohibit-password
    fi
  fi

  allow_users=coolify
  if option_true allow_root_login; then
    allow_users="root coolify"
  fi

  cat > /etc/ssh/sshd_config <<EOF
Port 22
ListenAddress 0.0.0.0
HostKey ${SSH_DATA}/ssh_host_ed25519_key
HostKey ${SSH_DATA}/ssh_host_rsa_key
PermitRootLogin ${root_login}
PasswordAuthentication ${password_auth}
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers ${allow_users}
PermitUserEnvironment no
AllowTcpForwarding yes
X11Forwarding no
PrintMotd no
Subsystem sftp internal-sftp
EOF

  sshd -t
}

require_nested_docker_privileges() {
  check_dir=/tmp/docker-host-privilege-check
  mkdir -p "$check_dir"

  if mount -t tmpfs tmpfs "$check_dir" >/dev/null 2>&1; then
    umount "$check_dir" >/dev/null 2>&1 || true
    rmdir "$check_dir" >/dev/null 2>&1 || true
    return
  fi

  rmdir "$check_dir" >/dev/null 2>&1 || true
  echo "[docker-host] Docker-in-Docker is missing required Linux privileges."
  echo "[docker-host] In Home Assistant, open this add-on and turn OFF Protection mode, then restart it."
  echo "[docker-host] This add-on also requires full_access, AppArmor disabled, SYS_ADMIN, NET_ADMIN, and kernel module access."
  echo "[docker-host] Without those permissions Docker cannot mount filesystems or configure networking."
  exit 1
}

can_write_cgroup_root() {
  test_dir=/sys/fs/cgroup/coolify-write-test
  if mkdir -p "$test_dir" >/dev/null 2>&1; then
    rmdir "$test_dir" >/dev/null 2>&1 || true
    return 0
  fi
  return 1
}

enable_cgroup_v2_nesting() {
  [ -f /sys/fs/cgroup/cgroup.controllers ] || return 0

  mkdir -p /sys/fs/cgroup/init
  attempts=0
  while [ "$attempts" -lt 20 ]; do
    if {
      xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || :
      sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control
    } >/dev/null 2>&1; then
      echo "[docker-host] cgroup v2 nesting enabled"
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 1
  done

  echo "[docker-host] Unable to enable cgroup v2 nesting"
  return 1
}

prepare_nested_cgroups() {
  if can_write_cgroup_root; then
    enable_cgroup_v2_nesting
    return
  fi

  echo "[docker-host] /sys/fs/cgroup is not writable; trying to remount it read-write"
  mount -o remount,rw /sys/fs/cgroup >/dev/null 2>&1 || true

  if can_write_cgroup_root; then
    enable_cgroup_v2_nesting
    return
  fi

  echo "[docker-host] Remount did not work; trying a private cgroup2 mount for Docker-in-Docker"
  mount -t cgroup2 cgroup2 /sys/fs/cgroup >/dev/null 2>&1 || true

  if can_write_cgroup_root; then
    enable_cgroup_v2_nesting
    return
  fi

  echo "[docker-host] Docker-in-Docker cannot create nested cgroups."
  echo "[docker-host] In Home Assistant, turn OFF Protection mode for this add-on and restart it."
  echo "[docker-host] If Protection mode is already off, Home Assistant OS is still exposing /sys/fs/cgroup read-only to this add-on."
  echo "[docker-host] Coolify deployments will fail with: mkdir /sys/fs/cgroup/docker: read-only file system."

  if option_true require_writable_cgroups; then
    exit 1
  fi

  echo "[docker-host] Continuing anyway because require_writable_cgroups=false."
  echo "[docker-host] This restores the previous best-effort behavior, but deployments may still fail if Docker cannot create container cgroups."
}

print_connection_details() {
  echo "[docker-host] Internal SSH host: ${HOSTNAME:-camilo-coolify-docker-host}"
  echo "[docker-host] SSH users: root$(option_true allow_root_login || printf ' disabled'), coolify"
  echo "[docker-host] Docker data root: ${DOCKER_DATA}"

  if option_true generate_client_key; then
    echo "[docker-host] Generated client public key:"
    cat "${CLIENT_KEY}.pub"
    if option_true print_client_private_key; then
      echo "[docker-host] BEGIN COOLIFY CLIENT PRIVATE KEY"
      cat "$CLIENT_KEY"
      echo "[docker-host] END COOLIFY CLIENT PRIVATE KEY"
      echo "[docker-host] Disable print_client_private_key after copying this key into Coolify."
    else
      echo "[docker-host] Set print_client_private_key=true and restart once if you need to copy the generated private key into Coolify."
    fi
  fi
}

start_dockerd() {
  mkdir -p "$DOCKER_DATA" /var/run
  rm -f /var/run/docker.pid

  docker_log_level="$(get_option docker_log_level)"
  docker_storage_driver="$(get_option docker_storage_driver)"
  docker_cgroupns_mode="$(get_option docker_cgroupns_mode)"
  docker_mtu="$(get_option docker_mtu)"

  prepare_nested_cgroups

  echo "[docker-host] Starting nested Docker daemon"
  docker-init -- dockerd \
    --host=unix:///var/run/docker.sock \
    --data-root="$DOCKER_DATA" \
    --storage-driver="$docker_storage_driver" \
    --default-cgroupns-mode="$docker_cgroupns_mode" \
    --log-level="$docker_log_level" \
    --mtu="$docker_mtu" &
  DOCKERD_PID=$!

  attempts=0
  while [ "$attempts" -lt 90 ]; do
    if ! kill -0 "$DOCKERD_PID" >/dev/null 2>&1; then
      echo "[docker-host] Docker daemon exited during startup"
      wait "$DOCKERD_PID" || true
      exit 1
    fi

    if docker version >/dev/null 2>&1; then
      chgrp docker /var/run/docker.sock || true
      chmod 660 /var/run/docker.sock || true
      docker info --format '[docker-host] Docker ready: {{.ServerVersion}}, storage={{.Driver}}, cgroup={{.CgroupDriver}}'
      return
    fi

    attempts=$((attempts + 1))
    sleep 1
  done

  echo "[docker-host] Docker daemon did not become ready"
  exit 1
}

start_sshd() {
  echo "[docker-host] Starting SSH server"
  /usr/sbin/sshd -D -e &
  SSHD_PID=$!
}

stop_services() {
  echo "[docker-host] Stopping services"
  kill "${SSHD_PID:-0}" "${DOCKERD_PID:-0}" >/dev/null 2>&1 || true
}

trap stop_services INT TERM

prepare_users
prepare_host_keys
prepare_authorized_keys
configure_password_auth
write_sshd_config
require_nested_docker_privileges
print_connection_details
start_dockerd
start_sshd

while :; do
  if ! kill -0 "$DOCKERD_PID" >/dev/null 2>&1; then
    echo "[docker-host] Docker daemon stopped"
    wait "$DOCKERD_PID" || true
    stop_services
    exit 1
  fi

  if ! kill -0 "$SSHD_PID" >/dev/null 2>&1; then
    echo "[docker-host] SSH server stopped"
    wait "$SSHD_PID" || true
    stop_services
    exit 1
  fi

  sleep 5
done
