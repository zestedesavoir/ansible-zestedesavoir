Vagrant.require_version ">= 1.7.0"

Vagrant.configure(2) do |config|
  config.vm.box = "generic/debian13"

  config.vm.define 'zds-site' do |zds|
    zds.vm.network "forwarded_port", guest: 80, host: 8080

    zds.vm.provision "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.verbose = "v"
      ansible.playbook = "playbook-zds.yml"
      ansible.groups = {
        "test" => ["zds-site"],
        "zds:children" => ["test"]
      }
      ansible.vault_password_file = "./vault-secret"
    end
  end

  config.vm.define 'matomo' do |matomo|
    matomo.vm.network "forwarded_port", guest: 80, host: 8081

    matomo.vm.provision "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.verbose = "v"
      ansible.playbook = "playbook-matomo.yml"
      ansible.groups = {
        "test_matomo" => ["matomo"],
        "matomo:children" => ["test_matomo"]
      }
      ansible.vault_password_file = "./vault-secret"
    end
  end
end
