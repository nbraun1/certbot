# syntax=docker/dockerfile:1

FROM alpine:3.24.1
LABEL maintainer="Nico Braun <49239121+nbraun1@users.noreply.github.com>"

WORKDIR /

RUN apk add --no-cache \
    bash \
    docker-cli \
    py3-pip \
    python3 \
    tini

RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip3 install --no-cache-dir \
        certbot

COPY --chmod=755 scripts/ /scripts

VOLUME ["/etc/letsencrypt"]

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--", "/scripts/entrypoint.sh"]
