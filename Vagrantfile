# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.define "build" do |box|
  	#box.vm.box = "bento/centos-6.9"
  	box.vm.box = "generic/centos6"
  	box.vm.synced_folder ".", "/home/vagrant/build"
  	box.vm.synced_folder "./gina_builds", "/opt/gina/"
  end

  config.vm.define "test" do |box|
        #box.vm.box = "centos/8"
        box.vm.box = "generic/centos8"
        box.vm.synced_folder ".", "/home/vagrant/build"
        box.vm.synced_folder "./gina_test_builds", "/opt/gina/"
  end

end
