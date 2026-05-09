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

A complete, production-ready infrastructure-as-code setup that creates a **4-node Kubernetes cluster** (1 control-plane, 2 workers) plus a dedicated tools VM with **Gitea**, **Nexus**, and **NFS**, while **Jenkins runs on Kubernetes** as the primary CI/CD server.

## Features

- **4 HeadlessUbuntu Server VMs** on VirtualBox with private networking
- **Kubernetes v1.29** with containerd and Flannel CNI
- **Docker Engine** on tools VM for containerized services
- **Dockerfiles + Compose** for Gitea/Nexus image and runtime definitions
- **Jenkins**: CI/CD automation server running in Kubernetes
- **Full-stack Jenkins pipeline** to auto-build and redeploy frontend/backend containers on code changes
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
make test-services  # Verify Jenkins readiness, Gitea, Nexus, frontend, and NFS availability
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

# Docker Services (tools VM)
make docker-build      # Build Gitea/Nexus images from docker/*/Dockerfile
make docker-up         # Start/update services via docker compose
make docker-down       # Stop/remove services defined in compose
make docker-ps         # Show compose service status

# Kubernetes app stack (Jenkins + frontend)
make k8s-network-deploy  # Install ingress-nginx + MetalLB with stable LoadBalancer IP
make k8s-network-status  # Show ingress and MetalLB state
make k8s-network-delete  # Remove network stack
make k8s-tools-deploy  # Apply Kubernetes manifests under k8s/devops-stack
make k8s-tools-status  # Show status in namespace devops-tools
make k8s-tools-delete  # Remove the Kubernetes app stack

# SSH Access
make ssh-master        # SSH into master node
make ssh-worker1       # SSH into worker1 node
make ssh-worker2       # SSH into worker2 node
make ssh-tools         # SSH into tools VM

# Diagnostics & Testing
make test-connectivity # Ping all nodes from tools VM
make test-services     # Check Jenkins readiness plus Gitea, Nexus, frontend, and NFS reachability
make test-k8s          # Verify Kubernetes cluster health

# Logs
make logs-jenkins      # Show Jenkins pod logs
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

Docker services are defined in source-controlled files under `docker/` and are deployed with:

```bash
make docker-up
```

## Deploy DevOps Stack On Kubernetes

This repo includes Kubernetes manifests for running the full-stack web app and tools stack on your cluster:

- Jenkins
- Frontend app
- Backend API
- PostgreSQL database

Manifests location:

- `k8s/devops-stack/00-namespace.yaml`
- `k8s/devops-stack/01-storage.yaml`
- `k8s/devops-stack/02-apps.yaml`
- `k8s/devops-stack/03-database.yaml`
- `k8s/devops-stack/04-backend.yaml`

The stack uses NFS-backed persistent storage from `192.168.56.20:/srv/nfs/share`.

Deploy:

```bash
make k8s-tools-deploy
make k8s-tools-status
```

Remove:

```bash
make k8s-tools-delete
```

Stable full-stack endpoint (recommended):

- `http://frontend.192.168.56.240.nip.io`, `http://backend.192.168.56.240.nip.io`, and Jenkins at `http://192.168.56.240/jenkins` via ingress-nginx + MetalLB

## Cluster Architecture

| Node | Hostname | IP | Role |
|------|----------|-----|------|
| VM 1 | master | 192.168.56.10 | Control Plane |  
| VM 2 | worker1 | 192.168.56.11 | Worker |
| VM 3 | worker2 | 192.168.56.12 | Worker |
| VM 4 | tools | 192.168.56.20 | DevOps Tools |

## Services & Access

Most shared services run on the `tools` VM (`192.168.56.20`); Jenkins runs on Kubernetes.

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Jenkins** | 8080 | `http://127.0.0.1:8080` via port-forward | CI/CD server (pipelines, agents, jobs) |
| **Gitea** | 3000 | `http://192.168.56.20:3000` | Git repository server |
| **Nexus** | 8081 | `http://192.168.56.20:8081` | Package/artifact repository |
| **Nexus Docker Registry** | 8082 | `http://192.168.56.20:8082` | Docker image registry |
| **Frontend** | 80 | `http://frontend.192.168.56.240.nip.io` | Kubernetes ingress endpoint |
| **Backend** | 80 | `http://backend.192.168.56.240.nip.io` | Kubernetes API ingress endpoint |
| **Jenkins** | 80 | `http://192.168.56.240/jenkins` | Kubernetes ingress endpoint |
| **NFS** | 2049 | `nfs://192.168.56.20:/srv/nfs/share` | Persistent shared storage |
| **Docker** | 2375 | `tcp://192.168.56.20:2375` | Tools VM Docker daemon used by Jenkins builds |

Kubernetes frontend (ingress):

- URL: `http://frontend.192.168.56.240.nip.io`
- Backend: `frontend` Service (`ClusterIP`) with multiple replicas
- Entry: `ingress-nginx-controller` Service (`LoadBalancer`) backed by MetalLB

Kubernetes backend (ingress):

- URL: `http://backend.192.168.56.240.nip.io`
- Paths: `/api` and `/health`
- Backend: `backend` Service (`ClusterIP`)



Jenkins builds use the Docker daemon on the tools VM instead of a Docker-in-Docker sidecar. The Jenkins pod points `DOCKER_HOST` at `tcp://192.168.56.20:2375`, while the tools VM Docker service is configured to keep the local Unix socket and expose the TCP listener for builds.

## Playbook Structure

Ansible playbooks are modular under `ansible/playbooks/cluster/`:

- **01-prepare.yml**: System prep (swap disable, kernel modules, containerd, kubelet)
- **02-init-master.yml**: Control plane initialization (kubeadm init, Flannel CNI)
- **03-join-workers.yml**: Worker node join (kubeadm join)
- **04-wait-ready.yml**: Wait for cluster readiness
- **05-tools-services.yml**: Tools VM setup (Docker, NFS, Gitea, Nexus)
- **06-nfs-clients.yml**: NFS client setup and mount on cluster nodes

`site.yml` orchestrates all 6 playbooks in sequence.

## Project Structure

```
.
├── Vagrantfile              # VM definitions (4 VMs with specs)
├── Makefile                 # One-command management targets
├── README.md                # This file
├── scripts/
│   ├── bootstrap.sh         # Base OS setup (all VMs)
│   └── setup-tools.sh       # Tools VM Ansible prep
├── docker/
│   ├── docker-compose.tools.yml  # Compose stack for Gitea + Nexus
│   ├── jenkins/
│   │   ├── Dockerfile
│   │   └── plugins.txt
│   ├── gitea/
│   │   └── Dockerfile
│   └── nexus/
│       └── Dockerfile
├── k8s/
│   └── devops-stack/
│       ├── 00-namespace.yaml
│       ├── 01-storage.yaml
│       └── 02-apps.yaml
├── ansible/
│   ├── ansible.cfg          # Ansible global config
│   ├── inventory.ini        # Static inventory using shared VM SSH key
│   └── playbooks/
│       ├── site.yml         # Main orchestration playbook
│       └── cluster/
│           ├── 01-prepare.yml
│           ├── 02-init-master.yml
│           ├── 03-join-workers.yml
│           ├── 04-wait-ready.yml
│           ├── 05-tools-services.yml
│           └── 06-nfs-clients.yml
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

All VMs are provisioned with one shared inter-VM SSH key, so the `vagrant` user can SSH between `master`, `worker1`, `worker2`, and `tools` without passwords.

Example from master:

```bash
vagrant ssh master
kubectl get nodes
kubectl get pods -A
```

### Mount NFS from a worker

```bash
vagrant ssh worker1
mount | grep /mnt/nfs
ls -la /mnt/nfs  # Shared storage accessible
```

NFS clients are automatically configured on cluster nodes (`master`, `worker1`, `worker2`) by Ansible, including persistent `/etc/fstab` mount entries.

### Access Gitea

1. Open browser: `http://192.168.56.20:3000`
2. Create admin user on first login
3. Create repositories, push code

### Access Nexus

1. Open browser: `http://192.168.56.20:8081`
2. Default login: `admin` / check logs for password: `make logs-nexus`
3. Configure repositories and proxy external registries

### Access Jenkins

1. Open browser: `http://192.168.56.240/jenkins`
2. Get the initial admin password: `make logs-jenkins`
3. Complete setup wizard and create your first pipeline job

## Full-Stack CI/CD with Jenkins

The Jenkins flow is centered on the full-stack web app and its Kubernetes deployment.

- frontend React app source and Dockerfile
- backend Express API source and Dockerfile
- `Jenkinsfile`: pipeline that builds/pushes images to Nexus and deploys the Kubernetes stack

### Pipeline behavior

On each detected commit/push in the app repository:

1. Checkout repository
2. Build frontend and backend container images
3. Push both images to Nexus registry
4. Apply or refresh Kubernetes manifests in `devops-tools`
5. Wait for rollout completion and run smoke tests against `/health` and `/api/users`

### Jenkins job setup

Create two Jenkins Pipeline jobs manually in the Jenkins UI. The Jenkins pod uses the custom image built from `docker/jenkins/Dockerfile`, which includes Docker CLI and `kubectl`.

Jobs to create:

1. `k8s-frontend`
  - Job type: **Pipeline**
  - Definition: **Pipeline script from SCM**
  - SCM: **Git**
  - Repository URL: `http://192.168.56.20:3000/OmarBouat/k8s-frontend.git`
  - Branch: `main`
  - Script Path: `Jenkinsfile`

2. `k8s-backend`
  - Job type: **Pipeline**
  - Definition: **Pipeline script from SCM**
  - SCM: **Git**
  - Repository URL: `http://192.168.56.20:3000/OmarBouat/k8s-backend.git`
  - Branch: `main`
  - Script Path: `Jenkinsfile`

### Auto-trigger from Gitea

Use either option:

- Preferred: add a Gitea webhook for each repo and point it to Jenkins.
- Fallback: SCM polling is already enabled in each Jenkinsfile (`pollSCM('H/5 * * * *')`).

Recommended webhook target in Jenkins:

- Frontend job: `http://192.168.56.240/jenkins/job/k8s-frontend/build?token=<token>`
- Backend job: `http://192.168.56.240/jenkins/job/k8s-backend/build?token=<token>`

> Note: If you prefer webhook-based triggering, create the jobs first, then add the webhook in each Gitea repo.
> The tools playbook also builds and pushes `192.168.56.20:8082/k8s-jenkins:latest` before the Kubernetes manifests are applied.

### Nexus Docker registry usage

1. Open Nexus UI: `http://192.168.56.20:8081`
2. The Ansible tools playbook creates the Docker hosted repository automatically on port `8082`
3. Log in from the tools VM or Jenkins with `docker login 192.168.56.20:8082`
4. Pull or push full-stack images using `192.168.56.20:8082/k8s-frontend:<tag>` and `192.168.56.20:8082/k8s-backend:<tag>`

> Note: Nexus remains available on the tools VM for artifacts, while frontend runtime deployment is Kubernetes-native.

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

### VM-to-VM SSH asks for password

```bash
# Re-apply bootstrap and SSH setup on all VMs
vagrant provision

# Quick checks from any VM
ssh master hostname
ssh worker1 hostname
ssh worker2 hostname
ssh tools hostname
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

