#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ansible sshpass git

mkdir -p /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

cat >/home/vagrant/.ansible.cfg <<'EOF'
[defaults]
inventory = /vagrant/ansible/inventory.ini
host_key_checking = False
retry_files_enabled = False
interpreter_python = auto_silent
stdout_callback = yaml

[ssh_connection]
pipelining = True
EOF

chown vagrant:vagrant /home/vagrant/.ansible.cfg
chmod 600 /home/vagrant/.ansible.cfg
