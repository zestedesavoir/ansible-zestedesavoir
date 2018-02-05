Vagrant.require_version ">= 1.7.0"

Vagrant.configure(2) do |config|
  config.vm.box = "bento/debian-9.3"

  config.vm.define "prod"

  config.vm.provision "ansible" do |ansible|
    ansible.verbose = "v"
    ansible.playbook = "playbook.yml"
    ansible.groups = {
      "production" => ["prod"],
      "app:children" => ["production"]
    }
    ansible.vault_password_file = "./vault-secret"
  end
end
