#!/bin/sh

enable_firewall() {
    case "$os" in
        centos)
            yum -y install firewalld
            systemctl start firewalld
            systemctl enable firewalld
            ;;
        ubuntu)
            systemctl start ufw
            systemctl enable ufw
            ufw --force enable
            ufw allow ssh
            ;;
        openbsd)
            pfctl -e
            ;;
    esac
}

set_hostname_and_timezone() {
    case "$os" in
        centos|ubuntu)
            hostnamectl set-hostname "$hostname"
            timedatectl set-timezone "$timezone"
            ;;
        openbsd)
            current_hostname=$(hostname)
            if [ "$current_hostname" != "$hostname" ]; then
                printf "%s\\n" "$hostname" > /etc/myname
                hostname "$hostname"
                sed -i "/${current_hostname}/d" /etc/hosts
                printf "127.0.0.1 %s\\n" "$hostname" >> /etc/hosts
                printf "::1 %s\\n" >> /etc/hosts
            fi
            if [ ! -L /etc/localtime -o $(readlink -n /etc/localtime) != "/usr/share/zoneinfo/${timezone}" ]; then
                ln -fs /usr/share/zoneinfo/"$timezone" /etc/localtime
            fi
            ;;
    esac
}

setup_user() {
    # Add user if they don't exist
    if [ ! $(id -u "$username") ]; then
        printf 'Password for non-root user: '
        stty -echo
        read password
        stty echo
        case "$os" in
            centos)
                useradd -m -G wheel "$username"
                printf "%s:%s" "$username" "$password" | chpasswd
                ;;
            ubuntu)
                useradd -m -G sudo "$username"
                printf "%s:%s" "$username" "$password" | chpasswd
                ;;
            openbsd)
                useradd -m -G wheel -p $(printf "%s" "$password" | encrypt) "$username"
                ;;
        esac
    fi
    # Copy dotfiles to home directory
#    if ls "$files"/common/home/.* > /dev/null 2>&1; then
#        home_file_path="${files}/common/home"
#    else
#        home_file_path="${default_files}/common/home"
#    fi
#    template \
#        -f "${home_file_path}/.*" \
#        -t "/home/${username}" \
#        -p '600' \
#        -o "${username}:${username}"
#    # Set proper permissions on ~/.ssh
    if [ ! -d "/home/${username}/.ssh" ]; then
        mkdir "/home/${username}/.ssh"
        chmod 700 "/home/${username}/.ssh"
    fi
    #chmod 600 /home/"${username}"/.ssh/*
    # Prompt for a public key if no authorized_keys file was provided or if its empty
    if [ ! -f "/home/${username}/.ssh/authorized_keys" -o ! -s "/home/${username}/.ssh/authorized_keys" ]; then
        printf '\\nNo authorized_keys files was copied to ~/.ssh. Enter a public key: '
        read public_ssh_key
        printf "%s" "$public_ssh_key" >> "/home/${username}/.ssh/authorized_keys"
        chmod 600 "/home/${username}/.ssh/authorized_keys"
        chown -R "${username}:${username}" "/home/${username}/.ssh"
    fi
}

configure_sshd() {
    # Disable password authentication
	if grep -E '#?PasswordAuthentication yes|#PasswordAuthentication no|#?PermitRootLogin yes|#PermitRootLogin no' /etc/ssh/sshd_config > /dev/null; then
		sed -Ei 's/#?PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
		sed -Ei 's/#PasswordAuthentication no/PasswordAuthentication no/g' /etc/ssh/sshd_config
		sed -Ei 's/#?PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
		sed -Ei 's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config
        case "$os" in
            centos)
                systemctl restart sshd
                systemctl enable sshd
                ;;
            ubuntu)
                systemctl restart ssh
                systemctl enable ssh
                ;;
            openbsd)
                /etc/rc.d/sshd restart
                rcctl enable sshd
                ;;
        esac
	fi
}

enable_and_run_automatic_updates() {
    case "$os" in
        centos)
			yum -y install yum-cron
			sleep 2
			sed -i 's/#?update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
			sed -i 's/#update_cmd = security/update_cmd = security/g' /etc/yum/yum-cron.conf
			sed -i 's/#?apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
			sed -i 's/#apply_updates = yes/apply_updates = yes/g' /etc/yum/yum-cron.conf
			systemctl enable yum-cron
			systemctl start yum-cron
			yum-cron
            ;;
        ubuntu)
            apt-get -y install unattended-upgrades
			sleep 2
			sed -i 's/"${distro_id}:${distro_codename}";/\/\/"${distro_id}:${distro_codename}"/g' /etc/apt/apt.conf.d/50unattended-upgrades
			systemctl start unattended-upgrades
			systemctl enable unattended-upgrades
			unattended-upgrades
            ;;
        openbsd)
			syspatch_crontab_entry="0 4 * * * /usr/sbin/syspatch"
			(crontab -l -u root | grep -v -F "$syspatch_crontab_entry"; printf "$syspatch_crontab_entry\\n" ) | crontab -u root -
			syspatch
            ;;
    esac
}

base_setup() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -c) cloudinit="yes";;
            -o) os="$2"; shift;;
            -n) hostname="$2"; shift;;
            -u) username="$2"; shift;;
            -t) timezone="$2"; shift;;
            -f) files="$2"; shift;;
            *) break
        esac
        shift
    done

    if [ "$os" != 'centos' -a "$os" != 'ubuntu' -a "$os" != 'openbsd' ]; then
        usage
    fi
    if [ "$cloudinit" != "yes" ]; then
        if [ -z "$hostname" -o -z "$username" ]; then
            usage
        fi
        if [ -z "$timezone" ]; then
            timezone="UTC"
        fi
    fi
    if [ "$help" = 'yes' ]; then
        usage
    fi
    # Load template functions
    . "${provisioning_base_dir}/lib/template.sh"
    # Set default files directory for fallback
    default_files=$(readlink -f ../files)
    enable_firewall
    if [ "$cloudinit" != "yes" ]; then
        set_hostname_and_timezone
        setup_user
        configure_sshd
    fi
    enable_and_run_automatic_updates
}
