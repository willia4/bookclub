# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  vagrant_root = File.dirname(__FILE__)

  config.vm.define "bookclub_local" do |node|
    node.vm.box = "ubuntu/trusty32"
    node.vm.network "forwarded_port", guest: 80, host: 8080

    node.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision/bookclub.ansible.yml"
      ansible.extra_vars = {
        ubuntu_version: "trusty",
        provision_path: vagrant_root + "/provision"
      }
    end
  end

  


end