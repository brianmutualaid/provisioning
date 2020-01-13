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
  # Put the systemd service file in place
  template \
    -f "${default_files}/wikijs/etc/systemd/system/wiki.service" \
    -t "/etc/systemd/system/wiki.service"
  systemctl daemon-reload
  systemctl start wiki
  systemctl enable wiki
else
  printf "/home/node/wiki already exists, skipping installation...\\n"
fi

# Set up nginx reverse proxy
apt-get -y install nginx
systemctl stop nginx
template -f "${default_files}/wikijs/etc/nginx/nginx.conf" -t "/etc/nginx/nginx.conf"
template \
  -f "${default_files}/wikijs/etc/nginx/conf.d/web.conf" \
  -t "/etc/nginx/conf.d/web.conf" \
  -c "example.com ${2}"
ufw allow http
ufw allow https
apt-get -y install certbot
letsencrypt certonly -n --standalone -d "$2" --agree-tos --email "$3"
systemctl start nginx
systemctl enable nginx

# Set up a mail relay for local user password resets
DEBIAN_FRONTEND=noninteractive apt-get -y install mailutils
template \
  -f "${default_files}/wikijs/etc/postfix/main.cf" \
  -t "/etc/postfix/main.cf" \
  -c "example.com ${2}"
systemctl start postfix
systemctl enable postfix

echo "The wiki is running! Go to the domain name you configured to complete the configuration process. Also consider setting up certbot to run on regular intervals in the root user's crontab with a line like the following:

13 * * * * /usr/bin/certbot renew --nginx --quiet --renew-hook \"systemctl reload nginx\""
