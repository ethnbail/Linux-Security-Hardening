# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "hardening-lab"
  config.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -y
    apt-get install -y python3 ansible
    echo "Lab VM ready."
  SHELL
end
