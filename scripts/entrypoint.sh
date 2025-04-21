#!/bin/bash
set -e

# source local Python virtual environment
source /opt/venv/bin/activate

# install each dns plugin which is defined in the DNS_PLUGINS
# environment variable if not already installed
./scripts/install-dns-plugins.sh

if [ -z "$ENABLE_MULTI_CERTIFICATES" ]; then
    # run certbot's certonly command to obtain certificates if not already exists
    ./scripts/certbot-certonly.sh

    if [ -z "$RUN_ONCE" ]; then
        # add crontab which is defined in the CRON 
        # environment variable if not already exists
        ./scripts/configure-crontab.sh

        # execute the crontab which we have configured previously
        # to ensure that the obtained certificates will be renewed
        exec crond -f -L /var/log/letsencrypt/cron.log
    fi
else
    # parse the INI file defined in the MULTI_CERTIFICATES_INI_FILE environment variable
    # and obtain a certificate for each configured domain. if the RUN_ONCE
    # environment variable is undefined, run configure-crontab.sh for each configured
    # domain, too. after configuring the crontabs, crond is started
    exec ./scripts/manage-multi-certificates.py
fi