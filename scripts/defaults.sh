#!/bin/bash

# Keep runtime defaults available when any script is invoked directly or by the
# image entrypoint. The '-' form preserves an explicitly supplied empty value.
export AUTHENTICATOR="${AUTHENTICATOR-standalone}"
export CRON="${CRON-0 0,12 * * *}"
export MULTI_CERTIFICATES_INI_FILE="${MULTI_CERTIFICATES_INI_FILE-/etc/certbot/multi-certificates.ini}"
