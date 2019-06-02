#!/bin/sh

#
# Script to set up Squid on CentOS 7
#

# Disable SELinux

setenforce 0
sed -i 's/^SELINUX=.*$/SELINUX=permissive/g' /etc/sysconfig/selinux
sed -i 's/^SELINUX=.*$/SELINUX=permissive/g' /etc/selinux/config

# From http://wiki.squid-cache.org/SquidFaq/BinaryPackages#CentOS

if [ ! -f /etc/yum.repos.d/squid.repo ]; then
  printf "[squid]
name=Squid repo for CentOS Linux - \$basearch
#IL mirror
baseurl=http://www1.ngtech.co.il/repo/centos/\$releasever/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=0" > /etc/yum.repos.d/squid.repo
fi

# Install EPEL so we can install squid-helpers (required for ssl_crtd) and install some other useful stuff

yum -y install epel-release
yum -y update
yum -y install tmux squid squid-helpers vim net-tools

# Below commands are mostly from http://wiki.squid-cache.org/ConfigExamples/Intercept/SslBumpExplicit

pushd /etc/squid
if [ ! -d ssl_cert ]; then
  mkdir ssl_cert
fi
pushd ssl_cert
if [ ! -f squid.pem ]; then
  openssl req -new -newkey rsa:2048 -sha256 -days 1095 -nodes -x509 -extensions v3_ca -keyout squid.pem -out squid.pem -subj "/C=US/ST=New York/L=New York/O=Squid, LLC/OU=Squid/CN=Squid/emailAddress=squid@example.com"
fi
if [ ! -f squid-client.crt ]; then
  openssl x509 -in squid.pem -outform DER -out squid-client.crt
fi
if [ ! -f /home/$2/squid-client.crt ]; then
  cp squid-client.crt /home/$2/
  chown $2:$2 /home/$2/squid-client.crt
fi
popd
chown -R squid:squid ssl_cert
chmod -R 700 ssl_cert
popd
if [ ! -d /var/lib/ssl_db ]; then
  /usr/lib64/squid/ssl_crtd -c -s /var/lib/ssl_db
fi
chown -R squid:squid /var/lib/ssl_db
if [ ! -f /etc/squid/squid.conf.orig ]; then
  mv /etc/squid/squid.conf /etc/squid/squid.conf.orig
fi
printf "http_port 3128 ssl-bump cert=/etc/squid/ssl_cert/squid.pem generate-host-certificates=on dynamic_cert_mem_cache_size=8MB cipher=HIGH:EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:!RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS options=NO_SSLv3
sslproxy_cipher EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:!RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS
sslproxy_options NO_SSLv3
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
http_access allow localnet
acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all" > /etc/squid/squid.conf
chown root:squid /etc/squid/squid.conf
chmod 640 /etc/squid/squid.conf

# Start and enable the Squid service

service squid restart
chkconfig squid on

# Print some helpful instructions

printf "
!!!
POINT YOUR OS OR BROWSER SSL PROXY SETTINGS TO THE IP ADDRESS OF YOUR
SQUID SERVER, PORT 3128, AND COPY THE FILE ~/squid-client.crt INTO YOUR
OS OR BROWSER ROOT CA STORE
!!!

"
