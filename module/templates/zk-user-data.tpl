#!/bin/bash -x

export AWS_DEFAULT_REGION='${AWS_REGION}'
export AWS_REGION='${AWS_REGION}'
export DEPLOY_UUID='${DEPLOY_UUID}'
export MYID='${MYID}'
export NIC_IP='${NIC_IP}'
export SERVICE_NAME='${SERVICE_NAME}'
export TAG_KEY='${TAG_KEY}'
export ZOOKEEPER_IPS='${ZOOKEEPER_IPS}'
export ELS_HOSTNAME='${ELS_HOSTNAME}'

#
# ENTER HERE YOUR CUSTOM CONFIGURATION OPTIONS FOR ZOOKEEPER
# PREFIX: ZKCFG_
#


# Bootstrap node
# check output in /var/log/cloud-init-output.log
/bootstrap/bootstrap.sh || shutdown -h now
