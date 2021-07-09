#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


apt-get install -y jq htop iftop tmux lsof dnsutils

exit 0
