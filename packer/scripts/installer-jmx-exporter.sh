#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1

export PACKAGE=$1
[ "${PACKAGE}" = "" ] && echo "ERROR: Missing package name: kafka or zookeeper." && exit 1

# jmx_exporter version
JMX_EXPORTER_VERSION="0.12.0"
RESOURCES_FOLDER="/tmp/packer/resources"
INSTALL_DIR="/opt/jmx_exporter"

mkdir -p ${INSTALL_DIR}

download_url="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/${JMX_EXPORTER_VERSION}/jmx_prometheus_httpserver-${JMX_EXPORTER_VERSION}-jar-with-dependencies.jar"
local_file="${INSTALL_DIR}/jmx_exporter.jar"

# install jmx_exporter
curl -XGET ${download_url} -o ${local_file}

# set jmx_exporter config
mv ${RESOURCES_FOLDER}/jmx_exporter_${PACKAGE}.yml /etc/jmx_exporter.yml

# create jmx_exporter user
useradd -m -d /var/run/jmx_exporter -r -s /bin/bash jmx_exporter

# Adding Systemd services
mv ${RESOURCES_FOLDER}/jmx_exporter.service /etc/systemd/system/
chown root:root /etc/systemd/system/jmx_exporter.service
chmod 644 /etc/systemd/system/jmx_exporter.service

systemctl enable jmx_exporter

exit 0
