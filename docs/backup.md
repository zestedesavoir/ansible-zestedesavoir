# Sauvegardes de Zeste de Savoir

Zeste de Savoir c'est une communauté mais aussi un site web avec ses membres,
ses contenus, ses messages, etc. Que faire pour ne pas perdre tout ça ?

Dans le cas de Zeste de Savoir, deux éléments sont critiques :
- la base de données avec les utilisateurs, les messages, les contenus, etc.
  (dans `/var/lib/mysql`) ;
- les fichiers importants, c'est-à-dire les dépôts Git des contenus et les
  galeries d'images (dans `/opt/zds/data`).

Le reste (code source, configuration du serveur, etc) n'est finalement pas très
important car tout est présent sur GitHub et un nouveau serveur peut être
rapidement installé !

Deux types de sauvegardes sont réalisés :
- des sauvegardes du serveur de prod vers le serveur de bêta ;
- des sauvegardes externes, vers du stockage gracieusement mis à
  disposition par quelques membres.


## Outils

Les sauvegardes sont réalisées à l'aide de
[BorgBackup](https://borgbackup.readthedocs.io/en/stable/index.html), logiciel
qui gère les sauvegardes incrémentales, sauvegardes à distance, et
chiffrement.

[Mariabackup](https://mariadb.com/kb/en/mariabackup-overview/) est utilisé pour
exporter la base de données MariaDB de façon complète et incrémentale, et pour
ensuite restaurer les sauvegardes.

Les connexions entre les serveurs pour réaliser les sauvegardes sont faites en
SSH.



## Sauvegardes

Deux *dépôts* Borg sont utilisées : un pour les sauvegardes de la base de
données, et un autre pour les contenus hébérgés sur le site.


### Serveur de prod

#### Base de données

Un [script](../roles/backup/files/prod/backup.sh) utilise Mariabackup pour
faire une sauvegarde complète chaque jour à 3h15, puis une sauvegarde
incrémentale à chaque heure paire (donc toutes les deux heures).

Ces sauvegardes sont disponibles dans le dossier `/var/backups/mysql` avec
comme nom la date et l'heure de la sauvegarde (au format `AAAAMMJJ-HHMM`). Un
[script](../roles/backup/files/prod/cleanup.sh) supprime au fur et à mesure les
anciennes sauvegardes pour ne pas saturer l'espace disque.

Une fois les sauvegardes réalisées, elles sont envoyées vers le serveur de bêta
avec un [script](../roles/backup/files/prod/bdd.sh) qui lance Borg.

Les scripts sont lancés par l'utilisateur root, avec les règles `cron`
suivantes :
```cron
# min hour dom month dow command
0 */2 * * * /var/backups/mysql/backup.sh
15 3 * * * /var/backups/mysql/backup.sh full
15 4 * * * /var/backups/mysql/cleanup.sh

5 */2 * * * /root/sauvegarde-vers-la-beta/bdd.sh
20 3 * * * /root/sauvegarde-vers-la-beta/bdd.sh
```


#### Contenus du site

Un [script](../roles/backup/files/prod/donnees.sh) utilise Borg pour
sauvegarder le dossier `/opt/zds/data` vers le serveur de bêta.

Cette sauvegarde est réalisée toutes les deux heures :
```cron
# min hour dom month dow command
0 */2 * * * /root/sauvegarde-vers-la-beta/donnees.sh
15 3 * * * /root/sauvegarde-vers-la-beta/donnees.sh
```


### Serveur de bêta

Un volume de 50 Go dédié aux sauvegardes est monté sur `/opt/sauvegarde` sur le
serveur de bêta et contient :
- le dépôt pour les sauvegardes de la base de données dans
  `/opt/sauvegarde/db-borg` ;
- le dépôt pour les sauvegardes des contenus du site dans
  `/opt/sauvegarde/data`.

Les sauvegardes de plus de 60 jours sont supprimées par un
[script](../roles/backup/beta/cleaning.sh) exécuté quotidiennement :
```cron
# min hour dom month dow command
0 5 * * * /opt/sauvegarde/cleaning.sh
```


## Restauration des sauvegardes (synchronisation de la bêta avec la prod)

Le script [restore-from-prod.sh](../roles/backup/files/beta/restore-from-prod.sh)
permet de restaurer la bêta à partir des sauvegardes de la prod. Il faut
l'exécuter en root et préciser ce qu'il doit faire :
```sh
./restore-from-prod.sh all # restaure les données et la base de données de la dernière sauvegarde
./restore-from-prod.sh clean # supprime tous les éléments intermédiaires créés par la commande précédente
```
D'autres sous-commandes permettent de ne lancer que des portions du script.



## Précisions concernant BorgBackup

Sur la bêta et sur la prod, borg est installé en récupérant les binaires
fournis par BorgBackup, plutôt que d'utiliser la version des dépôts Debian qui
est un peu veillissante. L'installation est faite comme recommandée par la
[documentation](https://borgbackup.readthedocs.io/en/stable/installation.html#standalone-binary) :
```sh
wget https://github.com/borgbackup/borg/releases/download/1.1.17/borg-linux64
mv borg-linux64 /usr/local/bin/borg
chown root:root /usr/local/bin/borg
chmod 755 /usr/local/bin/borg
```
On reste actuellement sur la branche 1.1.*, car comme dit la
[documentation](https://borgbackup.readthedocs.io/en/stable/changes.html#version-1-2-0-2022-02-22-22-02-22) :
*do you already want to upgrade? 1.1.x also will get fixes for a while*.

Par défaut, borg n'est pas très verbeux donc il ne faut pas hésiter à lui
demander une barre de progression avec `-p` ou un peu plus de verbosité avec
`-v` !

Le cache de Borgbackup peut prendre plusieurs gigaoctets de données ce qui
n'est pas souhaitable sur la bêta car l'espace disque y est assez restreint. Il
a donc été désactivé en suivant les instructions de la documentation
([Frequently asked questions > The borg cache eats way too much disk space,
what can I
do?](https://borgbackup.readthedocs.io/en/stable/faq.html#the-borg-cache-eats-way-too-much-disk-space-what-can-i-do)).


### Mise en en place des dépôts Borg

Sur la prod, en root :
```sh
ssh-keygen -a 100 -t ed25519 -C "zds-prod->beta" # à sauvegarder dans /root/.ssh/beta_ed25519
```

Sur la bêta :
```sh
adduser --disabled-password zds-prod
mkdir /home/zds-prod/.ssh
```
Créer le fichier `/home/zds-prod/.ssh/authorized_keys` et y ajouter :
```
restrict,from="2001:4b98:dc0:41:216:3eff:febc:7e10,92.243.7.44",command="borg serve --append-only --restrict-to-repository /opt/sauvegarde/db-borg --storage-quota 30G" <clé SSH publique générée sur la prod>
```
Ainsi, l'accès par SSH au serveur de bêta avec cette clé est restreint aux
connexions venant du serveur de prod, et ne peut servir qu'à exécuter la
commande borg indiquée.
```sh
chown -R zds-prod:zds-prod /home/zds-prod/.ssh
chmod -R 700 ~zds-prod/.ssh
chmod 600 ~zds-prod/.ssh/authorized_keys
mkdir /opt/sauvegarde/db-borg
chown -R zds-prod:zds-prod /opt/sauvegarde/db-borg
```
Sur la prod, ajouter dans `/root/.ssh/config` :
```
Host beta-backup
	HostName scaleway.zestedesavoir.com
	User zds-prod
	IdentityFile ~/.ssh/beta_ed25519
```
Initialiser le dépôt Borg, depuis le serveur de prod, en root :
```sh
borg init -e none beta-backup:/opt/sauvegarde/db-borg
```


## Perdre des données, cela n'arrive pas qu'aux autres !

Il y a déjà eu deux pertes de données dans l'histoire de Zeste de Savoir, avec
à chaque fois un article explicatif :
- [Retour sur une semaine compliquée pour Zeste de Savoir](https://zestedesavoir.com/articles/194/retour-sur-une-semaine-compliquee-pour-zeste-de-savoir/)
- [Retour dans le passé pour ZdS :(](https://zestedesavoir.com/articles/1432/retour-dans-le-passe-pour-zds/)
