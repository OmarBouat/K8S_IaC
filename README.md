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

A complete, production-ready infrastructure-as-code setup that creates a **4-node Kubernetes cluster** (1 control-plane, 2 workers) plus a dedicated tools VM with **Jenkins**, **Gitea**, **Nexus**, and **NFS** for a complete DevOps environment.

## Features

- **4 HeadlessUbuntu Server VMs** on VirtualBox with private networking
- **Kubernetes v1.29** with containerd and Flannel CNI
- **Docker Engine** on tools VM for containerized services
- **Dockerfiles + Compose** for Jenkins/Gitea/Nexus image and runtime definitions
- **Jenkins**: CI/CD automation server
- **Frontend-repo Jenkinsfile pipeline** to auto-build and redeploy frontend container on code changes
- Jenkins image includes the Docker CLI and host socket access for container builds
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

# Docker Services (tools VM)
make docker-build      # Build Jenkins/Gitea/Nexus images from docker/*/Dockerfile
make docker-up         # Start/update services via docker compose
make docker-down       # Stop/remove services defined in compose
make docker-ps         # Show compose service status

# Frontend Demo App
make frontend-build    # Build frontend image manually (optional)
make frontend-deploy   # Deploy frontend container manually (optional)
make frontend-health   # Check frontend health endpoint
make frontend-logs     # Show frontend container logs

# SSH Access
make ssh-master        # SSH into master node
make ssh-worker1       # SSH into worker1 node
make ssh-worker2       # SSH into worker2 node
make ssh-tools         # SSH into tools VM

# Diagnostics & Testing
make test-connectivity # Ping all nodes from tools VM
make test-services     # Check Jenkins, Gitea, Nexus, frontend, NFS reachability
make test-k8s          # Verify Kubernetes cluster health

# Logs
make logs-jenkins      # Show Jenkins container logs
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
| **Jenkins** | 8080 | `http://192.168.56.20:8080` | CI/CD server (pipelines, agents, jobs) |
| **Gitea** | 3000 | `http://192.168.56.20:3000` | Git repository server |
| **Nexus** | 8081 | `http://192.168.56.20:8081` | Package/artifact repository |
| **Nexus Docker Registry** | 8082 | `http://192.168.56.20:8082` | Docker image registry |
| **Frontend Demo** | 8090 | `http://192.168.56.20:8090` | Auto-redeployed demo website |
| **NFS** | 2049 | `nfs://192.168.56.20:/srv/nfs/share` | Persistent shared storage |
| **Docker** | 2375 | Via unix socket | Container runtime |

## Playbook Structure

Ansible playbooks are modular under `ansible/playbooks/cluster/`:

- **01-prepare.yml**: System prep (swap disable, kernel modules, containerd, kubelet)
- **02-init-master.yml**: Control plane initialization (kubeadm init, Flannel CNI)
- **03-join-workers.yml**: Worker node join (kubeadm join)
- **04-wait-ready.yml**: Wait for cluster readiness
- **05-tools-services.yml**: Tools VM setup (Docker, NFS, Jenkins, Gitea, Nexus)
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
│   ├── docker-compose.tools.yml  # Compose stack for Jenkins + Gitea + Nexus
│   ├── jenkins/
│   │   ├── Dockerfile
│   │   └── plugins.txt
│   ├── gitea/
│   │   └── Dockerfile
│   └── nexus/
│       └── Dockerfile
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

1. Open browser: `http://192.168.56.20:8080`
2. Get the initial admin password: `make logs-jenkins`
3. Complete setup wizard and create your first pipeline job

## Frontend CI/CD with Jenkins (Local Gitea -> Nexus Docker Registry)

Frontend CI/CD is driven from the frontend application repository (`http://192.168.56.20:3000/OmarBouat/frontend-project.git`), which includes:

- app source files (`index.html`, `styles.css`, `app.js`, `nginx.conf`, `Dockerfile`)
- `Jenkinsfile`: pipeline that builds, pushes to Nexus, and redeploys container `frontend-web` on port `8090`

### Pipeline behavior

On each detected commit/push in the local Gitea repo:

1. Checkout repository
2. Build `k8s-lab/frontend:latest` and `k8s-lab/frontend:<short_sha>`
3. Push the image to Nexus as `192.168.56.20:8082/k8s-lab/frontend`
4. Replace the running `frontend-web` container with the Nexus image
5. Run a health check against `http://172.17.0.1:8090/health`

### Jenkins job setup (one-time)

1. In Jenkins, create a **Pipeline** job.
2. Choose **Pipeline script from SCM**.
3. SCM: **Git**
4. Repository URL: your local Gitea repository URL, for example `http://192.168.56.20:3000/<owner>/frontend.git`.
5. Script Path: `Jenkinsfile`
6. Save and run once.

### Auto-trigger from Gitea

Use either option:

- Preferred: add a Gitea webhook to Jenkins and point it at the job or use SCM polling.
- Fallback: polling is enabled in the frontend repo `Jenkinsfile` every ~2 minutes

> Note: If Jenkins is not reachable from Gitea, polling will still keep deployments automated.

### Nexus Docker registry usage

1. Open Nexus UI: `http://192.168.56.20:8081`
2. The Ansible tools playbook creates the Docker hosted repository automatically on port `8082`
3. Log in from the tools VM or Jenkins with `docker login 192.168.56.20:8082`
4. Pull or push frontend images using `192.168.56.20:8082/k8s-lab/frontend:<tag>`

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

