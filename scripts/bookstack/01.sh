#!/bin/bash

# Mostly from https://github.com/BookStackApp/devops/blob/master/scripts/installation-ubuntu-18.04.sh
# But with nginx instead of Apache

# Install core system packages
export DEBIAN_FRONTEND=noninteractive
add-apt-repository universe
apt update
apt install -y unzip git curl php7.2-fpm php7.2-curl php7.2-mbstring php7.2-ldap \
php7.2-tidy php7.2-xml php7.2-zip php7.2-gd php7.2-mysql mysql-server-5.7

# Only set up database and install bookstack if /var/www/bookstack doesn't already exist
if [ ! -d /var/www/bookstack ]; then
  # Set up database
  DB_PASS="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)"
  mysql -u root --execute="CREATE DATABASE bookstack;"
  mysql -u root --execute="CREATE USER 'bookstack'@'localhost' IDENTIFIED BY '$DB_PASS';"
  mysql -u root --execute="GRANT ALL ON bookstack.* TO 'bookstack'@'localhost';FLUSH PRIVILEGES;"

  # Download BookStack
  pushd /var/www
  git clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch bookstack
  popd
  BOOKSTACK_DIR="/var/www/bookstack"
  pushd $BOOKSTACK_DIR

  # Install composer
  EXPECTED_SIGNATURE=$(wget https://composer.github.io/installer.sig -O - -q)
  curl -s https://getcomposer.org/installer > composer-setup.php
  ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

  if [ "$EXPECTED_SIGNATURE" = "$ACTUAL_SIGNATURE" ]
  then
      php composer-setup.php --quiet
      RESULT=$?
      rm composer-setup.php
  else
      >&2 echo 'ERROR: Invalid composer installer signature'
      rm composer-setup.php
      exit 1
  fi

  # Install BookStack composer dependancies
  php composer.phar install

  # Copy and update BookStack environment variables
  cp .env.example .env
  sed -i.bak 's/DB_DATABASE=.*$/DB_DATABASE=bookstack/' .env
  sed -i.bak 's/DB_USERNAME=.*$/DB_USERNAME=bookstack/' .env
  sed -i.bak "s/DB_PASSWORD=.*\$/DB_PASSWORD=$DB_PASS/" .env
  echo "APP_URL="
  # Generate the application key
  php artisan key:generate --no-interaction --force
  # Migrate the databases
  php artisan migrate --no-interaction --force

  # Set file and folder permissions
  chown www-data:www-data -R bootstrap/cache public/uploads storage && chmod -R 755 bootstrap/cache public/uploads storage

  # Some security setup from
  echo "STORAGE_TYPE=local_secure" >> .env
  echo "ALLOW_ROBOTS=false" >> .env
  echo "SESSION_SECURE_COOKIE=true" >> .env
fi

# Set up nginx

apt-get -y install nginx
systemctl stop nginx
cp "$1"/bookstack/etc/nginx/nginx.conf /etc/nginx/nginx.conf
cp "$1"/bookstack/etc/nginx/conf.d/web.conf /etc/nginx/conf.d/web.conf
sed -i "s/example.com/$2/g" /etc/nginx/conf.d/web.conf
ufw allow http
ufw allow https
apt-get -y install certbot
letsencrypt certonly -n --standalone -d "$2" --agree-tos --email "$3"
systemctl start nginx
systemctl enable nginx

popd
