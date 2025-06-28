#!/bin/bash

set -eu

BORG_COMMAND=/usr/local/bin/borg
BORG126_COMMAND=/usr/local/bin/borg1.2.6
BACKUP_DATE=`date '+%Y%m%d-%H%M'`
SAVE_ROOT_DIR=/var/backups/matomo
DB_SAVED_DIR=$SAVE_ROOT_DIR/mysql
DATA_SAVE_DIR=$SAVE_ROOT_DIR/matomo
VAULTWARDEN_DIR=/opt/vaultwarden
VAULTWARDEN_DB_BACKUP_DIR=$VAULTWARDEN_DIR/db_backups

db_local_backup()
{
	LATEST=$DB_SAVED_DIR/latest

	PREVIOUS=`readlink -f $LATEST`
	NEXT=$DB_SAVED_DIR/$BACKUP_DATE


	if [ -d "$NEXT" ]; then
		echo "'$NEXT' already exists."
		exit 1
	fi

	# See https://github.com/omegazeng/run-mariabackup for mariabackup options for
	# compressed and incremental backups.

	if [ "$#" -ge 1 ] && [ "$1" = "full" ]; then
		NEXT=$NEXT-full
		mkdir $NEXT

		(
			set -o pipefail  # get exit code before pipe
			set +e
			mariabackup 				\
				--backup 			\
				--stream=xbstream 		\
				--extra-lsndir $NEXT 		\
				2> $NEXT/mariabackup.log 	\
				| gzip > $NEXT/backup.stream.gz
			err=$?
			if [ $err -ne 0 ]; then
				echo "Full database backup failed, aborting."
				exit 1
			fi
		)
	else
		if ! [ -L "$LATEST" ]; then
			echo "'$LATEST' does not exists. Consider doing a full backup first."
			exit 1
		fi

		mkdir $NEXT

		(
			set -o pipefail  # get exit code before pipe
			set +e
			mariabackup 				\
				--backup 			\
				--stream=xbstream 		\
				--extra-lsndir $NEXT 		\
				--incremental-basedir $PREVIOUS \
				2> $NEXT/mariabackup.log 	\
				| gzip > $NEXT/backup.stream.gz
			err=$?
			if [ $err -ne 0 ]; then
				echo "Incremental database backup failed, aborting."
				exit 1
			fi
		)
	fi

	rm -f $LATEST $LATEST.log
	ln -s $NEXT $LATEST
	ln -s $NEXT/mariabackup.log $LATEST.log
}

data_local_backup()
{
	echo "** Starting local backup of Matomo application code..."
	rsync -a --exclude="tmp/*" /opt/matomo/ $DATA_SAVE_DIR
}

vaultwarden_local_backup()
{
	sqlite3 $VAULTWARDEN_DIR/data/db.sqlite3 ".backup '${VAULTWARDEN_DB_BACKUP_DIR}/${BACKUP_DATE}.sqlite3'"
	cp /etc/systemd/system/vaultwarden.service $VAULTWARDEN_DIR/
}

backup2beta2023()
{
	echo "Send backup to the 2023 beta server..."
	$BORG126_COMMAND create                                   \
	    --verbose                                             \
	    --filter AME                                          \
	    --list                                                \
	    --stats                                               \
	    --show-rc                                             \
	    --compression zstd,6                                  \
	    --exclude-caches                                      \
	    --info                                                \
	    beta-backup-2023:/opt/sauvegarde/matomo::$BACKUP_DATE \
	    $SAVE_ROOT_DIR
}

vaultwarden_backup2beta2023()
{

        echo "Send Vaultwarden backup to the 2023 beta server..."
        BORG_PASSCOMMAND='cat /root/borg/beta-vaultwarden.passphrase'  \
	    $BORG126_COMMAND create                                    \
            --verbose                                                  \
            --filter AME                                               \
            --list                                                     \
            --stats                                                    \
            --show-rc                                                  \
            --compression zstd,6                                       \
            --exclude-caches                                           \
            --info                                                     \
	    beta-backup-2023:/opt/sauvegarde/vaultwarden::$BACKUP_DATE \
	    $VAULTWARDEN_DIR
}


db_clean()
{
	echo "** Removing old local backups of the database..."

	BACKUPS="`echo $DB_SAVED_DIR/*-*/ | tr ' ' '\n' | sort -nr`"

	TO_DELETE="`
		echo "$BACKUPS" | awk '
			BEGIN { full=0 }
			{ if (full > 1) { print $0 } }
			/full/ { full++ }
		'
	`"

	echo "To be removed: $TO_DELETE"
	[ -z "$TO_DELETE" ] || rm -rf $TO_DELETE
}

vaultwarden_clean()
{
	echo "** Removing old local backups of the Vaultwarden database..."

	# Keep 8 most recent backups
	local to_delete="`echo $VAULTWARDEN_DB_BACKUP_DIR/*-*.sqlite3 | tr ' ' '\n' | sort -n | head -n -8`"

	echo "To be removed: $to_delete"
	[ -z "$to_delete" ] || rm -r $to_delete
}


# Big separator in log between executions of the script:
echo "#######################################################################################################################"
echo "Starting script ($(date))"

if [ "$#" -ge 1 ] && [ "$1" = "full" ]; then
	echo "** Starting a local full backup of the database..."
	db_local_backup full
	db_clean
	vaultwarden_clean
else
	echo "** Starting a local incremental backup of the database..."
	db_local_backup
fi

# data_local_backup
vaultwarden_local_backup

set +e
backup2beta2023; err1=$?
echo
# Ajouter ici les autres appels aux fonctions de sauvegarde
# backup2toto; err2=$?
# echo

# vaultwarden_backup2toto; err3=$?
# echo

err=$((err1+err2+err3))
set -e

if [ $err -gt 0 ]; then
	echo "At least one backup failed!"
else
	echo "All backups completed successfully!"

	curl -s -m 10 --retry 5 $(cat /root/healthchecks/matomo-sauvegardes.txt)
	echo # to make a newline after the "OK" written by curl
fi

echo "End of script ($(date))"
# Big separator in log between executions of the script:
echo "#######################################################################################################################"
