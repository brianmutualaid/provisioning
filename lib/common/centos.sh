#!/bin/sh

#
# Base script for all CentOS 7 installs
#

# Install and enable firewalld

yum -y install firewalld
systemctl start firewalld
systemctl enable firewalld

# Set hostname and timezone

hostnamectl set-hostname "$1"
timedatectl set-timezone "$3"

# Create new user if they don't already exist

if [ ! $(id -u "$2") ]; then
    printf "Password for non-root user: "
    stty -echo
    read password
    stty echo
    useradd -m -G wheel "$2"
    printf "$2":"$password" | chpasswd
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

# Disable SSH password authentication

sed -i 's/#?PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#?PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd
systemctl enable sshd

# Update packages and install useful stuff

yum -y update
yum -y install tmux bind-utils

# Install yum-cron and configure it to automatically install security updates

yum -y install yum-cron
sleep 2
sed -i 's/#?update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
sed -i 's/#update_cmd = security/update_cmd = security/g' /etc/yum/yum-cron.conf
sed -i 's/#?apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
sed -i 's/#apply_updates = yes/apply_updates = yes/g' /etc/yum/yum-cron.conf
systemctl enable yum-cron
systemctl start yum-cron
