# Déploiement d'une version de Zeste de Savoir

## Déployer sur un serveur distant

- `ENV` = "beta" ou "production"
- `TAG` = "bootstrap" (pour une installation complète) ou "upgrade" (pour une mise à jour)
- `appversion` = un tag (ex, "v27.1") ou une branche (ex, "release_v28") ou une PR (ex, "pull/5158/head" pour la PR 5158)

Depuis une copie de `ansible-zestedesavoir` sur votre ordinateur :

1. Mettre à jour `ansible-zestedesavoir` avec `git fetch`
2. Vérifier que vous êtes sur la bonne branche (`origin/master` la plupart du temps)
3. Modifier `appversion` dans `group_vars/ENV/vars.yml` avec la version de `zds-site` que vous voulez déployer
4. Créer un commit des modifications avec `git commit` et les envoyer sur Github avec `git push`
5. **Attention, un grand pouvoir implique de grandes responsabilités !**
    1. Vérifier votre choix pour `ENV`, `TAG` et `appversion`
    2. Lancer le *playbook* avec cette commande :
        - (version longue) `ansible-playbook playbook.yml --limit=ENV --tags=TAG --ask-become-pass --vault-password-file=vault-secret`
        - (version courte) `ansible-playbook playbook.yml -l ENV -t TAG -K --vault-password-file=vault-secret`
6. Vérifier que le serveur fonctionne bien et siroter un diabolo

## Déployer dans une machine virtuelle locale

Si vous souhaitez déployer Zeste de Savoir dans une machine virtuelle locale, il vous faut :

1. un logiciel de virtualisation tel que VirtualBox ;
2. le logiciel Vagrant pour interfacer le logiciel de virtualisation et Ansible.

[Installer Vagrant à partir de leur site web](https://www.vagrantup.com/downloads.html)

Voici les principales commandes à connaitre pour utiliser Vagrant :

Commande | Explication
---|---
`vagrant` | Afficher l'aide
`vagrant up` | Si la machine virtuelle n'existe pas : construire la machine, la démarrer et lancer le *playbook*. <br> Si la machine virtuelle existe déjà : simplement la démarrer.
`vagrant provision` | Lancer le *playbook* dans la machine virtuelle (avec la configuration `test`)
`vagrant ssh` | Ouvrir une connexion SSH avec la machine virtuelle
`vagrant halt` | Arrêter la machine virtuelle
`vagrant destroy` | Supprimer la machine virtuelle

### Première utilisation

À la racine du dépôt, lancez `vagrant up` et attendez une dizaine de minutes. Si la commande se termine sans erreur, alors vous pouvez accéder au site web sur `localhost:8080` (HTTP) ou `localhost:8443` (HTTPS). Si la commande s'est arrêtée avec une belle erreur toute rouge, alors il va falloir trouver le soucis et le corriger. Si tel est le cas, n'hésitez pas à demander de l'aide !

### Charger les données initiales

Si vous souhaitez charger les données initiales (utilisateurs, tutoriels, billets, sujets du forum, etc. factices), alors il faut se connecter au serveur avec `vagrant ssh` puis lancer ces commandes :

```bash
sudo -u zds bash
/opt/zds/virtualenv/bin/pip3 install -r /opt/zds/app/requirements-dev.txt
/opt/zds/wrapper loaddata /opt/zds/app/fixtures/*.yaml
/opt/zds/wrapper load_factory_data fixtures/advanced/aide_tuto_media.yaml
/opt/zds/wrapper load_fixtures --size=low --all
```

### Lancer le *playbook* avec un tag

Si vous souhaitez lancer l'équivalent de `ansible-playbook --tags=upgrade`, il est nécessaire d'ajouter cette ligne au bloc `config.vm.provision "ansible" do |ansible|` du fichier `Vagrantfile` :

```ruby
ansible.tags = "upgrade"
```
