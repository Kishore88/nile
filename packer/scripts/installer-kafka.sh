#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


# Kafka version
KAFKA_VERSION="2.4.1"
SCALA_VERSION="2.12"
RESOURCES_FOLDER="/tmp/packer/resources"

# Download Kafka
KAFKA_FILENAME="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
url="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_FILENAME}"

if [[ ! $(curl -s -f -I "${url}") ]]; then
    echo "Mirror does not have desired version, downloading direct from Apache"
    url="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_FILENAME}"
fi

curl -L ${url} -o /tmp/${KAFKA_FILENAME}
curl -L ${url}.asc -o /tmp/${KAFKA_FILENAME}.asc
curl -L https://www.apache.org/dist/kafka/KEYS -o /tmp/KEYS

# Validate download
gpg --import /tmp/KEYS
gpg --verify /tmp/${KAFKA_FILENAME}.asc /tmp/${KAFKA_FILENAME}

# Unpack kafka
KAFKA_FOLDER="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"

tar -xf /tmp/${KAFKA_FILENAME} -C /opt
ln -s ${KAFKA_FOLDER} /opt/kafka

# Creating kafka user
useradd -m -d /var/run/kafka -r -s /bin/bash kafka

# Add required folders
mkdir -p /var/lib/kafka /etc/kafka /opt/kafka/logs
chown -R kafka:kafka /var/lib/kafka /opt/kafka/logs
chmod -R 750 /var/lib/kafka /opt/kafka/logs

# Adding Systemd services
mv ${RESOURCES_FOLDER}/kafka.service /etc/systemd/system/
chown root:root /etc/systemd/system/kafka.service
chmod 644 /etc/systemd/system/kafka.service

# copying Kafka environment and config
RES=/tmp/packer/resources/
cp $RES/environment_kakfa.tmpl /etc/environment_kafka.tmpl
cp $RES/kafka.properties.tmpl /etc/kafka/
cp $RES/kafka.jaas.tmpl /etc/kafka/
cp $RES/kafka-log4j.properties /opt/kafka/config/log4j.properties

# disable syslog for kafka, the logs are already in /opt/kafka/logs
echo ':programname, contains, "kafka-server-start.sh" stop' > /etc/rsyslog.d/99-kafka-no-syslog.conf

exit 0
