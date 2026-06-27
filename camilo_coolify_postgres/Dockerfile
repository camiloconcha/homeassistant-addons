FROM docker.io/library/postgres:15-alpine

ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.source="https://github.com/camiloconcha/homeassistant-addons" \
  org.opencontainers.image.title="Camilo Coolify PostgreSQL"

RUN apk add --no-cache jq

COPY run.sh /usr/local/bin/run-addon.sh
RUN chmod +x /usr/local/bin/run-addon.sh

CMD ["/usr/local/bin/run-addon.sh"]
