#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


# Cleaning
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/*

exit 0
