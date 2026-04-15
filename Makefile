.PHONY: help up down status clean rerun deploy \
	docker-build docker-up docker-down docker-ps \
	frontend-build frontend-deploy frontend-logs frontend-health \
        ssh-master ssh-worker1 ssh-worker2 ssh-tools \
	logs-gitea logs-nexus logs-jenkins logs-docker \
	test-connectivity test-services test-k8s test-nfs-mounts

ANSIBLE_DIR := ansible
PLAYBOOK := playbooks/site.yml

help:
	@echo "Kubernetes Lab — Vagrant + Ansible"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "[VM lifecycle]"
	@echo "  up                Start all VMs and run full deployment"
	@echo "  down              Stop all VMs (keep current state)"
	@echo "  clean             Destroy all VMs and remove state"
	@echo "  status            Show VM power/status"
	@echo ""
	@echo "[Docker services on tools VM]"
	@echo "  docker-build      Build Jenkins, Gitea, and Nexus images from Dockerfiles"
	@echo "  docker-up         Start/update Jenkins, Gitea, and Nexus via docker compose"
	@echo "  docker-down       Stop and remove services from compose file"
	@echo "  docker-ps         Show docker compose service/container state"
	@echo ""
	@echo "[Frontend CI/CD demo app]"
	@echo "  frontend-build    Build frontend Docker image locally on tools VM"
	@echo "  frontend-deploy   Deploy/redeploy frontend container on tools VM"
	@echo "  frontend-health   Check frontend health endpoint"
	@echo "  frontend-logs     Show frontend container logs"
	@echo ""
	@echo "[Deployment]"
	@echo "  rerun             Re-run Ansible playbook only"
	@echo "  deploy            Alias of up"
	@echo ""
	@echo "[SSH access]"
	@echo "  ssh-master        SSH into master node"
	@echo "  ssh-worker1       SSH into worker1 node"
	@echo "  ssh-worker2       SSH into worker2 node"
	@echo "  ssh-tools         SSH into tools node"
	@echo ""
	@echo "[Checks and logs]"
	@echo "  test-connectivity Ping all inventory hosts via Ansible"
	@echo "  test-services     Check Jenkins, Gitea, Nexus, frontend, and NFS ports"
	@echo "  test-k8s          Show Kubernetes cluster health"
	@echo "  test-nfs-mounts   Verify NFS mounts and fstab on cluster nodes"
	@echo "  logs-jenkins      Show Jenkins container logs"
	@echo "  logs-gitea        Show Gitea container logs"
	@echo "  logs-nexus        Show Nexus container logs"
	@echo "  logs-docker       Show Docker containers and follow logs"
	@echo ""

up:
	@echo "==> Starting VMs"
	vagrant up
	@echo ""
	@echo "==> Running Ansible deployment"
	vagrant ssh tools -c "cd /vagrant/$(ANSIBLE_DIR) && ansible-playbook $(PLAYBOOK)"
	@echo ""
	@echo "✓ Cluster and services are ready"

down:
	@echo "==> Stopping all VMs"
	vagrant halt
	@echo "✓ VMs stopped"

clean:
	@echo "==> Destroying all VMs"
	vagrant destroy -f
	@echo "✓ Environment removed"

status:
	@echo "==> Current VM status"
	@vagrant status

rerun:
	@echo "==> Re-running Ansible deployment"
	vagrant ssh tools -c "cd /vagrant/$(ANSIBLE_DIR) && ansible-playbook $(PLAYBOOK)"
	@echo "✓ Playbook run completed"

deploy: up

docker-build:
	@echo "==> Building Docker images from Dockerfiles"
	vagrant ssh tools -c "cd /vagrant/docker && if docker compose version >/dev/null 2>&1; then docker compose -f docker-compose.tools.yml build; else docker-compose -f docker-compose.tools.yml build; fi"
	@echo "✓ Docker images built"

docker-up:
	@echo "==> Starting Docker services from compose file"
	vagrant ssh tools -c "cd /vagrant/docker && if docker compose version >/dev/null 2>&1; then docker compose -f docker-compose.tools.yml up -d --build; else docker-compose -f docker-compose.tools.yml up -d --build; fi"
	@echo "✓ Docker services running"

docker-down:
	@echo "==> Stopping Docker services from compose file"
	vagrant ssh tools -c "cd /vagrant/docker && if docker compose version >/dev/null 2>&1; then docker compose -f docker-compose.tools.yml down; else docker-compose -f docker-compose.tools.yml down; fi"
	@echo "✓ Docker services stopped"

docker-ps:
	@echo "==> Docker compose service status"
	vagrant ssh tools -c "cd /vagrant/docker && if docker compose version >/dev/null 2>&1; then docker compose -f docker-compose.tools.yml ps; else docker-compose -f docker-compose.tools.yml ps; fi"

frontend-build:
	@echo "==> Building frontend image"
	vagrant ssh tools -c "cd /vagrant && if [ -f Dockerfile ]; then docker build -t k8s-lab/frontend:latest .; elif [ -f frontend/Dockerfile ]; then docker build -t k8s-lab/frontend:latest frontend; else echo 'No frontend Dockerfile found at /vagrant or /vagrant/frontend' >&2; exit 1; fi"
	@echo "✓ Frontend image built"

frontend-deploy:
	@echo "==> Deploying frontend container"
	vagrant ssh tools -c "docker rm -f frontend-web 2>/dev/null || true && docker run -d --name frontend-web --restart unless-stopped -p 8090:80 k8s-lab/frontend:latest"
	@echo "✓ Frontend deployed at http://192.168.56.20:8090"

frontend-health:
	@echo "==> Checking frontend health"
	vagrant ssh tools -c "curl -fsS http://127.0.0.1:8090/health && echo '' && echo '✓ Frontend is healthy'"

frontend-logs:
	@echo "==> Frontend container logs"
	vagrant ssh tools -c "docker logs frontend-web"

ssh-master:
	vagrant ssh master

ssh-worker1:
	vagrant ssh worker1

ssh-worker2:
	vagrant ssh worker2

ssh-tools:
	vagrant ssh tools

test-connectivity:
	@echo "==> Testing Ansible connectivity to all nodes"
	vagrant ssh tools -c "cd /vagrant/$(ANSIBLE_DIR) && ansible all -m ping"
	@echo "✓ Connectivity test completed"

test-services:
	@echo "==> Testing service ports on tools node"
	@echo ""
	@echo "[Jenkins] port 8080"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/8080' && echo '✓ Jenkins is reachable' || echo '✗ Jenkins is NOT reachable'"
	@echo ""
	@echo "[Gitea] port 3000"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/3000' && echo '✓ Gitea is reachable' || echo '✗ Gitea is NOT reachable'"
	@echo ""
	@echo "[Nexus] port 8081"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/8081' && echo '✓ Nexus is reachable' || echo '✗ Nexus is NOT reachable'"
	@echo ""
	@echo "[Nexus Docker Registry] port 8082"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/8082' && echo '✓ Nexus Docker registry is reachable' || echo '✗ Nexus Docker registry is NOT reachable'"
	@echo ""
	@echo "[Frontend] port 8090"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/8090' && echo '✓ Frontend is reachable' || echo '✗ Frontend is NOT reachable (deploy once via Jenkins or make frontend-deploy)'"
	@echo ""
	@echo "[NFS] port 2049"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/2049' && echo '✓ NFS is reachable' || echo '✗ NFS is NOT reachable'"
	@echo "✓ Service checks completed"

test-k8s:
	@echo "==> Kubernetes cluster report"
	@echo ""
	@echo "[Nodes]"
	vagrant ssh master -c "kubectl get nodes -o wide"
	@echo ""
	@echo "[System pods]"
	vagrant ssh master -c "kubectl get pods -n kube-system -o wide"
	@echo ""
	@echo "[Node conditions snapshot]"
	vagrant ssh master -c "kubectl describe nodes | grep -A 2 'Conditions:' | head -15"
	@echo ""
	@echo "[Cluster info]"
	vagrant ssh master -c "kubectl cluster-info"
	@echo ""
	@echo "[CNI pods]"
	vagrant ssh master -c "kubectl get pods -n kube-flannel -o wide"
	@echo "✓ Kubernetes report completed"

test-nfs-mounts:
	@echo "==> Checking NFS mount state on cluster nodes"
	@echo ""
	@echo "[master]"
	vagrant ssh master -c "mount | grep '/mnt/nfs ' && grep '/mnt/nfs' /etc/fstab"
	@echo ""
	@echo "[worker1]"
	vagrant ssh worker1 -c "mount | grep '/mnt/nfs ' && grep '/mnt/nfs' /etc/fstab"
	@echo ""
	@echo "[worker2]"
	vagrant ssh worker2 -c "mount | grep '/mnt/nfs ' && grep '/mnt/nfs' /etc/fstab"
	@echo "✓ NFS mount checks completed"

logs-gitea:
	@echo "==> Gitea container logs"
	vagrant ssh tools -c "docker logs gitea"

logs-nexus:
	@echo "==> Nexus container logs"
	vagrant ssh tools -c "docker logs nexus"

logs-jenkins:
	@echo "==> Jenkins container logs"
	vagrant ssh tools -c "docker logs jenkins"

logs-docker:
	@echo "==> Docker containers"
	vagrant ssh tools -c "docker ps -a"
	@echo ""
	@echo "==> Streaming logs from running containers"
	vagrant ssh tools -c "docker logs -f $$(docker ps -q)"
