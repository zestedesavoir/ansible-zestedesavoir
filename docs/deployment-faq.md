# Foire Aux Questions concernant le déploiement

## Comment lancer une commande `python manage.py` sur le serveur ?

Si jamais vous souhaitez lancer une commande `python manage.py COMMANDE` sur le serveur, il faut lancer `/opt/zds/wrapper COMMANDE` à la place. Cet enrobage permet de lancer `python manage.py` avec l'utilisateur `zds` et les configurations spécifiques au serveur de production. Il s'utilise exactement de la même manière !

Si vous avez un doute sur le nom d'une commande, lancez `/opt/zds/wrapper` sans argument pour afficher la liste des commandes disponibles.

## Comment activer un changement visuel temporaire ?

Si vous souhaitez faire tomber de la neige, faire tomber des cœurs anatomiquement incorrects ou encore habiller Clem pour Noël ou Halloween, c'est très simple !

Vous pouvez activer et désactiver ces changements individuellement dans la configuration correspondant au serveur souhaité dans `group_vars/SERVEUR/vars.yml` :

```yaml
visual_changes:
  - snow # Neige qui tombe dans le bandeau de navigation
  - valentine-snow # Cœurs qui tombent dans le bandeau de navigation
  - clem-christmas # Affiche la Clem Christmas sur la page d'accueil
  - clem-halloween # Affiche la Clem Halloween sur la page d'accueil
```

Il vous suffit ensuite de lancer le *playbook* pour que les changements soient pris en compte !

Il est aussi possible de directement modifier le fichier de configuration `/opt/zds/config.toml` sur le serveur souhaité en ajoutant une ligne dans le bloc `[zds]`. Par exemple :

```toml
visual_changes = ["snow", "clem-christmas"]
```

Il vous suffit ensuite de lancer `sudo systemctl reload zds` pour que les changements soient pris en compte.

## Comment ajouter un bandeau temporaire en amont d'une maintenance ?

Il est possible d'ajouter un bandeau d'information tout en haut du site pour prévenir les utilisateurs en amont d'une longue maintenance sur le serveur de production. Pour ce faire, il suffit de modifier `group_vars/production/vars.yml` en s'inspirant du bandeau actuellement utilisé sur le serveur de bêta et de lancer le script Ansible pour prendre en compte les changements :

```yaml
very_top_banner:
  background_color: '#132DAE'
  border_color: '#061279'
  color: 'white'
  message: 'Site web en maintenance pendant quelques minutes à 11 heures'
  slug: 'maintenance-09/11/2020-11h'
```

Une autre façon de faire est de modifier le fichier de configuration `/opt/zds/config.toml` directement sur le serveur puis de recharger Gunicorn avec `sudo systemctl reload zds` :

```toml
[very_top_banner]
background_color = "#132DAE"
border_color = "#061279"
color = "white"
message = "Site web en maintenance pendant quelques minutes à 11 heures"
slug = "maintenance-09/11/2020-11h"
```

## Comment effectuer proprement une opération de maintenance sur la base de données ?

Si jamais vous devez effectuer des actions manuelles sur la base de données, il vous faut mettre en maintenance le site web comme ceci :

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

## Comment interdire la connexion ou l'inscription pour une certaine IP ?

Lorsque plusieurs comptes de spam sont créés régulièrement à partir d'une même IP, il peut être nécessaire d'interdire la connexion ou l'inscription sur le site web à partir de cette IP. Il suffit donc de rajouter une ligne `deny ADRESSE_IP;` au fichier `/etc/nginx/snippets/ban.conf` pour que l'accès aux URL commençant par `/membres/` soit interdit avec cette IP. Ceci n'est pour l'instant disponible que sur le serveur de production.