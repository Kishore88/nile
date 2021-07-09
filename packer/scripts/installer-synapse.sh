#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


#
# Synapse generated configuration files from a template merging
# environment variable
#

SYNAPSE_VERSION=0.5.0

syn_url="https://github.com/BrunoBonacci/synapse/releases/download/${SYNAPSE_VERSION}/synapse-Linux-x86_64"
curl -sfLC - --retry 3 --retry-delay 3 ${syn_url} -o /usr/local/bin/synapse
chmod +x /usr/local/bin/synapse
