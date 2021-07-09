#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


# Kafka version
RESOURCES_FOLDER="/tmp/packer/resources"
SCRAM_STORE_VERSION="0.0.2"

# FIXME, download from github releases
curl -L -o /tmp/packer/resources/scram.jar "https://github.com/obohrer/kafka-dynamodb-store/releases/download/v${SCRAM_STORE_VERSION}/kafka-dynamodb-store-${SCRAM_STORE_VERSION}-standalone.jar"
cp $RESOURCES_FOLDER/scram.jar /opt/kafka/libs/scram.jar

exit 0
