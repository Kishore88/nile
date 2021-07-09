#!/bin/bash -xe
# check if it runs as root
[ "$(id -u)" != "0" ] && echo "ERROR: The script needs to be executed as root user.." && exit 1

# linuxbrew
apt-get update
apt-get install -y build-essential
su - ubuntu -c 'yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"'

cat > /etc/profile.d/brew.sh <<\EOF
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew";
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar";
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew";
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH";
export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH";
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH";
EOF

chmod +x /etc/profile.d/brew.sh
su - ubuntu -c 'yes | brew update'

# install kafkacat
su - ubuntu -c 'brew install kafkacat'


# planck install
add-apt-repository -y ppa:mfikes/planck
apt-get update
apt-get install -y  planck


exit 0
