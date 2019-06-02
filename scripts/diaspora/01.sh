#!/bin/sh

#
# Script to install Diaspora on CentOS 7
#
# Based on https://wiki.diasporafoundation.org/Installation/CentOS/7?db=postgres&mode=production
#

# Prompt for passwords for diaspora and diaspora database users

printf "Password for diaspora user: "
stty -echo
read diaspora_password
stty echo
printf "Password for diaspora database user: "
stty -echo
read diaspora_db_password
stty echo

# Add diaspora user

useradd -m diaspora
printf diaspora:"$diaspora_password" | chpasswd

# Install dependencies

yum -y install epel-release
yum -y install tar make automake gcc gcc-c++ git net-tools libcurl-devel libxml2-devel libffi-devel libxslt-devel wget redis ImageMagick nodejs postgresql-devel

# Start and enable redis

systemctl start redis
systemctl enable redis

# Install PostgreSQL

yum -y install postgresql-server postgresql-contrib
sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
postgresql-setup initdb
systemctl enable postgresql
systemctl start postgresql

# Install dependencies for RVM

yum -y install patch libyaml-devel patch readline-devel openssl-devel bzip2 libtool bison sqlite-devel

# Create diaspora database user

sudo -u postgres psql -c "CREATE USER diaspora WITH CREATEDB PASSWORD "$diaspora_db_password""

# Install RVM as the diaspora user

su - diaspora 
curl -O https://raw.githubusercontent.com/wayneeseguin/rvm/master/binscripts/rvm-installer
rvm_sum=$(sha256sum ./rvm-installer | awk '{print $1}')
if [ "$rvm_sum" = "b3d4573424e57ebcc9b190a1ec6fafe381b7b799dc36b39620a756178dbc7fa3" ]; then
	chmod +x ./rvm-installer
	./rvm-installer
else
	printf "rvm-installer sum does not match known sum. Exiting...\n"
	exit 1
fi
printf '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> ~/.bashrc
source .bashrc
rvm autolibs read-fail
rvm install 2.3

# Clone Diaspora and copy configs

git clone -b master https://github.com/diaspora/diaspora.git
cd diaspora
cp config/database.yml.example config/database.yml
cp config/diaspora.yml.example config/diaspora.yml

sed -i 's/username: postgres/username: diaspora/g' config/database.yml
sed -i "s/password:$/password: "$diaspora_db_password"/g" config/database.yml
sed -i "s/#url: \"https:\/\/example.org\/\"/url: \"https:\/\/${url}\/\"/g" config/diaspora.yml
sed -i "s/#certificate_authorities: '\/etc\/pki\/tls\/certs\/ca-bundle.crt'/certificate_authorities: '\/etc\/pki\/tls\/certs\/ca-bundle.crt'/g" config/diaspora.yml
sed -i "s/#rails_environment: 'development'/rails_environment: 'production'/g" config/diaspora.yml
sed -i "s/#listen: '127.0.0.1:3000'/listen: '127.0.0.1:3000'/g" config/diaspora.yml

# Back to root

exit

# Install and configure nginx

yum -y install nginx
cp "$2"/diaspora/etc/nginx/nginx.conf /etc/nginx/nginx.conf
cp "$2"/diaspora/etc/nginx/conf.d/diaspora.conf /etc/nginx/conf.d/diaspora.conf
sed -i "s/example.com/$1/g" /etc/nginx/conf.d/diaspora.conf
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
systemctl restart firewalld
yum -y install certbot
certbot certonly --standalone -d "$1" --agree-tos --email "$3"
systemctl start nginx
systemctl enable nginx

# Install Ruby libraries required by Diaspora
su - diaspora
cd diaspora
gem install bundler
RAILS_ENV=production bin/bundle install --jobs $(nproc) --deployment --without test development --with postgresql
RAILS_ENV=production bin/rake db:create db:schema:load
RAILS_ENV=production bin/rake assets:precompile

