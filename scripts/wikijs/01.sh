#!/bin/bash

# Include template function and set default files dir
. "${provisioning_base_dir}/lib/template.sh"
default_files=$(readlink -f ../files)

# From https://github.com/nodesource/distributions/blob/master/README.md#deb
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt-get install -y nodejs

apt-get install -y postgresql postgresql-contrib
sudo -u postgres createdb wiki
printf 'Password for wiki PostgreSQL user: '
stty -echo
read password
stty echo
sudo -u postgres psql -c "CREATE USER wiki WITH PASSWORD '$password';"

# User for node process
if [ !$(id -u node) ]; then
  useradd -r -m -s /usr/sbin/nologin node
fi

if [ ! -d /home/node/wiki ]; then
  pushd /home/node
  sudo -u node curl -L -O https://github.com/Requarks/wiki/releases/download/2.0.0-rc.17/wiki-js.tar.gz
  sudo -u node mkdir wiki
  sudo -u node tar xzf wiki-js.tar.gz -C ./wiki
  popd
  # Put the config.yml file in place
  template \
    -f "${default_files}/wikijs/home/node/wiki/config.yml" \
    -t "/home/node/wiki/config.yml" \
    -c "psqlpassword ${password}" \
    -o "node"
else
  printf "/home/node/wiki already exists, skipping installation...\\n"
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

echo "Run 'node server' from /home/node/wikijs to start the configuration process!"
