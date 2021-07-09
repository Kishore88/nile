#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1


VER=7.2.0
url="https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-oss-${VER}-amd64.deb"
curl -sfLC - --retry 3 --retry-delay 3 ${url} -o /tmp/filebeat.deb
dpkg -i /tmp/filebeat.deb

# copying filebeat configuration
RES=/tmp/packer/resources/
cp $RES/filebeat.yml.tmpl /etc/filebeat/

exit 0
