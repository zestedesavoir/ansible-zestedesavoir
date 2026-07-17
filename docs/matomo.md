# Matomo

Une instance [Matomo](https://matomo.org/) est également déployée sur le
serveur `matomo.zestedesavoir.com`.

Ce dépôt contient les scripts nécessaires pour :
- lancer un conteneur dédié à Matomo ;
- le playbook Ansible `playbook-matomo.yml` configure le conteneur pour arriver
    jusqu'à l'installation de Matomo depuis le navigateur.

```sh
docker run --detach --privileged --name ansible-matomo --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host -p 8081:80 geerlingguy/docker-debian13-ansible
ansible-playbook -i inventory-local-matomo.ini playbook-matomo.yml
```

Lorsque le déploiement est terminé, il est possible d'accèder à l'URL
http://127.0.0.1:8081/, qui va afficher la procédure de configuration de
l'instance Matomo.

L'objectif à terme (donc pas encore atteint) est que le conteneur `ansible-zds`
puisse envoyer des statistiques de visites au conteneur `ansible-matomo`.

À noter qu'en production, on met à jour Matomo "manuellement" en passant par le
système de mises à jour dans le navigateur.

L'organisation du dépôt et des rôles Ansible pourrait certainement être mieux
faite pour avoir des choses spécifiques à Matomo, mais également des choses en
communes entre Matomo et ZdS. Votre contribution pour améliorer ce point sera
la bienvenue :)

Auparavant, nous avions un dépôt dédié :
[`ansible-matomo`](https://github.com/zestedesavoir/ansible-matomo), qui
utilisait le rôle
[`consensus.matomo`](https://galaxy.ansible.com/ui/standalone/roles/consensus/matomo/).
