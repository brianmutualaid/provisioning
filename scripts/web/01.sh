#!/bin/sh

# Install EPEL repository

yum -y install epel-release

# Install and configure nginx

yum -y install nginx
cp "$2"/web/etc/nginx/nginx.conf /etc/nginx/nginx.conf
cp "$2"/web/etc/nginx/conf.d/web.conf /etc/nginx/conf.d/web.conf
sed -i "s/example.com/$1/g" /etc/nginx/conf.d/web.conf
cp -R "$2"/web/var/www/ /var/www

# Open firewall ports for HTTP and HTTPS

firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
systemctl restart firewalld

# Install PHP and MySQL

apt-get -y install nginx mysql-server php7.0 php7.0-gd php7.0-mysql php7.0-xml
printf "\\nEnter a password for the MySQL root user: "
read mysql_root_pw
mysqladmin password "$mysql_root_pw"
mysql -p"$mysql_root_pw" -u root <<_EOF_
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_
systemctl start mysql
systemctl enable mysql
systemctl start php7.0-fpm
systemctl enable php7.0-fpm

# Get a certificate and start and enable nginx

apt-get -y install certbot
letsencrypt certonly --standalone -d "$1" --agree-tos --email "$3"
systemctl start nginx
systemctl enable nginx

# Set permissions

chown -R www-data:www-data /var/www
chmod -R 755 /var/www
chcon -Rt httpd_sys_content_t /var/www
systemctl restart nginx

# Install webtrees

curl -L -o "${HOME}/webtrees-1.7.9.tgz" https://github.com/fisharebest/webtrees/archive/1.7.9.tar.gz
mkdir /var/www/family
tar --strip-components=1 -xzf "${HOME}/webtrees-1.7.9.tgz" -C /var/www/family
chmod -R 777 /var/www/family/data


