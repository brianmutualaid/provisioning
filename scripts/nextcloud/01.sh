#!/bin/sh

#
# Script to install NextCloud on Ubuntu
#

# Allow HTTP and HTTPS traffic

ufw allow http
ufw allow https

# Prompt for password for initial admin user

printf "Password for initial NextCloud admin user '${2}': "
stty -echo
read admin_password
stty echo

# Install with snap

snap install nextcloud

# Configure initial admin user

/snap/bin/nextcloud.manual-install "$2" "$admin_password"

# Set trusted domain

sleep 10
/snap/bin/nextcloud.occ config:system:set trusted_domains 0 --value="$1"

# Enable HTTPS

/snap/bin/nextcloud.enable-https lets-encrypt

# Enable some apps
# This doesn't work but we can use app:install in the future...
# See https://github.com/nextcloud/server/issues/1599

#/snap/bin/nextcloud.occ app:enable calendar
#/snap/bin/nextcloud.occ app:enable twofactor_totp
#/snap/bin/nextcloud.occ app:enable twofactor_u2f
/snap/bin/nextcloud.occ app:enable admin_audit

# Set up a Collabora Online server? Maybe in a separate role/script?
# See https://nextcloud.com/collaboraonline/

# Configure password policy

/snap/bin/nextcloud.occ config:app:set password_policy minLength --value 12
/snap/bin/nextcloud.occ config:app:set password_policy enforceUpperLowerCase --value 1

# Configure sharing settings

# To-do! Should probably lock down public/federated sharing permissions a bit...

# Enable 2FA for admin user

/snap/bin/nextcloud.occ twofactorauth:enable "$2"
