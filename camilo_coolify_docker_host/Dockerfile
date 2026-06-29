FROM docker:29-dind-rootless

USER root

ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.source="https://github.com/camiloconcha/homeassistant-addons" \
  org.opencontainers.image.title="Camilo Coolify Docker Host"

ENV DOCKER_TLS_CERTDIR=""

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    docker-cli-compose \
    jq \
    openssh-server \
    shadow \
    su-exec \
    sudo \
  && mkdir -p /run/sshd /data

COPY run.sh /usr/local/bin/run-addon.sh
RUN chmod +x /usr/local/bin/run-addon.sh

ENTRYPOINT ["/usr/local/bin/run-addon.sh"]
