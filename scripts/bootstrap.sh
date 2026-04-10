#!/usr/bin/env bash
set -euo pipefail

NODE_NAME="${1:-}"
NODE_IP="${2:-}"

if [[ -z "${NODE_NAME}" || -z "${NODE_IP}" ]]; then
  echo "Usage: bootstrap.sh <node_name> <node_ip>"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y python3 python3-apt curl ca-certificates gnupg lsb-release openssh-client openssh-server

cat >/etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 ${NODE_NAME}

192.168.56.10 master
192.168.56.11 worker1
192.168.56.12 worker2
192.168.56.20 tools

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

hostnamectl set-hostname "${NODE_NAME}"

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown vagrant:vagrant /home/vagrant/.ssh

SHARED_KEY_FILE="/vagrant/.vagrant/machines/tools/virtualbox/private_key"

if [[ ! -f "${SHARED_KEY_FILE}" ]]; then
  echo "Missing shared key source: ${SHARED_KEY_FILE}. Run 'vagrant up tools' first."
  exit 1
fi

cp "${SHARED_KEY_FILE}" /home/vagrant/.ssh/k8s_vm_ed25519
ssh-keygen -y -f /home/vagrant/.ssh/k8s_vm_ed25519 >/home/vagrant/.ssh/k8s_vm_ed25519.pub
chmod 600 /home/vagrant/.ssh/k8s_vm_ed25519
chmod 644 /home/vagrant/.ssh/k8s_vm_ed25519.pub
chown vagrant:vagrant /home/vagrant/.ssh/k8s_vm_ed25519 /home/vagrant/.ssh/k8s_vm_ed25519.pub

touch /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
if ! grep -q -F "$(cat /home/vagrant/.ssh/k8s_vm_ed25519.pub)" /home/vagrant/.ssh/authorized_keys; then
  cat /home/vagrant/.ssh/k8s_vm_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
fi
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys

cat >/home/vagrant/.ssh/config <<'EOF'
Host master
  HostName 192.168.56.10
  User vagrant
  IdentityFile ~/.ssh/k8s_vm_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new

Host worker1
  HostName 192.168.56.11
  User vagrant
  IdentityFile ~/.ssh/k8s_vm_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new

Host worker2
  HostName 192.168.56.12
  User vagrant
  IdentityFile ~/.ssh/k8s_vm_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new

Host tools
  HostName 192.168.56.20
  User vagrant
  IdentityFile ~/.ssh/k8s_vm_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
EOF

chmod 600 /home/vagrant/.ssh/config
chown vagrant:vagrant /home/vagrant/.ssh/config
