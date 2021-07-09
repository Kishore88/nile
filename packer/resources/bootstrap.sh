#!/bin/bash -xe

#
# it feteches the instance's tags and converts them into environment variables
# for example, the "Name" tag will be available as $TAG_NAME
# a tag called "Foo-Bar21" will be availabe as $TAG_FOO_BAR21
#
function load-tags-as-env(){
    eval "$(aws --region $(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region) ec2 describe-tags --filters "Name=resource-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" | jq -r '.Tags | map({Key, Value}) | map(["\(.Key | ascii_upcase | gsub( "[^A-Z0-9]"; "_" ))", "\(.Value)"]) | map( "export TAG_\(.[0])='\''\(.[1])'\''")[]')"
}

#
# check output in /var/log/cloud-init-output.log
#

export MAX_MEM=$(grep 'MemTotal:' /proc/meminfo | awk '{mem=int($2 * 0.60 / 1000) ; if(mem<1024){mem=1024} ; print mem }')
# loads instance tags into environment
load-tags-as-env

env > $(dirname $0)/env-dump.$(date +%s)

#
# Bootstrap the node, attach EBS volumes and ENI network interfaces
#
python3 $(dirname $0)/bootstrap_node.py

#
# Prepare configuration files
#
synapse \
    /etc/environment_${SERVICE_NAME}.tmpl \
    /etc/${SERVICE_NAME}/${SERVICE_NAME}.properties.tmpl \
    /etc/filebeat/filebeat.yml.tmpl


# adding the list of peers
if [ "${SERVICE_NAME}" = "zookeeper" -a -e "/etc/zookeeper/zookeeper.properties" ] ; then
    echo $ZOOKEEPER_IPS | sed 's/:2181//g;s/,/\n/g' | awk '{ print "server."++i"="$1":2888:3888" }' >> /etc/zookeeper/zookeeper.properties
fi


if [ "${SERVICE_NAME}" = "zookeeper" -a ! -e "/var/lib/zookeeper/myid" ] ; then
    echo "$MYID" > /var/lib/zookeeper/myid
fi

if [ "${SERVICE_NAME}" = "kafka" -a ! -e "/opt/kafka/ssl/kafka.server.keystore.jks" ] ; then
    /opt/kafka/bin/generate_keystore.sh
fi

if [ "${SERVICE_NAME}" = "kafka" ] ; then
    synapse /etc/kafka/kafka.jaas.tmpl
fi

#
# Start services
#
[ "$ELS_HOSTNAME" != "" ] && service filebeat restart
systemctl enable --now ${SERVICE_NAME}.service
