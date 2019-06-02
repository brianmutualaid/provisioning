# Roles

## Overview

All scripted roles use common scripts that perform the following baseline functions:

* Enables a firewall (ufw, firewalld, or pf) and allows inbound SSH traffic
* Sets a hostname and timezone
* Creates a non-root user with su/sudo permissions and sets up a public key for SSH access
* Restricts SSH authentication to public keys
* Disables root SSH access
* Configures automatic, unattended security updates (not true for OpenBSD at the moment)

There are common scripts for CentOS 7, Ubuntu 16.04, and OpenBSD. If you specify a custom path to a provisioning-files repo, these scripts work non-interactively and use the file `common/home/.ssh/authorized_keys` for the SSH public key to allow access from. Otherwise they prompt for a public key.

There also may be some markdown files with manual steps for certain roles (only the macbook role right now).

## Scripts

### collabora

To use with the nextcloud role for the Collabora Online app.

### diaspora

Hasn't been updated in a while and probably doesn't work anymore. I would advise against using it as-is. When it worked, it set up a new Diaspora pod on CentOS 7.

### haproxy

Work-in-progress. Goal is to create a SSL/TLS/HTTPS passthrough load balancer on CentOS 7, with the option of using keepalived for failover. This will be useful for hosting multiple public websites behind NAT.

### jenkins

Hasn't been updated in a while and is untested. I'm not using Jenkins for anything at the moment so 🤷‍♂️.

### kvm

Sets up a minimal (no GUI) KVM host and a KVM storage pool on a dedicated disk. For CentOS 7.

### macbook

Just a markdown file with a list of applications to install and some baseline CLI stuff to do on a fresh macOS install. Normally recovery would be done from a Time Machine backup which would cover stuff in System Preferences too, but this is good to have anyway for clean installs.

### nextcloud

Work-in-progress but working. Might be useful at some point for setting up a somewhat secure NextCloud installation on Ubuntu 16.04.

### openvpn

To set up an OpenVPN server on OpenBSD. Steps are mostly from [Setting up OpenVPN (free community version) on OpenBSD](http://www.openbsdsupport.org/openvpn-on-openbsd.html).

### pf

To set up a pf gateway system on OpenBSD that provides DHCP and DNS services, and optionally install OpenVPN by running the openvpn role. Pretty unique to my own personal setup right now (e.g. nsd has an authoritative DNS zone for mutualaid.info).

### squid

Set up a squid proxy that intercepts HTTPS traffic. Mostly did this to try it out, the script probably isn't very useful in general.

### web

Basic static nginx website with HTTPS on CentOS 7. Unique to my personal website.
