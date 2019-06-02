#!/bin/sh

#
# Base script for all OpenBSD installs
#

# Include template function

. "${provisioning_base_dir}/lib/template.sh"

# Set default files directory for fallback

default_files=$(readlink -f ../files)

# Set hostname and timezone

if [ "$(hostname)" != "$1" ]; then
    printf "Hostname does not match. Updating...\\n"
    old_hostname=$(hostname)
    printf "$1\\n" > /etc/myname
    hostname "$1"
    sed -i "/${old_hostname}/d" /etc/hosts
    printf "127.0.0.1 ${1}\\n" >> /etc/hosts
    printf "::1 ${1}\\n" >> /etc/hosts
fi
if [ ! -L /etc/localtime -o $(readlink -n /etc/localtime) != "/usr/share/zoneinfo/${3}" ]; then
    printf "Timezone isn't set properly. Updating...\\n"
    ln -fs /usr/share/zoneinfo/"$3" /etc/localtime
fi

# Create new user if they don't already exist

if [ ! $(id -u "$2") ]; then
    printf "Password for non-root user: "
    stty -echo
    read password
    stty echo
    useradd -m -G wheel -p $(printf "$password" | encrypt) "$2"
fi

# Copy dotfiles to home directory of new user

if ls "$4"/common/home/.* > /dev/null 2>&1; then
    home_file_path="${4}/common/home"
else
    home_file_path="${default_files}/common/home"
fi
template \
    -f "${home_file_path}/.*" \
    -t "/home/${2}" \
    -p '600' \
    -o "${2}:${2}"

# Make sure permissions on .ssh are correct

if [ ! -d "/home/${2}/.ssh" ]; then
    mkdir "/home/${2}/.ssh"
fi
chmod 700 "/home/${2}/.ssh"
chmod 600 /home/"${2}"/.ssh/*
chown -R "${2}:${2}" "/home/${2}/.ssh"

# Prompt for a public key if no authorized_keys file was provided

if [ ! -f "/home/${2}/.ssh/authorized_keys" ]; then
    printf "\nNo authorized_keys file was copied to ~/.ssh. Enter a public key: "
    read public_ssh_key
    printf "$public_ssh_key" >> "/home/${2}/.ssh/authorized_keys"
    chown "$2":"$2" "/home/${2}/.ssh/authorized_keys"
    chmod 600 "/home/${2}/.ssh/authorized_keys"
fi

# Disable SSH password authentication

if grep -E '#?PasswordAuthentication yes|#PasswordAuthentication no|#?PermitRootLogin yes|#PermitRootLogin no' /etc/ssh/sshd_config > /dev/null; then
    sed -Ei 's/#?PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sed -Ei 's/#PasswordAuthentication no/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sed -Ei 's/#?PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    sed -Ei 's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config
    /etc/rc.d/sshd restart
    rcctl enable sshd
fi
