#!/bin/sh

#
# Script to set up pf on OpenBSD
#

# Include template function

. "${provisioning_base_dir}/lib/template.sh"

# Set default files directory for fallback

default_files=$(readlink -f ../files)

# Enable IP forwarding

if ! grep -e '^net\.inet\.ip\.forwarding=1$' /etc/sysctl.conf > /dev/null; then
    printf "net.inet.ip.forwarding=1\\n" >> /etc/sysctl.conf
fi
if [ $(sysctl -n net.inet.ip.forwarding) != '1' ]; then
    sysctl net.inet.ip.forwarding=1
fi

# hostname.*

if ls "$1"/pf/etc/hostname.* > /dev/null 2>&1; then
    hostname_file_path="${1}/pf/etc"
else
    hostname_file_path="${default_files}/pf/etc"
fi
template \
    -f "${hostname_file_path}/hostname.*" \
    -t '/etc' \
    -r "extif ${2} intif ${3}" \
    -p '640' \
    -s 'sh /etc/netstart $(basename "$i" | cut -d "." -f 2)'

# dhclient.conf

if [ -f "${1}/pf/etc/dhclient.conf" ]; then
    dhclient_file_path="${1}/pf/etc/dhclient.conf"
else
    dhclient_file_path="${default_files}/pf/etc/dhclient.conf"
fi
template \
    -f "$dhclient_file_path" \
    -t /etc/dhclient.conf \
    -c "hostname ${4} extif ${2} domain ${5}" \
    -s "sh /etc/netstart ${3}"

# dhcpd.conf

if [ -f "${1}/pf/etc/dhcpd.conf" ]; then
    dhcpd_file_path="${1}/pf/etc/dhcpd.conf"
else
    dhcpd_file_path="${default_files}/pf/etc/dhcpd.conf"
fi
template \
    -f "$dhcpd_file_path" \
    -t /etc/dhcpd.conf \
    -c "domain ${5}" \
    -s 'rcctl -f restart dhcpd'
if ! rcctl ls on | grep dhcpd > /dev/null; then
    rcctl enable dhcpd
fi

# zonefiles

if ls "$1"/pf/var/nsd/zones/master/* > /dev/null 2>&1; then
    zones_file_path="${1}/pf/var/nsd/zones/master"
else
    zones_file_path="${default_files}/pf/var/nsd/zones/master"
fi
template \
    -f "${zones_file_path}/*" \
    -t /var/nsd/zones/master \
    -c "hostname ${4} domain ${5}" \
    -r "domain ${5}"

# nsd.conf

if [ -f "${1}/pf/var/nsd/etc/nsd.conf" ]; then
    nsd_file_path="${1}/pf/var/nsd/etc/nsd.conf"
else
    nsd_file_path="${default_files}/pf/var/nsd/etc/nsd.conf"
fi
template \
    -f "$nsd_file_path" \
    -t /var/nsd/etc/nsd.conf \
    -c "domain ${5}" \
    -s 'rcctl -f restart nsd'
if ! rcctl ls on | grep nsd > /dev/null; then
    rcctl enable nsd
fi

# unbound.conf

if [ -f "${1}/pf/var/unbound/etc/unbound.conf" ]; then
    unbound_file_path="${1}/pf/var/unbound/etc/unbound.conf"
else
    unbound_file_path="${default_files}/pf/var/unbound/etc/unbound.conf"
fi
template \
    -f "$unbound_file_path" \
    -t /var/unbound/etc/unbound.conf \
    -c "domain ${5}" \
    -s 'rcctl -f restart unbound'
if ! rcctl ls on | grep unbound > /dev/null; then
    rcctl enable unbound
fi


# pf.conf

if [ -f "${1}/pf/etc/pf.conf" ]; then
    pf_file_path="${1}/pf/etc/pf.conf"
else
    pf_file_path="${default_files}/pf/etc/pf.conf"
fi
template \
    -f "$pf_file_path" \
    -t /etc/pf.conf \
    -c "intif ${3}" \
    -p 600 \
    -s 'pfctl -d & pfctl -e & pfctl -f /etc/pf.conf'
