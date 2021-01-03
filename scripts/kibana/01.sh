#!/bin/bash

# Mostly from https://www.elastic.co/guide/en/kibana/7.10/install.html

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat << EOF > /etc/yum.repos.d/kibana.repo
[kibana]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

dnf -y install --enablerepo=kibana kibana

/bin/systemctl daemon-reload
/bin/systemctl enable kibana.service
systemctl start kibana.service
