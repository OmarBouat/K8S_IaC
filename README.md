# Kubernetes Lab with Vagrant + Ansible

This project creates **4 Ubuntu Server VMs (headless on VirtualBox)**:

- `master` (Kubernetes control plane) - `192.168.56.10`
- `worker1` (Kubernetes worker) - `192.168.56.11`
- `worker2` (Kubernetes worker) - `192.168.56.12`
- `tools` (Ansible/control tools VM) - `192.168.56.20`

## Prerequisites (host machine)

- VirtualBox
- Vagrant

# Kubernetes Lab with Vagrant + Ansible

A complete, production-ready infrastructure-as-code setup that creates a **4-node Kubernetes cluster** (1 control-plane, 2 workers) plus a dedicated tools VM with **Gitea**, **Nexus**, and **NFS** for a complete DevOps environment.

## Features

- **4 HeadlessUbuntu Server VMs** on VirtualBox with private networking
- **Kubernetes v1.29** with containerd and Flannel CNI
- **Docker Engine** on tools VM for containerized services
- **Gitea**: Self-hosted Git repository server
- **Nexus**: Artifact repository manager (Maven, Docker, npm, etc.)
- **NFS**: Network file system for persistent shared storage
- **Ansible**: Full infrastructure automation with modular playbooks
- **Makefile**: One-command deployment and management

## Quick Start (Using Make)

### Prerequisites (host machine)

- VirtualBox
- Vagrant
- Make (optional, but convenient)

### Deploy in one command

```bash
# From project root
make up         # Start VMs + deploy cluster + services (~10-15 minutes)
```

Then verify:

```bash
make test-k8s       # Check Kubernetes cluster state
make test-services  # Verify Gitea, Nexus, NFS availability
```

## Available Make Targets

```bash
make help              # Show all targets

# VM Management
make up                # Start all VMs and deploy cluster + services
make down              # Stop all VMs (power off, keep state)
make clean             # Destroy all VMs completely
make status            # Show VM status

# Deployment
make rerun             # Re-run Ansible playbook without VM changes
make deploy            # Shortcut for 'up && rerun'

# SSH Access
make ssh-master        # SSH into master node
make ssh-worker1       # SSH into worker1 node
make ssh-worker2       # SSH into worker2 node
make ssh-tools         # SSH into tools VM

# Diagnostics & Testing
make test-connectivity # Ping all nodes from tools VM
make test-services     # Check Gitea, Nexus, NFS reachability
make test-k8s          # Verify Kubernetes cluster health

# Logs
make logs-gitea        # Show Gitea container logs
make logs-nexus        # Show Nexus container logs
make logs-docker       # Show all Docker container logs
```

## Manual Deployment (Vagrant + Ansible)

If you prefer not to use Make:

### 1) Start VMs

```bash
vagrant up
```

This provisionsall 4 VMs and installs basic dependencies.

### 2) Run Ansible playbook

SSH into tools VM:

```bash
vagrant ssh tools
cd /vagrant/ansible
ansible-playbook playbooks/site.yml
```

## Cluster Architecture

| Node | Hostname | IP | Role |
|------|----------|-----|------|
| VM 1 | master | 192.168.56.10 | Control Plane |  
| VM 2 | worker1 | 192.168.56.11 | Worker |
| VM 3 | worker2 | 192.168.56.12 | Worker |
| VM 4 | tools | 192.168.56.20 | DevOps Tools |

## Services & Access

All services run on the `tools` VM (`192.168.56.20`):

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Gitea** | 3000 | `http://192.168.56.20:3000` | Git repository server |
| **Nexus** | 8081 | `http://192.168.56.20:8081` | Package/artifact repository |
| **NFS** | 2049 | `nfs://192.168.56.20:/srv/nfs/share` | Persistent shared storage |
| **Docker** | 2375 | Via unix socket | Container runtime |

## Playbook Structure

Ansible playbooks are modular under `ansible/playbooks/cluster/`:

- **01-prepare.yml**: System prep (swap disable, kernel modules, containerd, kubelet)
- **02-init-master.yml**: Control plane initialization (kubeadm init, Flannel CNI)
- **03-join-workers.yml**: Worker node join (kubeadm join)
- **04-wait-ready.yml**: Wait for cluster readiness
- **05-tools-services.yml**: Tools VM setup (Docker, NFS, Gitea, Nexus)

`site.yml` orchestrates all 5 playbooks in sequence.

## Project Structure

```
.
├── Vagrantfile              # VM definitions (4 VMs with specs)
├── Makefile                 # One-command management targets
├── README.md                # This file
├── scripts/
│   ├── bootstrap.sh         # Base OS setup (all VMs)
│   └── setup-tools.sh       # Tools VM Ansible prep
├── ansible/
│   ├── ansible.cfg          # Ansible global config
│   ├── inventory.ini        # Static inventory with SSH keys
│   └── playbooks/
│       ├── site.yml         # Main orchestration playbook
│       └── cluster/
│           ├── 01-prepare.yml
│           ├── 02-init-master.yml
│           ├── 03-join-workers.yml
│           ├── 04-wait-ready.yml
│           └── 05-tools-services.yml
```

## Common Workflows

### Check cluster status

```bash
make test-k8s
# Shows: nodes, system pods, CNI status, cluster info
```

### SSH into a node

```bash
make ssh-master     # Control plane
make ssh-worker1    # Worker 1
make ssh-worker2    # Worker 2
make ssh-tools      # DevOps tools
```

Example from master:

```bash
vagrant ssh master
kubectl get nodes
kubectl get pods -A
```

### Mount NFS from a worker

```bash
vagrant ssh worker1
sudo apt-get install nfs-common
sudo mkdir -p /mnt/nfs
sudo mount -t nfs 192.168.56.20:/srv/nfs/share /mnt/nfs
ls -la /mnt/nfs  # Shared storage accessible
```

### Access Gitea

1. Open browser: `http://192.168.56.20:3000`
2. Create admin user on first login
3. Create repositories, push code

### Access Nexus

1. Open browser: `http://192.168.56.20:8081`
2. Default login: `admin` / check logs for password: `make logs-nexus`
3. Configure repositories and proxy external registries

### Redeploy just services

```bash
vagrant ssh tools
cd /vagrant/ansible
ansible-playbook playbooks/cluster/05-tools-services.yml
```

## Customization

### Change VM specs (CPU, memory, count)

Edit `Vagrantfile`:

```ruby
nodes = [
  { name: "master", role: "master", ip: "192.168.56.10", cpus: 2, memory: 3072 },
  # Adjust cpus, memory as needed
]
```

Then: `vagrant destroy -f && vagrant up`

### Change Kubernetes version

Edit `ansible/playbooks/cluster/02-init-master.yml`:

```yaml
- name: Initialize Kubernetes cluster
  ansible.builtin.command: >-
    kubeadm init --kubernetes-version=v1.29.15  # Change version
    ...
```

### Change CNI plugin

Edit `ansible/playbooks/cluster/02-init-master.yml` to use a different CNI instead of Flannel (Calico, Cilium, etc.).

## Troubleshooting

### VMs won't start

```bash
# Check VirtualBox
vboxmanage list vms

# Verify Vagrant state
vagrant status

# Recreate everything
vagrant destroy -f
vagrant up
```

### Ansible connectivity issues

```bash
# Test connectivity
make test-connectivity

# Or manually:
vagrant ssh tools -c "cd /vagrant/ansible && ansible all -m ping"
```

### Kubernetes nodes stuck in NotReady

```bash
# Check node conditions
vagrant ssh master -c "kubectl describe node worker1"

# Check CNI pod status
vagrant ssh master -c "kubectl get pods -n kube-flannel"

# Check kubelet logs (on the worker)
vagrant ssh worker1 -c "sudo journalctl -u kubelet -f"
```

### Services not reachable

```bash
# Check containers on tools
vagrant ssh tools -c "docker ps"

# Check logs
make logs-gitea
make logs-nexus

# Test ports
make test-services
```

## Performance Notes

- Initial `vagrant up` takes ~5 minutes (VM creation + provisioning)
- First Ansible playbook run takes ~10-15 minutes (package downloads, Nexus startup)
- Subsequent runs are faster (idempotent)
- Nexus startup can take 60+ seconds; use `docker logs nexus` if uncertain

## Security Warnings

⚠️ **This is a lab environment, NOT production-ready:**

- SSH key checking disabled in Ansible (convenience for lab)
- Nexus/Gitea have default/weak credentials (change in production)
- NFS exported with `no_root_squash` (only for lab)
- No RBAC or network policies enforced
- All VMs on same private network with full cross-access

For production, add:
- TLS certificates
- Proper authentication/RBAC
- Network segmentation
- Persistent data backup
- Monitoring and logging

## Requirements

### Host Machine

- **OS**: Linux, macOS, or Windows (with WSL2)
- **VirtualBox**: 6.1+ (with Extension Pack recommended)
- **Vagrant**: 2.3+
- **RAM**: 16GB minimum (8GB for VMs + system overhead)
- **Disk**: ~30GB free space
- **CPU**: 4 cores minimum (2 for VMs + overhead)

### Network

- Internet connection (to download VM box and Docker images)
- Private network `192.168.56.0/24` available (VirtualBox reserved range)

## Contributing

This is a personal lab project. Feel free to fork, modify, and extend!

## License

MIT — use freely for learning and experimentation.

## Quick Reference

```bash
# Full workflow
make up                    # Deploy everything
make test-k8s              # Verify K8s
make test-services         # Verify services
make ssh-master            # Access cluster
kubectl get nodes          # List nodes
```

---

**Questions?** Check logs with `make logs-*` or inspect playbooks in `ansible/playbooks/cluster/`.

