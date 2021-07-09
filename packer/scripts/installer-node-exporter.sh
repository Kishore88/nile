#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


# node_exporter version
NODE_EXPORTER_VERSION="0.18.1"
RESOURCES_FOLDER="/tmp/packer/resources"

download_url="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
local_file="/tmp/node_exporter-${NODE_EXPORTER_VERSION}.tar.gz"

# download node_exporter
curl -L -XGET ${download_url} -o ${local_file}

# untar
tar -C /tmp/ -xvf ${local_file}

# install
mv "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/bin/node_exporter

# create node_exporter user
useradd -m -d /var/run/node_exporter -r -s /bin/bash node_exporter

# Adding Systemd services
mv ${RESOURCES_FOLDER}/node_exporter.service /etc/systemd/system/
chown root:root /etc/systemd/system/node_exporter.service
chmod 644 /etc/systemd/system/node_exporter.service

systemctl enable node_exporter

exit 0
