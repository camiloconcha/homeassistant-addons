FROM docker.io/ghostfolio/ghostfolio:3.11.0

ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.source="https://github.com/camiloconcha/homeassistant-addons" \
  org.opencontainers.image.title="Camilo Ghostfolio"

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends gosu \
  && rm -rf /var/lib/apt/lists/*
COPY run.sh /usr/local/bin/run-addon.sh
RUN chmod +x /usr/local/bin/run-addon.sh

CMD ["/usr/local/bin/run-addon.sh"]
