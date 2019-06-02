#!/bin/sh

#
# Script to set up OpenVPN on OpenBSD 6.2
#
# Fairly confident that this will work as a script now...
#

# OpenVPN setup steps mostly from http://www.openbsdsupport.org/openvpn-on-openbsd.html

# If OpenVPN is already installed, skip easyrsa key/cert generation stuff. If you want to re-run all of this, completely uninstall the OpenVPN package
if [ ! $(pkg_info -e 'openvpn->=2.4.4') ]; then
  pkg_add openvpn-- easy-rsa
  install -m 700 -d /etc/openvpn/private
  install -m 700 -d /etc/openvpn/private-client-conf
  install -m 755 -d /etc/openvpn/certs
  install -m 755 -d /var/log/openvpn
  install -m 755 -d /var/openvpn/chrootjail/etc/openvpn
  install -m 755 -d /etc/openvpn/chrootjail/etc/openvpn/ccd  # client custom configuration dir
  install -m 755 -d /var/openvpn/chrootjail/var/openvpn
  #mv /etc/openvpn/ccd/ /etc/openvpn/crl.pem /var/openvpn/chrootjail/etc/openvpn/
  ln -s /var/openvpn/chrootjail/etc/openvpn/crl.pem /etc/openvpn/crl.pem
  ln -s /var/openvpn/chrootjail/etc/openvpn/ccd/ /etc/openvpn/
  ln -s /var/openvpn/chrootjail/etc/openvpn/replay-persist-file /etc/openvpn/replay-persist-file
  #ls -alpd /etc/openvpn/certs /etc/openvpn/ccd /var/openvpn/chrootjail /var/openvpn/chrootjail/etc /var/openvpn/chrootjail/etc/openvpn /etc/openvpn/private /etc/openvpn/private-client-conf /var/log/openvpn
  pkiDir="/etc/openvpn/easy-rsa-pki/"
  mkdir ${pkiDir}
  easyrsaDir="/usr/local/share/easy-rsa/"
  cd ${easyrsaDir}
  #ls -alp /etc/openvpn/private/vpn-ta.key || openvpn --genkey --secret /etc/openvpn/private/vpn-ta.key
  openvpn --genkey --secret /etc/openvpn/private/vpn-ta.key
  ./easyrsa --batch=0 --pki-dir=${pkiDir} init-pki
  ./easyrsa --batch=1 --pki-dir=${pkiDir} gen-dh
  ./easyrsa --batch=1 --pki-dir=${pkiDir} --req-cn=vpn-ca build-ca nopass
  openssl x509 -in ${pkiDir}/ca.crt -text -noout
  openssl rsa -in ${pkiDir}/private/ca.key -check -noout
  ./easyrsa --batch=1 --pki-dir=${pkiDir} --req-cn=vpnserver gen-req vpnserver nopass
  openssl req -in ${pkiDir}/reqs/vpnserver.req -text -noout
  openssl rsa -in ${pkiDir}/private/vpnserver.key -check -noout
  ./easyrsa --batch=1 --pki-dir=${pkiDir} show-req vpnserver
  ./easyrsa --batch=1 --pki-dir=${pkiDir} sign server vpnserver
  openssl x509 -in ${pkiDir}/issued/vpnserver.crt -text -noout
  echo "Last added cert in db: `cat ${pkiDir}/index.txt|tail -1`"
  echo "Next added cert will have number: `cat ${pkiDir}/serial`"
  ./easyrsa --batch=1 --pki-dir=${pkiDir} gen-crl
  chown :_openvpn ${pkiDir}/crl.pem; chmod g+r ${pkiDir}/crl.pem 
  openssl crl -in ${pkiDir}/crl.pem -text -noout
  cp -p ${pkiDir}/ca.crt /etc/openvpn/certs/vpn-ca.crt
  cp -p ${pkiDir}/private/ca.key /etc/openvpn/private/vpn-ca.key
  cp -p ${pkiDir}/issued/vpnserver.crt /etc/openvpn/certs/vpnserver.crt
  cp -p ${pkiDir}/private/vpnserver.key /etc/openvpn/private/vpnserver.key
  cp -p ${pkiDir}/dh.pem /etc/openvpn/dh.pem
  cp -p ${pkiDir}/crl.pem /etc/openvpn/crl.pem
  test -f /etc/openvpn/private/mgmt.pwd || touch /etc/openvpn/private/mgmt.pwd
  chown root:wheel /etc/openvpn/private/mgmt.pwd; chmod 600 /etc/openvpn/private/mgmt.pwd
  openssl rand -base64 32 > /etc/openvpn/private/mgmt.pwd
fi

# Copy scripts to home directory

if [ ! -d "/home/${2}/bin" ]; then
    mkdir /home/"$2"/bin
    chown "$2":"$2" /home/"$2"/bin
fi
if [ ! -f "/home/${2}/bin/openvpn-client.sh" ]; then
    cp "$1"/openvpn/home/bin/openvpn-client.sh /home/"$2"/bin/openvpn-client.sh
    chown "$2":"$2" /home/"$2"/bin/openvpn-client.sh
    chmod 700 /home/"$2"/bin/openvpn-client.sh
fi

# Additional steps

if [ ! -d /var/openvpn/chrootjail/tmp ]; then
    install -m 755 -d /var/openvpn/chrootjail/tmp
    chown _openvpn:_openvpn /var/openvpn/chrootjail/tmp
fi

# Set up openvpn-htpasswd

if [ ! -f /var/openvpn/chrootjail/var/openvpn/openvpn-htpasswd ]; then
    ftp -o /tmp/openvpn-htpasswd.c https://raw.githubusercontent.com/brianmutualaid/openvpn-htpasswd/master/openvpn-htpasswd.c
    gcc -static -o /var/openvpn/chrootjail/var/openvpn/openvpn-htpasswd /tmp/openvpn-htpasswd.c
    chown _openvpn:wheel /var/openvpn/chrootjail/var/openvpn/openvpn-htpasswd
    chmod 755 /var/openvpn/chrootjail/var/openvpn/openvpn-htpasswd
fi
if ! grep -e "^${2}:" /var/openvpn/chrootjail/var/openvpn/users.htpasswd > /dev/null; then
    printf "Password for OpenVPN user (username will match non-root username): "
    stty -echo
    read openvpn_password
    stty echo
    printf "$2":"$openvpn_password" | htpasswd -I /var/openvpn/chrootjail/var/openvpn/users.htpasswd
fi

# Copy config files and rc.d scripts into place

openvpn_change='no'
if ! diff "${1}/openvpn/etc/openvpn/server.conf" /etc/openvpn/server.conf; then
    cp "${1}/openvpn/etc/openvpn/server.conf" /etc/openvpn/server.conf
    chown root:_openvpn /etc/openvpn/server.conf
    chmod 640 /etc/openvpn/server.conf
    openvpn_change='yes'
fi
if ! diff "${1}/openvpn/etc/rc.d/openvpn" /etc/rc.d/openvpn; then
    cp "${1}/openvpn/etc/rc.d/openvpn" /etc/rc.d/openvpn
    chown root:wheel /etc/rc.d/openvpn
    chmod 555 /etc/rc.d/openvpn
    openvpn_change='yes'
fi
if [ "$openvpn_change" = 'yes' ]; then
    rcctl -f restart openvpn
fi
if ! rcctl ls on | grep openvpn > /dev/null; then
    rcctl enable openvpn
fi
