#!/bin/sh

#
# Script to install Collabora on Ubuntu
#

# Allow HTTPS

ufw allow https

# Install Docker
# From https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/

apt-get -y install \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
apt-get -y update
apt-get -y install docker-ce
systemctl enable docker
systemctl restart docker

# Get a certificate

apt-get -y install certbot
certbot certonly --standalone -d "$2" --agree-tos --email "$3"

# Install Collabora
# Mostly from https://nextcloud.com/collaboraonline/

escaped_hostname=$(echo "$2" | sed 's/\./\\\\\./g')
docker pull collabora/code
docker run -t -d -p 127.0.0.1:9980:9980 -e "domain=${escaped_hostname}" --restart always --cap-add MKNOD collabora/code
apt-get install apache2
a2enmod proxy
a2enmod proxy_wstunnel
a2enmod proxy_http
a2enmod ssl
# fix this filename?
cp "${1}/collabora/etc/apache2/sites-available/collabora.conf" /etc/apache2/sites-available/collabora.conf
sed -i "s/{server_name}/${2}/g" /etc/apache2/sites-available/collabora.conf
systemctl enable apache2
systemctl restart apache2
a2ensite collabora
systemctl restart apache2
