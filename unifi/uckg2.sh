#!/bin/bash

### This script will allow you to own your Cloudkey Gen2.

### This is an early version 0.2... more features to come.

### If you use this it is at your own risk.

echo "About to remove all the UniFi software."
echo "I am not responsible if anything goes wrong."
echo
echo "Type: \"I understand\""
read check

if [[ $check == "I understand" ]]; then
  echo "Cross your fingers ..."
else
  exit 1
fi

apt update
apt -y upgrade

apt -y remove mongodb-clients mongodb-server-core mongodb-server uid-agent unifi-pion-gw node18

apt -y remove unifi-core ucore-setup-listener uck-tools ubnt-zram-swap ubnt-unifi-setup ubnt-ucp4cpp ubnt-systemhub ubnt-opencv4-libs ubnt-binmecpp ubnt-archive-keyring

apt -y remove nginx node20 nodejs

mkdir /usr/share/postgresql/9.6/man/man1
touch /usr/share/postgresql/9.6/man/man1/psql.1.gz
apt -y remove postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6

mkdir /usr/share/postgresql/14/man/man1
touch /usr/share/postgresql/14/man/man1/psql.1.gz
apt -y remove postgresql-14 postgresql-client-14

mkdir /usr/share/postgresql/16/man/man1
touch /usr/share/postgresql/16/man/man1/psql.1.gz
apt -y remove postgresql-16 postgresql-client-16 postgresql postgresql-common postgresql-client-common

echo "Paste your rsa_id.pub key and press enter..."
read authorizedkey

mkdir /root/.ssh
echo "$authorizedkey" > /root/.ssh/authorized_keys

cat /etc/ssh/sshd_config | grep --invert-match "PermitRootLogin" > sshd_config.backup
echo "PermitRootLogin prohibit-password" >> sshd_config.backup
echo "PubkeyAuthentication yes" >> sshd_config.backup
echo "AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2" >> sshd_config.backup
rm /etc/ssh/sshd_config
cp sshd_config.backup /etc/ssh/sshd_config

echo "Press ENTER to reboot..."

read check

reboot now
