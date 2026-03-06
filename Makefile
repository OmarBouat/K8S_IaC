.PHONY: help up down status clean rerun \
        ssh-master ssh-worker1 ssh-worker2 ssh-tools \
        logs-gitea logs-nexus logs-docker \
        test-connectivity test-services test-k8s

ANSIBLE_DIR := ansible
PLAYBOOK := playbooks/site.yml

help:
	@echo "Kubernetes Lab with Vagrant + Ansible"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "VM Management:"
	@echo "  up              - Start all VMs and deploy cluster + services"
	@echo "  down            - Stop all VMs (power off, keep state)"

	@echo "  clean           - Destroy all VMs completely"
	@echo "  status          - Show VM status"
	@echo ""
	@echo "Deployment:"
	@echo "  rerun           - Re-run Ansible playbook without VM changes"
	@echo "  deploy          - Shortcut for 'up && rerun'"
	@echo ""
	@echo "SSH Access:"
	@echo "  ssh-master      - SSH into master node"
	@echo "  ssh-worker1     - SSH into worker1 node"
	@echo "  ssh-worker2     - SSH into worker2 node"
	@echo "  ssh-tools       - SSH into tools VM"
	@echo ""
	@echo "Service Management:"
	@echo "  test-connectivity - Ping all nodes from tools VM"
	@echo "  test-services   - Check Gitea, Nexus, NFS availability"
	@echo "  test-k8s        - Check Kubernetes cluster state"
	@echo "  logs-gitea      - Show Gitea container logs"
	@echo "  logs-nexus      - Show Nexus container logs"
	@echo "  logs-docker     - Show all Docker container logs"
	@echo ""

up:
	@echo "Starting VMs..."
	vagrant up
	@echo ""
	@echo "Running Ansible playbook..."
	vagrant ssh tools -c "cd /vagrant/$(ANSIBLE_DIR) && ansible-playbook $(PLAYBOOK)"
	@echo ""
	@echo "✓ Deployment complete!"

down:
	@echo "Stopping VMs..."
	vagrant halt

clean:
	@echo "Destroying VMs..."
	vagrant destroy -f
	@echo "✓ All VMs destroyed"

status:
	@echo "VM Status:"
	@vagrant status

rerun:
	@echo "Running Ansible playbook..."
	vagrant ssh tools -c "cd /vagrant/$(ANSIBLE_DIR) && ansible-playbook $(PLAYBOOK)"

deploy: up

ssh-master:
	vagrant ssh master

ssh-worker1:
	vagrant ssh worker1

ssh-worker2:
	vagrant ssh worker2

ssh-tools:
	vagrant ssh tools

test-connectivity:
	@echo "Testing connectivity to all cluster nodes..."
	vagrant ssh tools -c "cd /vagrant/$(ANSIBLE_DIR) && ansible all -m ping"

test-services:
	@echo "Testing service availability..."
	@echo ""
	@echo "Gitea (port 3000):"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/3000' && echo '✓ Gitea is reachable' || echo '✗ Gitea is NOT reachable'"
	@echo ""
	@echo "Nexus (port 8081):"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/8081' && echo '✓ Nexus is reachable' || echo '✗ Nexus is NOT reachable'"
	@echo ""
	@echo "NFS (port 2049):"
	vagrant ssh tools -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/192.168.56.20/2049' && echo '✓ NFS is reachable' || echo '✗ NFS is NOT reachable'"

test-k8s:
	@echo "Kubernetes Cluster Status:"
	@echo ""
	@echo "Nodes:"
	vagrant ssh master -c "kubectl get nodes -o wide"
	@echo ""
	@echo "System Pods:"
	vagrant ssh master -c "kubectl get pods -n kube-system -o wide"
	@echo ""
	@echo "Node Details:"
	vagrant ssh master -c "kubectl describe nodes | grep -A 2 'Conditions:' | head -15"
	@echo ""
	@echo "Cluster Info:"
	vagrant ssh master -c "kubectl cluster-info"
	@echo ""
	@echo "Pod Networks (CNI):"
	vagrant ssh master -c "kubectl get pods -n kube-flannel -o wide"

logs-gitea:
	@echo "Gitea container logs:"
	vagrant ssh tools -c "docker logs gitea"

logs-nexus:
	@echo "Nexus container logs:"
	vagrant ssh tools -c "docker logs nexus"

logs-docker:
	@echo "All Docker containers:"
	vagrant ssh tools -c "docker ps -a"
	@echo ""
	@echo "Running containers logs:"
	vagrant ssh tools -c "docker logs -f $$(docker ps -q)"
