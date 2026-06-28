# Changelog

## 0.1.3

- Prepare writable cgroup v2 nesting before starting `dockerd`, so Coolify helper/app containers can create their own cgroups.
- Fail early with a clear message when Home Assistant still exposes `/sys/fs/cgroup` as read-only to the add-on.

## 0.1.2

- Start `dockerd` directly through `docker-init`, skipping the upstream `dind` wrapper that writes to `/sys/fs/cgroup/init` and fails on Home Assistant OS read-only cgroups.

## 0.1.1

- Request explicit Docker-in-Docker capabilities and kernel module metadata.
- Add a startup preflight that tells the user to disable Home Assistant Protection mode when required privileges are missing.

## 0.1.0

- Initial experimental self-contained Docker host for Camilo Coolify.
- Runs nested Docker with persistent `/data/docker` storage.
- Runs SSH for Coolify remote-server onboarding.
- Supports user-provided authorized keys or generated client keys.
