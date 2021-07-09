#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1

RESOURCES_FOLDER="/tmp/packer/resources"

cp ${RESOURCES_FOLDER}/generate_keystore.sh /opt/kafka/bin/generate_keystore.sh

exit 0
