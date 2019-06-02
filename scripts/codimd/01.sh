#!/bin/sh

# Include template function

. "${provisioning_base_dir}/lib/template.sh"

# Install node.js 8 repo

cd /root
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

# Install stuff

apt-get -y install nodejs=6.14.1-1nodesource1
apt-get -y install postgresql postgresql-contrib make g++ build-essential

# Download CodiMD and run setup script
# Steps mostly from https://github.com/hackmdio/codimd#installation

curl -o codimd-1.2.1.tar.gz https://codeload.github.com/hackmdio/codimd/tar.gz/1.2.1
tar xzf codimd-1.2.1.tar.gz
cd codimd-1.2.1
#npm install webpack@2
#npm install grunt
bin/setup

# Set up environment variables

export NODE_ENV="production"
export DEBUG="false"
export CMD_DOMAIN="codipoc.legends.im"
#
# Set up config.json
#
#template \
#    -f "config.json" \
#    -t "$(pwd)"
#    -r "asdf ${2}" \
