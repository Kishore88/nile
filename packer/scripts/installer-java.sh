#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1

JDK_MAJOR="13"
JDK_VERSION="13.0.2"
JDK_BUILD="8"

#
# Install OpenJDK (doesn't have new GC)
#
#jdk_url="https://download.java.net/java/GA/jdk${JDK_VERSION}/${JDK_HASH}/${JDK_BUILD}/GPL/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz"
#sha_url="${jdk_url}.sha256"

#
# Install AdoptOpenJDK
#
jdk_url="https://github.com/AdoptOpenJDK/openjdk${JDK_MAJOR}-binaries/releases/download/jdk-${JDK_VERSION}%2B${JDK_BUILD}/OpenJDK${JDK_MAJOR}U-jdk_x64_linux_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
sha_url="${jdk_url}.sha256.txt"

curl -fLC - --retry 3 --retry-delay 3 ${jdk_url} -o /tmp/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz
curl -sfLC - --retry 3 --retry-delay 3 ${sha_url} -o /tmp/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz.sha256

# verify checksum
actual=$(sha256sum /tmp/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz | cut -d' ' -f1)
expected=$(cat /tmp/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz.sha256 | cut -d' ' -f1)

if [ "$actual" != "$expected" ] ; then
    echo "ERROR: JDK-${JDK_VERSION} checksum verification failed."
    exit 1
fi

mkdir -p /usr/lib/jvm/
tar -zxvf /tmp/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz -C /usr/lib/jvm/
ln -s /usr/lib/jvm/jdk-${JDK_MAJOR}* /usr/lib/jvm/master-java

cat > /etc/profile.d/jdk.sh <<\EOF
#!/bin/sh
export JAVA_HOME=/usr/lib/jvm/master-java
export PATH=$JAVA_HOME/bin:$PATH
EOF

chmod +x /etc/profile.d/jdk.sh

cat >> /etc/environment <<\EOF
JAVA_HOME=/usr/lib/jvm/master-java
EOF

exit 0
