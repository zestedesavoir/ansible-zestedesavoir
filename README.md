# Zeste de Savoir sur un serveur de production

Ce dépôt contient tous les fichiers nécessaire au déploiement d'un serveur de production pour Zeste de Savoir grâce à [Ansible](https://docs.ansible.com/ansible/latest/index.html). Vous trouverez ci-dessous toutes les informations pour prendre en main une installation de Zeste de Savoir sur un serveur de production.

[Documentation du projet technique de Zeste de Savoir](https://docs.zestedesavoir.com)

[Code source de Zeste de Savoir](https://github.com/zestedesavoir/zds-site)

[Code source de zmarkdown](https://github.com/zestedesavoir/zmarkdown)

## Présentation générale

Nous avons actuellement deux serveurs :

- le serveur de production (« la prod ») à l'adresse `zestedesavoir.com` ;
- le serveur de préproduction (« la bêta ») à l'adresse `beta.zestedesavoir.com`.

Ces deux serveurs doivent être identiques autant que possible pour pouvoir reproduire les bugs de la prod sur la bêta. Néanmoins, le système de sauvegarde de la base de données et des fichiers est mis en place uniquement sur le serveur de production.

### Logiciels utilisés

| Paramètre                                                    | Valeur               |
| ------------------------------------------------------------ | -------------------- |
| Système d'exploitation                                       | Debian 10 « Buster » |
| Serveur web                                                  | nginx                |
| Interface WSGI (entre le serveur web et Django)              | Gunicorn             |
| Base de donnée                                               | MariaDB              |
| Moteur de recherche                                          | ElasticSearch        |
| Outil de surveillance du système d'exploitation et des requêtes de Zeste de Savoir * | Munin                |
| Outil de surveillance des erreurs de Zeste de Savoir *       | Sentry               |
| Outil pour les certificats TLS                               | Certbot              |

\* Actuellement, les deux outils de surveillance sont installés sur un serveur à part du serveur de production. (Un serveur appartenant à [vhf] pour le Munin et un serveur appartenant à [Sandhose] pour le Sentry.)

### Arborescence des fichiers

| Paramètre                                                    | Valeur                                     |
| ------------------------------------------------------------ | ------------------------------------------ |
| Utilisateur et groupe local                                  | `zds` et `zds`                             |
| Dossier dédié à `zds-site`                                   | `/opt/zds/app`                             |
| Dossier avec les données importantes à sauvegarder (dépôts Git des contenus et images des galeries) | `/opt/zds/data`                            |
| Base de données à sauvegarder (et ses sauvegardes régulières) | `/var/lib/mysql` (et `/var/backups/mysql`) |
| Fichiers de journalisation                                   | `/var/log/zds`                             |

### Sauvegardes

Une explication détaillée est disponible dans le fichier `BACKUP.md` !

## Déployer dans une machine virtuelle

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

## Déployer sur un serveur de production

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

## Configuration temporaire

### Changements visuels temporaires

Plusieurs changements visuels sont activables et désactivables en modifiant la configuration dans `group_vars/beta/vars.yml` ou `group_vars/production/vars.yml` :

```yaml
visual_changes:
  - snow # Neige animée dans le bandeau de navigation
  - clem-christmas # Affiche la Clem Christmas sur la page d'accueil
  - clem-halloween # Affiche la Clem Halloween sur la page d'accueil
```

### Ajouter un bandeau temporaire

Il est possible d'ajouter un bandeau d'information tout en haut du site pour prévenir les utilisateurs en amont d'une longue maintenance du serveur de production. Pour se faire, il suffit de modifier `group_vars/production/vars.yml` en s'inspirant du bandeau actuellement utilisé sur le serveur de bêta et de lancer le script Ansible pour prendre en compte les changements :

```yaml
very_top_banner:
  background_color: '#132DAE'
  border_color: '#061279'
  color: 'white'
  message: 'Site web en maintenance pendant quelques minutes à 11 heures'
  slug: 'maintenance-09/11/2020-11h'
```

Une autre façon de faire est de modifier le fichier `/opt/zds/config.toml` directement sur le serveur puis de recharger Gunicorn avec `sudo systemctl reload zds` :

```toml
[very_top_banner]
background_color = "#132DAE"
border_color = "#061279"
color = "white"
message = "Site web en maintenance pendant quelques minutes à 11 heures"
slug = "maintenance-09/11/2020-11h"
```

## Actions manuelles sur le serveur

### Effectuer une opération de maintenance

Si jamais vous devez effectuer des actions manuelles sur la base de données ou des logiciels utilisés par le site web, il vous faut le mettre en maintenance comme ceci :

```bash
# On affiche la page de maintenance
cd /opt/zds/webroot
sudo ln -s errors/maintenance.html
# On attend quelques secondes
# On arrête le serveur et le watchdog associé
sudo systemctl stop zds-watchdog
sudo systemctl stop zds
# Si besoin, on arrête la base de données
sudo systemctl stop mariadb
```

Pour le redémarrer, on effectue les étapes inverses :

```bash
# Si besoin, on redémarre la base de données
sudo systemctl start mariadb
# On redémarre le serveur et le watchdog associé
sudo systemctl start zds
sudo systemctl start zds-watchdog
# On attend quelques secondes
# On enlève la page de maintenance
sudo rm /opt/zds/webroot/maintenance.html
```

### Lancer une commande `python manage.py`

Si jamais vous devez lancer une commande `python manage.py`, ne le faites pas, utilisez le script `wrapper` présent dans le dossier `/opt/zds` ! Cet enrobage permet de lancer `python manage.py` avec l'utilisateur `zds` et les configurations spécifiques au serveur de production. Il s'utilise de la même manière : par exemple, `python manage.py shell` devient simplement `/opt/zds/wrapper shell`.

### Interdire la connexion ou l'inscription pour une certaine IP

Lorsque plusieurs comptes de spam sont créés régulièrement à partir d'une même IP, il peut être nécessaire d'interdire la connexion ou l'inscription sur le site web à partir de cette IP. Il suffit donc de rajouter une ligne `deny ADRESSE_IP;` au fichier `/etc/nginx/snippets/ban.conf` pour que l'accès aux URL commençant par `/membres/` soit interdit avec cette IP.

## (Archive) Configuration du Munin

*Actuellement, notre script Ansible ne prend pas en charge la configuration du Munin. J'archive ici les anciennes instructions pour l'installation du Munin. Je ne sais pas si elles sont encore valables.*

------

Installer le noeud Munin : `apt-get install munin-node`.

On obtient les suggestions de plugins à installer avec `munin-node-configure --suggest` et les commandes à lancer pour les activer via `munin-node-configure --shell`.

Le serveur de graphe accède au serveur en SSH avec une clé publique, placée dans le home de l'utilisateur munin (sous debian, l'utilisateur créé par le packet munin a son home dans `/var/lib/munin`, donc sa clé doit être dans `/var/lib/munin/.ssh/authorized_keys`).

Créer les liens vers le plugin Django-Munin :

```bash
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_active_sessions
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_active_users
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_db_performance
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_articles
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_mps
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_posts
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_sessions
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_topics
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_tutorials
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_users
ln -s /usr/share/munin/plugins/django.py /etc/munin/plugins/zds_total_tribunes
```

Créer le fichier `/etc/munin/plugin-conf.d/zds.conf` et y ajouter la config des graphes
propres à ZdS :

```
[zds_db_performance]
env.url https://zestedesavoir.com/munin/db_performance/
env.graph_category zds

[zds_total_users]
env.url https://zestedesavoir.com/munin/total_users/
env.graph_category zds

[zds_active_users]
env.url https://zestedesavoir.com/munin/active_users/
env.graph_category zds

[zds_total_sessions]
env.url https://zestedesavoir.com/munin/total_sessions/
env.graph_category zds

[zds_active_sessions]
env.url https://zestedesavoir.com/munin/active_sessions/
env.graph_category zds

[zds_total_topics]
env.url https://zestedesavoir.com/munin/total_topics/
env.graph_category zds

[zds_total_posts]
env.url https://zestedesavoir.com/munin/total_posts/
env.graph_category zds

[zds_total_mps]
env.url https://zestedesavoir.com/munin/total_mps/
env.graph_category zds

[zds_total_tutorials]
env.url https://zestedesavoir.com/munin/total_tutorials/
env.graph_category zds

[zds_total_articles]
env.url https://zestedesavoir.com/munin/total_articles/
env.graph_category zds

[zds_total_tribunes]
env.url https://zestedesavoir.com/munin/total_opinions/
env.graph_category zds
```

<!-- Liens vers les pseudos -->

[vhf]: https://github.com/vhf
[Sandhose]: https://github.com/sandhose
