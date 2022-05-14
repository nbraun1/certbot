#!/bin/bash
set -e

# add manage certificates options
if [ ! -z "$QUIET" ]; then
    certbot_params+=(-q)
fi

# add renew options
if [ ! -z "$PRE_HOOK_CMD" ]; then
    certbot_params+=(--pre-hook "$PRE_HOOK_CMD")
fi

if [ ! -z "$POST_HOOK_CMD" ]; then
    certbot_params+=(--post-hook "$POST_HOOK_CMD")
fi

if [ ! -z "$DEPLOY_HOOK_CMD" ]; then
    certbot_params+=(--deploy-hook "$DEPLOY_HOOK_CMD")
fi

# add custom options
if [ ! -z "$CERTBOT_RENEW_FLAGS" ]; then
    certbot_params+=($CERTBOT_RENEW_FLAGS)
fi

certbot renew "${certbot_params[@]}" &>>/var/log/letsencrypt/renewal.log