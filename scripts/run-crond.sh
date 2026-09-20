#!/bin/bash
set -e

source "$(dirname "$0")/defaults.sh"

# exec preserves this PID so renewal jobs can stop this scheduler on failure.
export CERTBOT_CROND_PID="$$"
export CERTBOT_CROND_FAILURE_FILE=/tmp/certbot-renew.failed
rm -f "$CERTBOT_CROND_FAILURE_FILE"

exec crond -f -L /dev/stderr
