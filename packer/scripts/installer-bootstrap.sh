#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


#
# This script prepares the node bootstrap sequence. When the node starts up
# a user-data script will trigger the `/bootstrap/bootstrap.sh` script.
#
