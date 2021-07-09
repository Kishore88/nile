#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


# Zookeeper version
ZOOKEEPER_VERSION="3.5.5"
RESOURCES_FOLDER="/tmp/packer/resources"


# Download Zookeeper
ZOOKEEPER_FILENAME="apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz"
url="https://archive.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/${ZOOKEEPER_FILENAME}"

curl -L ${url} -o /tmp/${ZOOKEEPER_FILENAME}
curl -L ${url}.asc -o /tmp/${ZOOKEEPER_FILENAME}.asc
curl -L https://www.apache.org/dist/zookeeper/KEYS -o /tmp/KEYS

# Validate download
gpg --import /tmp/KEYS
gpg --verify /tmp/${ZOOKEEPER_FILENAME}.asc /tmp/${ZOOKEEPER_FILENAME}

# Unpack Zookeeper
ZOOKEEPER_FOLDER="apache-zookeeper-${ZOOKEEPER_VERSION}-bin"

tar -xf /tmp/${ZOOKEEPER_FILENAME} -C /opt
ln -s ${ZOOKEEPER_FOLDER} /opt/zookeeper

# Creating zookeeper user
useradd -m -d /var/run/zookeeper -r -s /bin/bash zookeeper

# Add required folders
# NOTE Not happy with this. It can be done better
#      /etc/zookeeper contains the /etc/zookeeper/zookeeper.properties which is loaded from s3
#      /var/lib/zookeeper is set and used in /etc/zookeeper/zookeeper.properties which loaded from s3
#      /var/log/zookeeper is used in zookeeper.service which is /etc/systemd/system/zookeeper.service
mkdir -p /var/lib/zookeeper /etc/zookeeper /var/log/zookeeper
chown -R zookeeper:zookeeper /var/lib/zookeeper /etc/zookeeper /var/log/zookeeper
chmod -R 755 /var/lib/zookeeper /var/log/zookeeper

# Adding Systemd services
mv ${RESOURCES_FOLDER}/zookeeper.service /etc/systemd/system/
chown root:root /etc/systemd/system/zookeeper.service
chmod 644 /etc/systemd/system/zookeeper.service

# copying Zookeeper environment and configuration
RES=/tmp/packer/resources/
cp $RES/environment_zookeeper.tmpl /etc/environment_zookeeper.tmpl
cp $RES/zookeeper.properties.tmpl /etc/zookeeper/

exit 0
