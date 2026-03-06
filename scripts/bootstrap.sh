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
apt-get install -y python3 python3-apt curl ca-certificates gnupg lsb-release

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
