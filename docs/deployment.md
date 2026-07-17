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
        - (version longue) `ansible-playbook playbook-zds.yml --limit=ENV --tags=TAG --ask-become-pass --vault-password-file=vault-secret`
        - (version courte) `ansible-playbook playbook-zds.yml -l ENV -t TAG -K --vault-password-file=vault-secret`
6. Vérifier que le serveur fonctionne bien et siroter un diabolo

## Déployer en local

Si vous souhaitez déployer Zeste de Savoir en local, nous utilisons un
conteneur Docker. Il faut donc [installer
Docker](https://docs.docker.com/engine/install/debian/). Ensuite, nous
utilisons l'image
[`geerlingguy/docker-debian13-ansible`](https://hub.docker.com/r/geerlingguy/docker-debian13-ansible)
([sources](https://github.com/geerlingguy/docker-debian13-ansible)) qui utilise
SystemD, nécessaire pour avoir un environnement vraiment ressemblant au serveur
de production.

1. Création et démarrage d'un conteneur `ansible-zds` :
   ```sh
   docker run --detach --privileged --name ansible-matomo --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host -p 8080:80 geerlingguy/docker-debian13-ansible
   ```
2. Lancer le playbook Ansible :
   ```sh
   ansible-playbook -i inventory-local-zds.ini playbook-zds.yml
   ```
   Le site devrait alors être accessible depuis `localhost:8080`.
3. Obtenir un shell dans le conteneur :
   ```sh
   docker exec -it ansible-zds bash
   ```
4. Arrêter le conteneur :
   ```sh
   docker stop ansible-zds
   ```
5. Redémarrer le conteneur :
   ```sh
   docker start ansible-zds
   ```
6. Supprimer le conteneur :
   ```sh
   docker rm ansible-zds
   ```

### Charger les données initiales

**Les données initiales sont maintenant chargées automatiquement avec Ansible
lors d'un déploiement en local.**

Si vous souhaitez charger les données initiales (utilisateurs, tutoriels,
billets, sujets du forum, etc. factices), il faut obtenir un shell dans le
conteneur (`docker exec -it ansible-zds bash`) puis lancer ces commandes :

```bash
sudo -u zds bash
/opt/zds/virtualenv/bin/pip3 install -r /opt/zds/app/requirements-dev.txt
/opt/zds/wrapper loaddata /opt/zds/app/fixtures/*.yaml
/opt/zds/wrapper load_factory_data fixtures/advanced/aide_tuto_media.yaml
/opt/zds/wrapper load_fixtures --size=low --all
```
