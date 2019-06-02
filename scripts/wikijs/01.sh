#!/bin/bash

# From https://github.com/nodesource/distributions/blob/master/README.md#deb
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt-get install -y nodejs

# From https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
apt-get update
apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod

# User for node process
if [ !$(id -u node) ]; then
  useradd -r -m -s /usr/sbin/nologin node
fi

# From https://docs.requarks.io/wiki/install/installation
if [ ! -d /home/node/wikijs ]; then
  sudo -u node mkdir /home/node/wikijs
  pushd /home/node/wikijs
  sudo -u node curl -sSo- https://wiki.js.org/install.sh | sudo -u node bash
  popd
else
  printf "/home/node/wikijs already exists, skipping installation...\\n"
fi

# Set up nginx reverse proxy
apt-get -y install nginx
systemctl stop nginx
cp "$1"/wikijs/etc/nginx/nginx.conf /etc/nginx/nginx.conf
cp "$1"/wikijs/etc/nginx/conf.d/web.conf /etc/nginx/conf.d/web.conf
sed -i "s/example.com/$2/g" /etc/nginx/conf.d/web.conf
ufw allow http
ufw allow https
apt-get -y install certbot
letsencrypt certonly -n --standalone -d "$2" --agree-tos --email "$3"
systemctl start nginx
systemctl enable nginx

echo "Run 'node wiki configure' from /home/node/wikijs to start the configuration process!"
