#!/bin/bash
set -e

cron_script="/usr/bin/flock /tmp/certbot-renew.lock /scripts/certbot-renew.sh"

# append command line options to renewal script if available
if [[ $# > 0 ]]; then
    cron_exp="$CRON $cron_script $@"
else
    cron_exp="$CRON $cron_script"
fi

# add renew crontab if not already exists 
crontab -l | grep -q "$cron_exp" && ec=$? || ec=$?
if [ $ec == 0 ]; then
    echo "crontab $cron_exp already exists"
else
    echo "$cron_exp" >> /etc/crontabs/root
fi