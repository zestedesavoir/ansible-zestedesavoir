# Sauvegardes de Zeste de Savoir

Zeste de Savoir c'est une communauté mais aussi un site web avec ses membres, ses contenus, ses messages, etc. Que faire pour ne pas perdre tout ça ?

Dans le cas de Zeste de Savoir, deux points sont critiques :

- la base de données avec les utilisateurs, les messages, les contenus, etc. (dans `/var/lib/mysql`) ;
- les fichiers importants, c'est-à-dire les dépôts Git des contenus et les galeries d'images (dans `/opt/zds/data`).

Le reste (code source, configuration du serveur, etc) n'est finalement pas très important car tout est présent sur Github et un nouveau serveur peut être rapidement installé !

Deux sauvegardes de la prod sont actuellement en place :

- une sauvegarde sur un serveur appartenant à Sandhose, dont je ne parlerais pas ici ;
- une sauvegarde sur le serveur de bêta, dont je vais parler ici.

## Comment est mise en place la sauvegarde ?

### Sur le serveur de prod

Pour les fichiers importants, il n'y a pas de sauvegarde sur le serveur de prod lui-même. Par contre, la base de données fait l'objet :

- d'une sauvegarde complète chaque jour à 3h15 ;
- d'une sauvegarde incrémentale toutes les quatre heures à 4h, 8h, 12h, 16h, 20h et minuit.

Ces sauvegardes sont disponibles dans le dossier `/var/backups/mysql` avec comme nom la date et l'heure de la sauvegarde (au format `AAAAMMJJ-HHMM`). On supprime au fur et à mesure les anciennes sauvegardes pour libérer de l'espace disque.

On utilise l'utilitaire `cron` pour lancer ces sauvegardes :

```cron
# min hour dom month dow command
0 */4 * * * /var/backups/mysql/backup.sh
15 3 * * * /var/backups/mysql/backup.sh full
15 4 * * * /var/backups/mysql/cleanup.sh
```

**`backup.sh`**

```sh
#!/bin/sh

set -eu

WD=/var/backups/mysql
LATEST=$WD/latest

PREVIOUS=`readlink -f $LATEST`
NEXT=$WD/`date '+%Y%m%d-%H%M'`

if [ -d "$NEXT" ]; then
	echo "\`$NEXT' already exists."
	exit 1
fi

if [ "$#" -ge 1 ] && [ "$1" = "full" ]; then
	NEXT=$NEXT-full
	mariabackup --backup --compress --target-dir=$NEXT 2> $NEXT.log
else
	if ! [ -L "$LATEST" ]; then
		echo "\`$LATEST' does not exists. Consider doing a full backup first."
		exit 1
	fi

	mariabackup --backup --compress --target-dir=$NEXT --incremental-basedir=$PREVIOUS 2> $NEXT.log
fi

rm -f $LATEST $LATEST.log
ln -s $NEXT $LATEST
ln -s $NEXT.log $LATEST.log
```

**`cleanup.sh`**

```sh
#!/bin/sh

set -eu

WD=/var/backups/mysql

BACKUPS="`echo $WD/*-*/ | tr ' ' '\n' | sort -nr`"

TO_DELETE="`
	echo "$BACKUPS" | awk '
		BEGIN { full=0 }
		{ if (full > 1) { print $0 } }
		/full/ { full++ }
	'
`"

[ -z "$TO_DELETE" ] || rm -r $TO_DELETE
```

### Sur le serveur de bêta

On utilise :

- rsync pour les sauvegardes de la base de données ;
- [BorgBackup](https://borgbackup.readthedocs.io/en/stable/index.html) pour les fichiers importants.

Un volume dédié aux sauvegardes de 50 Go est monté sur `/opt/sauvegarde` sur le serveur de bêta et contient :

- les sauvegardes de la base de données dans `/opt/sauvegarde/db` (l'équivalent de `/var/backups/mysql` mais sans la suppression des anciennes sauvegardes) ;
- les sauvegardes des fichiers importants dans `/opt/sauvegarde/data` (que l'on initialise au préalable avec `borg init --encryption=none /opt/sauvegarde/data` avec l'utilisateur `root`).

On utilise l'utilitaire `cron` *depuis le serveur de prod* pour envoyer les données vers le serveur de bêta :

```cron
# min hour dom month dow command
0 */4 * * * /root/sauvegarde-vers-la-beta/donnees.sh
5 */4 * * * /root/sauvegarde-vers-la-beta/bdd.sh
```

**`bdd.sh` (sur le serveur de prod)**

```sh
#!/bin/sh

BASE=opt/sauvegarde

echo "Synchronisation des sauvegardes de la base de donnée"
rsync -azvr /var/backups/mysql/ root@scaleway.zestedesavoir.com:/$BASE/db
```

**`donnees.sh` (sur le serveur de prod)**

```sh
#!/bin/sh

# Script from https://borgbackup.readthedocs.io/en/stable/quickstart.html#automating-backups

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=ssh://root@scaleway.zestedesavoir.com/opt/sauvegarde/data

# See the section "Passphrase notes" for more infos.
#export BORG_PASSPHRASE='XYZl0ngandsecurepa_55_phrasea&&123'

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

DATE=`date '+%Y%m%d-%H%M'`

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
                                    \
    ::$DATE                         \
    /opt/zds/data                   \

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

#borg prune                          \
#    --list                          \
#    --show-rc                       \
#    --keep-within 1w                \

#prune_exit=$?

# use highest exit code as global exit code
#global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=${backup_exit}

if [ ${global_exit} -eq 0 ]; then
    info "Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup and/or Prune finished with warnings"
else
    info "Backup and/or Prune finished with errors"
fi

exit ${global_exit}
```

Enfin, voici le script qui s'occupe de garder les 60 derniers jours de sauvegardes et de supprimer le reste.

**cleaning.sh (sur le serveur de bêta)**

```sh
#!/bin/sh

# Get the list of the full database backups, sorted by date from latest to oldest
db_full_backups=`find /opt/sauvegarde/db -type d -name *-full | sort -nr`

count=0
for db_full_backup in $db_full_backups
do
    count=$((count+1))
    # We want to keep the newer 60 database backups
    if [ $count -le 60 ]
    then
        continue
    fi

    # We remove the 0315-full part
    db_daily_backups=`echo $db_full_backup | head -c -10`
    # We remove the full database backup and its incremental database backups
    echo "rm -r $db_daily_backups*"
    rm -r $db_daily_backups*
done

# We keep the data backups for last 60 days and remove the rest
borg prune --keep-within 60d --list data/
```

## Comment est mise en place la restauration ?

C'est bien beau d'avoir des sauvegardes, mais fonctionneront-elles le jour où on en aura besoin ? Pour cela, il est impératif de vérifier que la restauration des sauvegardes fonctionne. Une bonne manière de tester cela est d'utiliser les sauvegardes du serveur de prod sur le serveur de bêta !

Voici les commandes que j'ai effectuée pour restaurer la bêta à partir des sauvegardes de la prod :

```sh
# Script de mise à jour de la bêta avec les backups de la prod

### Étape 1 - On prépare ce qui peut se faire avant l'arrêt du site web

# Il faut identifier les backups de la base de données à utiliser
# Si on est le 9 mai 2020 à 7h du matin alors il faudra utiliser :
# - la sauvegarde complète de 3h15 : 20200509-0315-full
# - la sauvegarde incrémentale de 4h : 20200509-0400
# - la sauvegarde incrémentale de 6h : 20200509-0600

# On copie les sauvegardes concernées pour ne pas qu'elles soient modifiées
sudo cp -r /opt/sauvegarde/db/20200509-0315-full{,.bck}/
sudo cp -r /opt/sauvegarde/db/20200509-0400{,.bck}/
sudo cp -r /opt/sauvegarde/db/20200509-0600{,.bck}/

# On décompresse les sauvegardes
sudo mariabackup -V --decompress --target-dir /opt/sauvegarde/db/20200509-0315-full/
sudo mariabackup -V --decompress --target-dir /opt/sauvegarde/db/20200509-0400/
sudo mariabackup -V --decompress --target-dir /opt/sauvegarde/db/20200509-0600/

# On prépare la sauvegarde complète
sudo mariabackup -V --prepare \
   --target-dir=/opt/sauvegarde/db/20200509-0315-full/
   
# On met à jour la sauvegarde complète grâce aux sauvegardes incrémentales
sudo mariabackup -V --prepare \
   --target-dir=/opt/sauvegarde/db/20200509-0315-full/ \
   --incremental-dir=/opt/sauvegarde/db/20200509-0400/
sudo mariabackup -V --prepare \
   --target-dir=/opt/sauvegarde/db/20200509-0315-full/ \
   --incremental-dir=/opt/sauvegarde/db/20200509-0600/

### Étape 2 - On s'occupe de ce qui doit être fait avec le site web à l'arrêt

# En premier il faut passer arrêter le site web
cd /opt/zds/webroot/
sudo ln -s errors/maintenance.html
sudo systemctl stop zds
sudo systemctl stop zds-watchdog

# Ensuite il faut arrêter MySQL et faire une copie de la bdd existante
sudo systemctl stop mysql
sudo mv /var/lib/mysql{,.bck}/

# On restaure la base de données avec la sauvegarde complète
sudo mariabackup -V --copy-back --target-dir /opt/sauvegarde/db/20200509-0315-full/

# On met les bons droits et on relance MySQL
sudo chown -R mysql:mysql /var/lib/mysql/
sudo systemctl start mysql

# On vérifie que le démarrage de MySQL s'est bien passé
sudo systemctl status mysql

# On va chercher le mot de passe de l'utilisateur 'zds' pour la base de donnée dans le fichier '/opt/zds/config.toml'
# On ouvre le shell de MySQL
sudo mysql
# On écrit dedans :
alter user 'zds'@'localhost' identified by 'MOT DE PASSE'

# On vérifie la quantité d'espace disque disponible
df -kh

# Si on a assez d'espace disque disponible (environ 15 Go) alors on effectue une copie de /opt/zds/data
sudo cp -r /opt/zds/data{,.bck}/
# Sinon, on supprime /opt/zds/data
sudo rm -rI /opt/zds/data

# On utilise la sauvegarde du dossier /opt/zds/data
# On doit lancer la commande depuis /
# On peut utiliser l'option -n pour faire un dry-run
# Je n'ai pas l'impression que --verbose ne serve à grand chose, c'est dommage
cd /
sudo borg extract --verbose /opt/sauvegarde/data::20200509-0600 opt/zds/data

# Si jamais la version en production est plus ancienne que celle en bêta :
# - on applique les migrations de la base de données
# - on transfère les fichiers front de /opt/zds/app/dist vers /opt/zds/data/static
/opt/zds/wrapper migrate
/opt/zds/wrapper collectstatic

# On peut relancer le site web
sudo systemctl start zds
sudo systemctl start zds-watchdog
sudo rm /opt/zds/webroot/maintenance.html

# On vérifie que tout fonctionne bien

### Étape 3 - On nettoie

# Si tout est parfait, on peut supprimer les copies temporaires
sudo rm -rI /opt/zds/data.bck/
sudo rm -rI /var/lib/mysql.bck/
sudo rm -rI /opt/sauvegarde/db/20200509-0315-full.bck/
sudo rm -rI /opt/sauvegarde/db/20200509-0400.bck/
sudo rm -rI /opt/sauvegarde/db/20200509-0600.bck/
```



## Perdre des données, cela n'arrive pas qu'aux autres !

Il y a déjà eu deux pertes de données dans l'histoire de Zeste de Savoir, avec à chaque fois un article explicatif :

- [Retour sur une semaine compliquée pour Zeste de Savoir](https://zestedesavoir.com/articles/194/retour-sur-une-semaine-compliquee-pour-zeste-de-savoir/)
- [Retour dans le passé pour ZdS :(](https://zestedesavoir.com/articles/1432/retour-dans-le-passe-pour-zds/)

