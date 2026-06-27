FROM ghcr.io/coollabsio/coolify-realtime:1.0.16

ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.source="https://github.com/camiloconcha/homeassistant-addons" \
  org.opencontainers.image.title="Camilo Coolify Realtime"

USER root
RUN apk add --no-cache jq \
  && sed -i "s/hostname: 'coolify'/hostname: process.env.COOLIFY_HOST || 'coolify'/" /terminal/terminal-server.js

COPY run.sh /usr/local/bin/run-addon.sh
RUN chmod +x /usr/local/bin/run-addon.sh

ENTRYPOINT ["/usr/local/bin/run-addon.sh"]
