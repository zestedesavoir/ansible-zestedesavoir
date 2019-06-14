Ce dépôt contient tous les fichiers nécessaire au déploiement d'un serveur de production pour Zeste de Savoir (pour en savoir plus, voir [la documentation](https://docs.zestedesavoir.com) du projet et [le dépôt`zds-site`](https://github.com/zestedesavoir/zds-site)).

# Déployer une version de `zds-site` dans une machine virtuelle configurée comme un serveur de production

[Installer Vagrant à partir de leur site web](https://www.vagrantup.com/downloads.html)

Depuis une copie de `ansible-zestedesavoir` sur votre ordinateur :

Commande | Explication
---|---
`vagrant` | Afficher l'aide
`vagrant up` | Démarrer la machine virtuelle (et la construire si elle n'existe pas)
`vagrant halt` | Arrêter la machine virtuelle
`vagrant provision` | Lancer le *playbook* dans la machine virtuelle (avec la configuration `test`)
`vagrant ssh` | Ouvrir une connexion SSH avec la machine virtuelle
`vagrant destroy` | Supprimer la machine virtuelle

Vous pouvez accéder au site web sur `localhost:8080` (HTTP) ou `localhost:8443` (HTTPS).

# Déployer une version de `zds-site` sur un serveur de production

[Installer Ansible à partir de leur site web](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

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
