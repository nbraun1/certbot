#!/bin/bash
set -e
set -o pipefail

source "$(dirname "$0")/defaults.sh"

stop_scheduler_on_failure() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        # A logging error must not prevent shutdown or replace the exit status.
        set +e
        printf '%s\n' "$exit_code" > "$CERTBOT_CROND_FAILURE_FILE"
        printf 'Renewal failed for %s (exit %s); stopping the scheduler\n' \
            "${CERT_NAME:-all certificates}" "$exit_code" >&2
        kill -TERM "$CERTBOT_CROND_PID"
    fi
    exit "$exit_code"
}

if [[ "${CERTBOT_CROND_PID-}" =~ ^[0-9]+$ ]] &&
    [ "$CERTBOT_CROND_PID" -gt 1 ] &&
    [ -n "${CERTBOT_CROND_FAILURE_FILE-}" ]; then
    # Cron invokes this script under flock, including this check and the trap.
    if [ -f "$CERTBOT_CROND_FAILURE_FILE" ]; then
        echo "Skipping renewal after an earlier failure" >&2
        exit 1
    fi
    trap stop_scheduler_on_failure EXIT
fi

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

mkdir -p /var/log/letsencrypt
certbot renew "${certbot_params[@]}" 2>&1 | tee -a /var/log/letsencrypt/renewal.log
