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

Le script [`backups.sh`](../roles/backup/files/prod/backups.sh) est exécuté
régulièrement par l'utilisateur root, selon les règles `cron` suivantes, et
réalise les sauvegardes du serveur de production.
```cron
# min hour dom month dow command
0 */2 * * * /root/backups.sh >> /var/log/zds/backups.log 2>&1
15  3 * * * /root/backups.sh full >> /var/log/zds/backups.log 2>&1
```

#### Base de données

Mariabackup fait une sauvegarde complète chaque jour à 3h15, puis une
sauvegarde incrémentale à chaque heure paire (donc toutes les deux heures)
(fonction `db_local_backup` du script `backups.sh`).

Ces sauvegardes sont disponibles dans le dossier `/var/backups/mysql` avec
comme nom la date et l'heure de la sauvegarde (au format `AAAAMMJJ-HHMM`). Les
sauvegardes sont supprimées au fur et à mesure pour ne pas saturer l'espace
disque (fonction `db_clean` du script `backups.sh`).

Une fois les sauvegardes réalisées, elles sont envoyées vers le serveur de bêta
avec Borg (fonction `db_borg_backup` du script `backups.sh`).

#### Contenus du site

Borg sauvegarde toutes les deux heures le dossier `/opt/zds/data` vers le
serveur de bêta (fonction `data_borg_backup` du script `backups.sh`).


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
0 5 * * * /opt/sauvegarde/cleaning.sh >> /var/log/zds/backups-cleaning.log 2>&1
```

### Surveillance

Les scripts de sauvegardes lancés automatiquement envoient une notification au
service [healthchecks.io](https://healthchecks.io) lorsqu'ils ont terminés. En
cas d'erreur dans le déroulement des scripts, HealthCheck enverra un mail à
l'adresse technique pour indiquer qu'il n'a pas reçu une notification.


## Restauration des sauvegardes (synchronisation de la bêta avec la prod)

Le script
[`restore-from-prod.sh`](../roles/backup/files/beta/restore-from-prod.sh)
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

> Attention, il peut être nécessaire de forcer l'utilisation de l'IPv4. Dans ce
> cas, il faut rajouter `AddressFamily inet` au fichier `.ssh/config` et
> utiliser une IPv4 dans le fichier `authorized_keys` (on ne peut pas utiliser
> de nom de domaine, à moins de passer `UseDNS` à `true` dans
> `/etc/ssh/sshd_config`). En pratique, on en a besoin pour les sauvegardes du
> seveur hébergeant Matomo vers le serveur de bêta, car Scaleway [ne fournit
> pas d'IPv6 fixe pour les
> serveurs](https://feature-request.scaleway.com/posts/209/truly-static-ipv6),
> ni de [moyen de définir un enregistrement DNS
> inverse](https://feature-request.scaleway.com/posts/73/reverse-name-support-for-public-ipv6).


## Sauvegardes externes

Sur la prod, en root :
```sh
ssh-keygen -a 100 -t ed25519 -C "zds-prod->ext" # à sauvegarder dans /root/.ssh/ext_ed25519
```
Mettre en place la clé publique sur le serveur externe, dans le `authorized_keys` :
```
restrict,from="2001:4b98:dc0:41:216:3eff:febc:7e10,92.243.7.44",command="borg serve --append-only --restrict-to-repository /chemin/du/depot/borg --storage-quota 200G" <clé SSH>
```

Sur la prod, ajouter dans `/root/.ssh/config` :
```
Host ext-backup
	HostName adresse.du.serveur.externe
	User utilisateur
	IdentityFile ~/.ssh/ext_ed25519
```

Initialiser le dépôt, **avec une méthode de chiffrement** :
```sh
borg init -e repokey ext-backup:/chemin/du/depot/borg
```
Mettre la phrase de passe dans le fichier `/root/borg/ext-depot.passphrase`.
Exporter la clé :
```sh
borg key export ext-backup:/chemin/du/depot/borg /root/borg/ext-depot.key
```
S'assurer que ces deux fichiers ont seulement les droits 600.

Ajouter au script de sauvegarde exécuté par la CRON :
```sh
backup2extbackup()
{
    echo "Backup data to external server..."
    BORG_PASSCOMMAND='cat /root/borg/ext-depot.passphrase' \
	borg create                                        \
	--verbose                                          \
	--filter AME                                       \
	--list                                             \
	--stats                                            \
	--show-rc                                          \
	--compression zstd,6                               \
	--exclude-caches                                   \
	--info                                             \
	ext-backup:/chemin/du/depot/borg::$BACKUP_DATE     \
	/dossier/à/sauvegarder/
    # Dupliquer les commandes pour le dépôt de la BDD
}

# Appeler la fonction après l'appel à backup2beta
```


## Rotation des logs

Les logs des sauvegardes sont dans le dossier `/var/log/zds/`.  Ils sont
archivés par les instructions `logrotate` du fichier
[`/etc/logrotate.d/zds-backup`](../roles/backup/files/logrotate-zds-backup).


## Perdre des données, cela n'arrive pas qu'aux autres !

Il y a déjà eu deux pertes de données dans l'histoire de Zeste de Savoir, avec
à chaque fois un article explicatif :
- [Retour sur une semaine compliquée pour Zeste de Savoir](https://zestedesavoir.com/articles/194/retour-sur-une-semaine-compliquee-pour-zeste-de-savoir/)
- [Retour dans le passé pour ZdS :(](https://zestedesavoir.com/articles/1432/retour-dans-le-passe-pour-zds/)
