#!/bin/sh

#
# Base script for all Ubuntu 16 installs
#

# Enable ufw

systemctl start ufw
systemctl enable ufw
ufw enable

# Set hostname and timezone

hostnamectl set-hostname "$1"
timedatectl set-timezone "$3"

# Create new user if they don't already exist

if [ ! $(id -u "$2") ]; then
    printf "Password for non-root user: "
    stty -echo
    read password
    stty echo
    useradd -m -G sudo "$2"
    printf "$2":"$password" | chpasswd
else
    printf "User already exists. Continuing...\n"
fi

# Prompt for public SSH key and set up in authorized_keys file

if [ ! -s "/home/${2}/.ssh/authorized_keys" ]; then
    printf "\nPublic SSH key for authorized_keys file: "
    read public_ssh_key
    if [ ! -d "/home/${2}/.ssh" ]; then
        mkdir "/home/${2}/.ssh"
        chown "$2":"$2" "/home/${2}/.ssh"
        chmod 700 "/home/${2}/.ssh"
    fi
    printf "$public_ssh_key" >> "/home/${2}/.ssh/authorized_keys"
    chown "$2":"$2" "/home/${2}/.ssh/authorized_keys"
    chmod 700 "/home/${2}/.ssh/authorized_keys"
else
    printf "authorized_keys file already exists. Continuing...\n"
fi

# Disable SSH password authentication and set up public key collected earlier

sed -i 's/#?PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#?PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd
systemctl enable sshd

# Update packages and install useful stuff

apt-get -y update
apt-get -y upgrade
apt-get -y install tmux dnsutils

# Install unattended-upgrades and configure it to automatically install security updates

apt-get -y install unattended-upgrades
sleep 2
sed -i 's/"${distro_id}:${distro_codename}";/\/\/"${distro_id}:${distro_codename}"/g' /etc/apt/apt.conf.d/50unattended-upgrades
systemctl enable unattended-upgrades
systemctl start unattended-upgrades
