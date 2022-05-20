FROM alpine:3.15.4
LABEL maintainer="Nico Braun <nico.braun.dev@gmx.de>"

# account options
ENV EMAIL=

# manage certificates options
ENV CERT_NAME=
ENV DOMAINS=
ENV PREFERRED_CHALLENGES=
ENV ISSUANCE_TIMEOUT=
ENV MAX_LOG_BACKUPS=
ENV FORCE_RENEWAL=
ENV QUIET=

# authenticator options
ENV AUTHENTICATOR=standalone

# standalone authenticator options
ENV HTTP01_ADDRESS=
ENV HTTP01_PORT=

# webroot authenticator options
ENV WEBROOT_PATH=

# dns authenticator options
ENV DNS_AUTHENTICATOR_CREDENTIALS=
ENV DNS_PROPAGATION_SECONDS=
ENV DNS_PLUGIN_FLAGS=

# test and debug options
ENV STAGING=
ENV VERBOSE=
ENV DEBUG=

# security options
ENV RSA_KEY_SIZE=
ENV KEY_TYPE=
ENV ELLIPTIC_CURVE=

# path options
ENV SERVER=

# renew options
ENV PRE_HOOK_CMD=
ENV POST_HOOK_CMD=
ENV DEPLOY_HOOK_CMD=

# custom options
ENV CERTBOT_CERTONLY_FLAGS=
ENV CERTBOT_RENEW_FLAGS=
ENV DNS_PLUGINS=
ENV RUN_ONCE=
ENV CRON="0 0,12 * * *"
ENV ENABLE_MULTI_CERTIFICATES=
ENV MULTI_CERTIFICATES_INI_FILE=/etc/certbot/multi-certificates.ini

RUN set -ex; \
    apk add --no-cache \
    bash \
    tini \
    docker-cli \
    python3 \
    py3-pip \
    certbot

# copy each certbot relevant script including the entrypoint.sh
# and ensure that each of them is executable
COPY scripts/ /scripts
RUN chmod +x -R /scripts

VOLUME [ "/etc/letsencrypt" ]

EXPOSE 80

ENTRYPOINT [ "/sbin/tini", "--", "/scripts/entrypoint.sh" ]