#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


export PACKAGE=$1
[ "${PACKAGE}" = "" ] && echo "ERROR: Missing package name: kafka or zookeeper." && exit 1

# Install required dependencies
apt-get update && apt-get install --no-install-recommends -y jq python3-pip xfsprogs

# Defining new rt_table
echo -ne "2\t${PACKAGE}\n" >> /etc/iproute2/rt_tables
echo -ne "3\ttraffic" >> /etc/iproute2/rt_tables

# Install Python resources
# aws cli : https://github.com/boto/boto3/issues/2596#issuecomment-698347488
pip3 install botocore==1.17.63
pip3 install awscli==1.18.140
pip3 install boto3==1.14.63
pip3 install requests

#
# This script prepares the node bootstrap sequence. When the node starts up
# a user-data script will trigger the `/bootstrap/bootstrap.sh` script.
#
RES=/tmp/packer/resources/
mkdir /bootstrap
cp $RES/bootstrap.sh $RES/bootstrap_node.py /bootstrap/
chmod +x /bootstrap/bootstrap.sh

exit 0
