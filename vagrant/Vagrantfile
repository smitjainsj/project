
Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"

   config.vm.network "forwarded_port", guest: 80, host: 81
   config.vm.network "forwarded_port", guest: 8080, host: 8081
   config.vm.network "private_network", ip: "192.168.33.51"
   config.vm.hostname = "test"

  config.vm.provider "virtualbox" do |vb|
     vb.memory = "2024"
   end
  
  config.vm.provision "shell" do |s|
     s.path = "provision.sh"
  end

end
