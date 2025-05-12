# Matomo

Une instance [Matomo](https://matomo.org/) est également déployée sur le
serveur `matomo.zestedesavoir.com`.

Ce dépôt contient les scripts nécessaires pour :
- lancer une machine virtuelle dédiée à Matomo (différente de la VM utilisée
  pour déployer localement zds-site)
- le playbook Ansible `playbook-matomo.yml` configure la VM pour arriver
  jusqu'à l'installation de Matomo depuis le navigateur.

Le fichier `Vragrantfile` définit donc deux VMs : `zds` et `matomo`. Il faut
ajouter ce nom de VM comme paramètre supplémentaire aux commandes Vagrant. Par
exemple, pour démarrer la VM avec Matomo :
```sh
vagrant up matomo
```
Lorsque la création de la VM et le déploiement sont terminés, il est possible
d'accèder à l'URL http://127.0.0.1:8081/, qui va afficher la procédure de
configuration de l'instance Matomo.

L'objectif à terme (donc pas encore atteint) est que la VM `zds` puisse envoyer
des statistiques de visites à la VM `matomo`.

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
