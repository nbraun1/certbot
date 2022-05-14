#!/bin/bash
set -e

cron_script="/scripts/certbot-renew.sh"
crontab -l | grep -q "$CRON $cron_script" && ec=$? || ec=$?
# check if crontab already exists
if [ $ec == 0 ]; then
    echo "crontab $CRON $cron_script already exists"
else
    echo "$CRON $cron_script" | crontab -
fi