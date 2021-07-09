#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1

DEB_FILE=/tmp/amazon-ssm-agent.deb
DEPLOYMENT_REGION=eu-west-1

curl -XGET -O amazon-ssm-agent.db "https://s3.${DEPLOYMENT_REGION}.amazonaws.com/amazon-ssm-${DEPLOYMENT_REGION}/latest/debian_amd64/amazon-ssm-agent.deb" -o $DEB_FILE

sudo apt install $DEB_FILE
rm $DEB_FILE
