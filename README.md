Ce dépôt contient tous les fichiers nécessaire au déploiement d'un serveur de production pour Zeste de Savoir (pour en savoir plus, voir [la documentation](https://docs.zestedesavoir.com) du projet et [le dépôt`zds-site`](https://github.com/zestedesavoir/zds-site)).

# Déployer une version de `zds-site` dans une machine virtuelle configurée comme un serveur de production

[Installer Vagrant à partir de leur site web](https://www.vagrantup.com/downloads.html)

Dans une copie de `ansible-zestedesavoir` sur votre ordinateur :

- Afficher l'aide : `vagrant`
- Lancer une machine virtuelle (installe l'OS et lance le *playbook* la première fois, ça prend du temps) : `vagrant up`
- Se connecter en SSH à la machine virtuelle : `vagrant ssh`
- Lancer le *playbook* : `vagrant provision`
- Arrêter la machine virtuelle : `vagrant halt`
- Supprimer la machine virtuelle : `vagrant destroy`

Vous pouvez accéder au site web sur `localhost:8080` ou `localhost:8443`.

# Déployer une version de `zds-site` sur un serveur de production

- (local) = une copie de `ansible-zestedesavoir` sur votre ordinateur
- (distant) = une connexion SSH avec le serveur de production
- ENV = "beta" ou "production"
- `appversion` = un tag (ex, "v27.1") ou une branche (ex, "release_v28") ou une PR (ex, "pull/5158/head" pour la PR 5158)

1. (local) Mettre à jour avec `git fetch`
2. (local) Modifier `appversion` dans `group_vars/ENV/vars.yml` avec la version de `zds-site` que vous voulez déployer
3. (local) Commiter les modifications et les envoyer avec `git commit` puis `git push`
4. (local) *S'il s'agit d'une simple mise à jour et pas d'une installation complète*, vous pouvez vous permettre de modifier le `playbook.yml` comme décrit un peu plus bas
6. (local) **Attention, prenez plusieurs paires de gants avant de lancer cette commande !** Déployer la nouvelle version avec `ansible-playbook playbook.yml --limit ENV --vault-password-file=vault-secret --ask-become-pass`
8. Vérifier que le serveur fonctionne bien et siroter un diabolo

Modifications à apporter au `playbook.yml` pour une simple mise à jour (c'est temporaire, dans le futur il y aura deux *playbooks* distincts) :

```yaml
- hosts: app
  become: true
  roles:
    #- common
    #- elasticsearch
    #- mysql
    #- web
    - app
    #- latex
    - zmd
```
