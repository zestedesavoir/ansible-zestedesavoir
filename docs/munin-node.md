## (Archive) Configuration de Munin Node

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