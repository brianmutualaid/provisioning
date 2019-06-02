#!/bin/sh

yum -y install keepalived
# copy keepalived.conf (for master/backup servers) into place and set permissions
systemctl enable keepalived
systemctl start keepalived

yum -y install haproxy
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
# copy haproxy.cfg into place and set permissions
systemctl enable haproxy
systemctl start haproxy
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Get syslog working

sed -i 's/#$ModLoad imudp/$ModLoad imudp/' /etc/rsyslog.conf
sed -i 's/#$UDPServerRun 514/$UDPServerRun 514\n$UDPServerAddress 127.0.0.1/' /etc/rsyslog.conf
printf 'local2.* /var/log/haproxy.log' > /etc/rsyslog.d/haproxy.conf
systemctl restart rsyslog
systemctl restart haproxy
