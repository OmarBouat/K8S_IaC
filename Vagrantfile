Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_check_update = false

  nodes = [
    { name: "master", role: "master", ip: "192.168.56.10", cpus: 2, memory: 3072 },
    { name: "worker1", role: "worker", ip: "192.168.56.11", cpus: 2, memory: 2048 },
    { name: "worker2", role: "worker", ip: "192.168.56.12", cpus: 2, memory: 2048 },
    { name: "tools", role: "tools", ip: "192.168.56.20", cpus: 2, memory: 2048 }
  ]

  nodes.each do |node|
    config.vm.define node[:name] do |machine|
      machine.vm.hostname = node[:name]
      machine.vm.network "private_network", ip: node[:ip]

      machine.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-#{node[:name]}"
        vb.gui = false
        vb.cpus = node[:cpus]
        vb.memory = node[:memory]
      end

      machine.vm.provision "shell", path: "scripts/bootstrap.sh", args: [node[:name], node[:ip]]

      if node[:role] == "tools"
        machine.vm.provision "shell", path: "scripts/setup-tools.sh"
      end
    end
  end
end
