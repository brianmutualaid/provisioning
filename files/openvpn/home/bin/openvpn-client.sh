#!/bin/sh

#
# Create keys and certificates for a new OpenVPN client
#

if ! [ $(id -u) = "0" ]; then
  printf "This script must be run as root.\n"
  exit 1
fi

usage() {
  printf "Usage:

  $0 [-p <pki directory>] [-e <easy-rsa directory>] -c <client name> [-o|-d]

  -p: Set the path to the PKI directory. Defaults to /etc/openvpn/easy-rsa-pki/.
  -e: Set the path to the easy-rsa directory. Defaults to /usr/local/share/easy-rsa/.
  -c: Set the client name for the new OpenVPN client.
  -o: Just generate the .ovpn file for a client, don't generate new certificates or keys.
  -d: Delete a user by revoking the client certificate.\n"

  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p) pki_directory="$2"; shift;;
    -e) easy_rsa_directory="$2"; shift;;
    -c) client_name="$2"; shift;;
    -o) ovpn_only="yes";;
    -d) revoke="yes";;
    *) usage; break
  esac
  shift
done

if [ -z "$pki_directory" ]; then
  pki_directory="/etc/openvpn/easy-rsa-pki/"
fi
if [ -z "$easy_rsa_directory" ]; then
  easy_rsa_directory="/usr/local/share/easy-rsa/"
fi
if [ -z "$client_name" ]; then
  usage
fi
if [ "$ovpn_only" = "yes" -a "$revoke" = "yes" ]; then
  usage
fi

cd "$easy_rsa_directory"

if [ "$revoke" = "yes" ]; then
  ./easyrsa --pki-dir="$pki_directory" revoke "$client_name"
  ./easyrsa --pki-dir="$pki_directory" gen-crl
  chmod 640 "$pki_directory"/crl.pem
  chown _openvpn:_openvpn "$pki_directory"/crl.pem
  cp -p "$pki_directory"/crl.pem /var/openvpn/chrootjail/etc/openvpn/crl.pem
else
  if [ "$ovpn_only" != "yes" ]; then
    ./easyrsa --batch=1 --pki-dir="$pki_directory" --req-cn="$client_name" gen-req "$client_name" nopass
    openssl req -in "$pki_directory"/reqs/"$client_name".req -text -noout
    openssl rsa -in "$pki_directory"/private/"$client_name".key -check -noout
    ./easyrsa --batch=1 --pki-dir="$pki_directory" sign client "$client_name"
  fi

  ca_cert=`cat /etc/openvpn/certs/vpn-ca.crt`
  client_cert=`openssl x509 -in "$pki_directory"issued/"$client_name".crt`
  client_key=`cat "$pki_directory"private/"$client_name".key`
  ta_key=`cat /etc/openvpn/private/vpn-ta.key`

  printf "Creating .ovpn file for $client_name at $HOME/$client_name.ovpn..."

  printf "client
dev tun
proto tcp4
remote openvpn.mutualaid.info 443
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA512
verb 3
auth-user-pass
key-direction 1
<ca>
$ca_cert
</ca>
<cert>
$client_cert
</cert>
<key>
$client_key
</key>
<tls-auth>
$ta_key
</tls-auth>" > "$HOME"/"$client_name".ovpn
fi
