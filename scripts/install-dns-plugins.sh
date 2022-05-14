#!/bin/bash
set -e

IFS="," read -ra dns_plugins <<< "$DNS_PLUGINS"

for dns_plugin in "${dns_plugins[@]}"; do
    pip3 show "$dns_plugin" &>/dev/null && ec=$? || ec=$?
    # check if dns plugin already exists
    if [ $ec == 0 ]; then
        echo "$dns_plugin is already installed"
    else
        pip3 install "$dns_plugin" >/dev/null
    fi
done