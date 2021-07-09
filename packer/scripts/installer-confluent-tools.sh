#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


# Kafka version
CP_VERSION="5.3"
CP_PATCH=".1"
SCALA_VERSION="2.12"


# Download Confluent Community
url="http://packages.confluent.io/archive/${CP_VERSION}/confluent-community-${CP_VERSION}${CP_PATCH}-${SCALA_VERSION}.tar.gz"
curl -fLC - --retry 3 --retry-delay 3 ${url} -o /tmp/confluent.tar.gz

tar -zxvf /tmp/confluent.tar.gz -C /opt/
ln -s /opt/confluent-* /opt/confluent

cat > /etc/profile.d/confluent.sh <<\EOF
#!/bin/sh
export CONFLUENT_HOME=/opt/confluent
export PATH=$CONFLUENT_HOME/bin:$PATH
EOF

chmod +x /etc/profile.d/confluent.sh

exit 0
