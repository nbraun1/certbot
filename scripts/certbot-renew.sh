#!/bin/bash
set -e

while [[ $# > 0 ]]; do
    case "$1" in
        --cert-name)
            CERT_NAME="$2"
            shift # past argument
            shift # past value
            ;;
        
        -q|--quiet)
            QUIET=1
            shift # past argument
            ;;
        
        --pre-hook)
            PRE_HOOK_CMD="$2"
            shift # past argument
            shift # past value
            ;;
        
        --post-hook)
            POST_HOOK_CMD="$2"
            shift # past argument
            shift # past value
            ;;

        --deploy-hook)
            DEPLOY_HOOK_CMD="$2"
            shift # past argument
            shift # past value
            ;;

        --certbot-renew-flags)
            CERTBOT_RENEW_FLAGS=$2
            shift # past argument
            shift # past value
            ;;

        *)
            >&2 echo "Unknown command line option: $1"
            exit 1
    esac
done

# add manage certificates options
# only required if we should renew multiple certificates in an individual way
if [ ! -z "$CERT_NAME" ] && [ ! -z "$ENABLE_MULTI_CERTIFICATES" ]; then
    certbot_params+=(--cert-name "$CERT_NAME")
fi

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