#!/bin/bash

# Mostly from https://www.elastic.co/guide/en/logstash/7.10/installing-logstash.html

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat << EOF > /etc/yum.repos.d/logstash.repo
[logstash]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

dnf -y install --enablerepo=logstash logstash

/bin/systemctl daemon-reload
/bin/systemctl enable logstash.service
systemctl start logstash.service

