#!/bin/bash
set -e

# install each dns plugin which is defined in the DNS_PLUGINS
# environment variable if not already installed
./scripts/install-dns-plugins.sh

# run certbot's certonly command to issue certificates if not already exists
./scripts/certbot-certonly.sh

if [ -z "$RUN_ONCE" ]; then
    # add crontab which is defined in the CRON 
    # environment variable if not already exists
    ./scripts/configure-crontab.sh

    # execute the cron which we have configured previously
    # to ensure that the issued certificates will be renewed
    exec crond -f -L /var/log/letsencrypt/cron.log
fi