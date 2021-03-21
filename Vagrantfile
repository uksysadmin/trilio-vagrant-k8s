# -*- mode: ruby -*-
# vi: set ft=ruby :

# Nodes:
#  master-01    192.168.100.100
#  worker-01    192.168.100.101

# Interfaces
# eth0 - nat (used by VMware/VirtualBox)
# eth1 - host / API 192.168.100.0/24

nodes = {
    'worker' => [1, 101],
    'master'  => [1, 100],
}

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
  else
    raise "[-] ERROR: Please add vagrant-hostmanager plugin:  vagrant plugin install vagrant-hostmanager"
  end


  # Defaults (VirtualBox)
  config.vm.box = "bento/ubuntu-20.04"
  # config.vm.synced_folder ".", "/vagrant", type: "nfs"

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on the "Usage" link above
    config.cache.scope = :box

    # OPTIONAL: If you are using VirtualBox, you might want to use that to enable
    # NFS for shared folders. This is also very useful for vagrant-libvirt if you
    # want bi-directional sync
    config.cache.synced_folder_opts = {
      # type: :nfs,
      # The nolock option can be useful for an NFSv3 client that wants to avoid the
      # NLM sideband protocol. Without this option, apt-get might hang if it tries
      # to lock files needed for /var/cache/* operations. All of this can be avoided
      # by using NFSv4 everywhere. Please note that the tcp option is not the default.
      owner: "_apt",
      group: "_apt",
      # mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end

  if config.vm.provider :vmware_workstation
    # If we're running VMware Workstation (i.e. Linux)
    if Vagrant.has_plugin?("vagrant-triggers")
      config.trigger.before :up do
        puts "[+] INFO: Ensuring /dev/vmnet* are correct to allow promiscuous mode."
        puts "[+]       Needed for access to containers on different VMs."
        run "./fix_vmnet.sh"
      end
    else
      puts "[-] You do not have vagrant-triggers installed so Vagrant is unable"
      puts "[-] to set the correct permissions for promiscuous mode to function"
      puts "[-] on VMware Workstation based environments"
      puts "[-]"
      puts "[-] Install using: vagrant plugin install vagrant-triggers"
      puts "[-]"
      puts "[-] Please ensure /dev/vmnet* is group owned and writeable by you"
      puts "[-]          sudo chmod chgrp <gid> /dev/vmnet*"
      puts "[-]          sudo chmod g+rw /dev/vmnet*"
    end
  end

  # VMware Fusion / Workstation
  config.vm.provider :vmware_fusion or config.vm.provider :vmware_workstation do |vmware, override|
    override.vm.box = "bento/ubuntu-20.04"
    override.vm.synced_folder ".", "/vagrant", type: "nfs"

    # Fusion Performance Hacks
    vmware.vmx["logging"] = "FALSE"
    vmware.vmx["MemTrimRate"] = "0"
    vmware.vmx["MemAllowAutoScaleDown"] = "FALSE"
    vmware.vmx["mainMem.backing"] = "swap"
    vmware.vmx["sched.mem.pshare.enable"] = "FALSE"
    vmware.vmx["snapshot.disabled"] = "TRUE"
    vmware.vmx["isolation.tools.unity.disable"] = "TRUE"
    vmware.vmx["unity.allowCompostingInGuest"] = "FALSE"
    vmware.vmx["unity.enableLaunchMenu"] = "FALSE"
    vmware.vmx["unity.showBadges"] = "FALSE"
    vmware.vmx["unity.showBorders"] = "FALSE"
    vmware.vmx["unity.wasCapable"] = "FALSE"
    vmware.vmx["vhv.enable"] = "TRUE"
  end

  #Default is 2200..something, but port 2200 is used by forescout NAC agent.
  config.vm.usable_port_range = 2800..2900

  config.vm.graceful_halt_timeout = 120

  nodes.each do |prefix, (count, ip_start)|
    count.times do |i|
      if prefix == "master" or prefix == "worker"
        hostname = "%s-%02d" % [prefix, (i+1)]
      else
        hostname = "%s" % [prefix, (i+1)]
      end

      config.ssh.insert_key = false

      config.vm.define "#{hostname}" do |box|
        box.vm.hostname = "#{hostname}"
        # box.vm.network :private_network, ip: "172.29.236.#{ip_start+i}", :netmask => "255.255.255.0"
      	box.vm.network :private_network, ip: "192.168.100.#{ip_start+i}", :netmask => "255.255.255.0"

        # If using VMware Fusion
        box.vm.provider "vmware_fusion" do |v|
          v.linked_clone = true if Vagrant::VERSION =~ /^1.8/
          v.vmx["memsize"] = 1024
          if prefix == "master"
            v.vmx["memsize"] = 4096
            v.vmx["numvcpus"] = "2"
          end
          if prefix == "worker"
            v.vmx["memsize"] = 4096
            v.vmx["numvcpus"] = "2"
            v.vmx["vhv.enable"] = "TRUE"
          end
        end

        # If using VMware Workstation
        box.vm.provider "vmware_workstation" do |v|
          v.linked_clone = true if Vagrant::VERSION =~ /^1.8/
          v.vmx["memsize"] = 1024
          if prefix == "master"
            v.vmx["memsize"] = 4096
            v.vmx["numvcpus"] = "2"
          end
          if prefix == "worker"
            v.vmx["memsize"] = 4096
            v.vmx["numvcpus"] = "2"
            v.vmx["vhv.enable"] = "TRUE"
          end
        end

        # Otherwise using VirtualBox
        box.vm.provider :virtualbox do |vbox|
          vbox.name = "#{hostname}"
          # Defaults
          vbox.linked_clone = true if Vagrant::VERSION =~ /^1.8/
          vbox.customize ["modifyvm", :id, "--memory", 1024]
          vbox.customize ["modifyvm", :id, "--cpus", 1]
          if prefix == "master"
            vbox.customize ["modifyvm", :id, "--memory", 4096]
            vbox.customize ["modifyvm", :id, "--cpus", 2]
          end
          if prefix == "worker"
            vbox.customize ["modifyvm", :id, "--memory", 4096]
            vbox.customize ["modifyvm", :id, "--cpus", 2]
          end
          vbox.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nicpromisc4", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nicpromisc5", "allow-all"]
        end


	# Run Scripts (All Hosts)
	box.vm.provision :shell, :path => "install-k8s.sh"

	# Master runs last so run the extra script to init kube service
	if hostname == "master-01"
	  box.vm.provision :shell, :path => "setup-k8s-master.sh"
	end
	
	
      end
    end
  end
end
