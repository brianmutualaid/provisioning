#!/bin/sh

pushd /root
git clone https://github.com/brianmutualaid/provisioning.git
pushd /root/provisioning/roles
./codimd.sh -n "codipoc.example.com" -u "brian"
