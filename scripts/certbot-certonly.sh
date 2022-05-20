#!/bin/bash
set -e

if [ -z "$EMAIL" ]; then
    >&2 echo "EMAIL environment variable is undefined"
    exit 1
fi

# add account options
certbot_params+=(-m "$EMAIL")

# add manage certificates options
if [ ! -z "$CERT_NAME" ]; then
    certbot_params+=(--cert-name "$CERT_NAME")
fi

if [ ! -z "$DOMAINS" ]; then
    certbot_params+=(-d "$DOMAINS")
fi

if [ ! -z "$ISSUANCE_TIMEOUT" ]; then
    certbot_params+=(--issuance-timeout "$ISSUANCE_TIMEOUT")
fi

if [ ! -z "$MAX_LOG_BACKUPS" ]; then
    certbot_params+=(--max-log-backups "$MAX_LOG_BACKUPS")
fi

if [ ! -z "$FORCE_RENEWAL" ]; then
    certbot_params+=(--force-renewal)
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
fi

if [ ! -z "$QUIET" ]; then
    certbot_params+=(-q)
fi

# check if an user defines the PREFERRED_CHALLENGES environment variable,
# if so we should not auto-detect and override this value
if [ ! -z "$PREFERRED_CHALLENGES" ]; then
    use_custom_preferred_challenges=1
fi

# add authenticator options
# add the --webroot-path option if the authenticator is "webroot"
if [ "$AUTHENTICATOR" == "webroot" ]; then
    # fail if the WEBROOT_PATH environment variable is undefined
    if [ -z "$WEBROOT_PATH" ]; then
        >&2 echo "authenticator is webroot but no WEBROOT_PATH is defined"
        exit 1
    fi
    certbot_params+=(--webroot --webroot-path "$WEBROOT_PATH")
    if [ -z $use_custom_preferred_challenges ]; then
        # webroot authenticator works only with the http challenge
        PREFERRED_CHALLENGES="http-01"
    fi
# add the --standalone option if the authenticator is "standalone"
elif [ "$AUTHENTICATOR" == "standalone" ]; then
    certbot_params+=(--standalone)
    if [ ! -z "$HTTP01_ADDRESS" ]; then
        certbot_params+=(--http-01-address "$HTTP01_ADDRESS")
    fi
    if [ ! -z "$HTTP01_PORT" ]; then
        certbot_params+=(--http-01-port "$HTTP01_PORT")
    fi
    if [ -z $use_custom_preferred_challenges ]; then
        # standalone authenticator works only with the http challenge
        PREFERRED_CHALLENGES="http-01"
    fi
# add the dns authenticator options
elif [[ "$AUTHENTICATOR" == *dns* ]]; then
    certbot_params+=(-a "$AUTHENTICATOR")
    if [ ! -z "$DNS_AUTHENTICATOR_CREDENTIALS" ]; then
        certbot_params+=(--"$AUTHENTICATOR"-credentials "$DNS_AUTHENTICATOR_CREDENTIALS")
    fi
    if [ ! -z "$DNS_PROPAGATION_SECONDS" ]; then
        certbot_params+=(--"$AUTHENTICATOR"-propagation-seconds "$DNS_PROPAGATION_SECONDS")
    fi
    if [ ! -z "$DNS_PLUGIN_FLAGS" ]; then
        certbot_params+=($DNS_PLUGIN_FLAGS)
    fi
    if [ -z $use_custom_preferred_challenges ]; then
        # dns authenticator works only with the dns challenge
        PREFERRED_CHALLENGES="dns-01"
    fi
fi

certbot_params+=(--preferred-challenges "$PREFERRED_CHALLENGES")

# add test and debug options
if [ ! -z "$STAGING" ]; then
    certbot_params+=(--staging) 
fi

if [ ! -z "$VERBOSE" ]; then
    certbot_params+=(-v) 
fi

if [ ! -z "$DEBUG" ]; then
    certbot_params+=(--debug)
fi

# add security options
if [ ! -z "$RSA_KEY_SIZE" ]; then
    certbot_params+=(--rsa-key-size "$RSA_KEY_SIZE")
fi

if [ ! -z "$KEY_TYPE" ]; then
    certbot_params+=(--key-type "$KEY_TYPE")
fi

if [ ! -z "$ELLIPTIC_CURVE" ]; then
    certbot_params+=(--elliptic-curve "$ELLIPTIC_CURVE")
fi

# add path options
if [ ! -z "$SERVER" ]; then
    certbot_params+=(--server "$SERVER")
fi

# add custom options
if [ ! -z "$CERTBOT_CERTONLY_FLAGS" ]; then
    certbot_params+=($CERTBOT_CERTONLY_FLAGS)
fi

certbot certonly -n --keep --agree-tos "${certbot_params[@]}"