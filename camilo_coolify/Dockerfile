FROM ghcr.io/coollabsio/coolify:latest

ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.source="https://github.com/camiloconcha/homeassistant-addons" \
  org.opencontainers.image.title="Camilo Coolify"

USER root
RUN apk add --no-cache jq su-exec \
  && sed -i "s/if (! isCloud() && config('constants.coolify.is_windows_docker_desktop') == false) {/if (! isCloud() \&\& env('COOLIFY_HA_ENABLE_LOCALHOST', false) \&\& config('constants.coolify.is_windows_docker_desktop') == false) {/" /var/www/html/database/seeders/ProductionSeeder.php \
  && sed -i "s/if (! isCloud()) {/if (! isCloud() \&\& env('COOLIFY_HA_ENABLE_LOCALHOST', false)) {/" /var/www/html/database/seeders/ProductionSeeder.php

COPY run.sh /usr/local/bin/run-addon.sh
RUN chmod +x /usr/local/bin/run-addon.sh

ENTRYPOINT ["/usr/local/bin/run-addon.sh"]
