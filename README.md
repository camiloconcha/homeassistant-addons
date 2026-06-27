# homeassistant-addons

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @jdeath/homeassistant-addons](https://git-lister.onrender.com/api/stars/camiloconcha/homeassistant-addons?limit=30)](https://github.com/camiloconcha/homeassistant-addons/stargazers)

## About

Home Assistant allows anyone to create add-on repositories to share their
add-ons for Home Assistant easily. This repository is one of those repositories,
providing extra Home Assistant add-ons for your installation.

The primary goal of this project is to provide you (as a Home Assistant user)
with additional, high quality, add-ons that allow you to take your automated
home to the next level.

## Installation

[![Add repository on my Home Assistant][repository-badge]][repository-url]

If you want to do add the repository manually, please follow the procedure highlighted in the [Home Assistant website](https://home-assistant.io/hassio/installing_third_party_addons). Use the following URL to add this repository: https://github.com/camiloconcha/homeassistant-addons

## Add-ons

- `camilo_coolify_postgres`: PostgreSQL backend for Coolify.
- `camilo_coolify_redis`: Redis backend for Coolify.
- `camilo_coolify_realtime`: Coolify realtime and terminal websocket backend.
- `camilo_coolify`: Coolify dashboard for managing remote Docker servers over SSH.
- `camilo_ghostfolio_postgres`: PostgreSQL backend for Ghostfolio.
- `camilo_ghostfolio_valkey`: Valkey/Redis-compatible cache for Ghostfolio.
- `camilo_ghostfolio`: Ghostfolio wealth management web app.

For Coolify, install and start PostgreSQL, Redis, and Realtime first, then
configure and start Coolify. This package intentionally disables Coolify's
automatic localhost Docker bootstrap so Home Assistant OS does not become an
unsupported Docker host. Add remote Docker servers from the Coolify UI instead.

For Ghostfolio, install and start PostgreSQL and Valkey first, then configure and
start Ghostfolio. Keep credentials in the Home Assistant add-on options; do not
commit secrets to this repository.

[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fcamiloconcha%2Fhomeassistant-addons
