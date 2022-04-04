#!/bin/sh

set -eu

BACKUP_DATE=`date '+%Y%m%d-%H%M'`

db_local_backup()
{
	WD=/var/backups/mysql
	LATEST=$WD/latest

	PREVIOUS=`readlink -f $LATEST`
	NEXT=$WD/$BACKUP_DATE


	if [ -d "$NEXT" ]; then
		echo "'$NEXT' already exists."
		exit 1
	fi

	# See https://github.com/omegazeng/run-mariabackup for mariabackup options for
	# compressed and incremental backups.

	if [ "$#" -ge 1 ] && [ "$1" = "full" ]; then
		NEXT=$NEXT-full
		mkdir $NEXT
		mariabackup --backup --stream=xbstream --extra-lsndir $NEXT 2> $NEXT/mariabackup.log | gzip > $NEXT/backup.stream.gz
	else
		if ! [ -L "$LATEST" ]; then
			echo "'$LATEST' does not exists. Consider doing a full backup first."
			exit 1
		fi

		mkdir $NEXT
		mariabackup --backup --stream=xbstream --extra-lsndir $NEXT --incremental-basedir $PREVIOUS 2> $NEXT/mariabackup.log | gzip > $NEXT/backup.stream.gz
	fi

	rm -f $LATEST $LATEST.log
	ln -s $NEXT $LATEST
	ln -s $NEXT/mariabackup.log $LATEST.log
}


data_borg_backup()
{
	echo "** Content backups with borg..."

	echo "Backup data to the beta server..."
	borg create                                        \
	    --verbose                                      \
	    --filter AME                                   \
	    --list                                         \
	    --stats                                        \
	    --show-rc                                      \
	    --compression lz4                              \
	    --exclude-caches                               \
	    beta-backup:/opt/sauvegarde/data::$BACKUP_DATE \
	    /opt/zds/data

	# ... sauvegardes vers les dépôts externes ...
}


db_borg_backup()
{
	echo "** Database backups with borg..."

	echo "Backup database to the beta server..."
	borg create                                           \
	    --verbose                                         \
	    --filter AME                                      \
	    --list                                            \
	    --stats                                           \
	    --show-rc                                         \
	    --compression zstd,6                              \
	    --exclude-caches                                  \
	    --info                                            \
	    beta-backup:/opt/sauvegarde/db-borg::$BACKUP_DATE \
	    /var/backups/mysql

	# ... sauvegardes vers les dépôts externes ...
}


db_clean()
{
	echo "** Removing old local backups of the database..."
	WD=/var/backups/mysql

	BACKUPS="`echo $WD/*-*/ | tr ' ' '\n' | sort -nr`"

	TO_DELETE="`
		echo "$BACKUPS" | awk '
			BEGIN { full=0 }
			{ if (full > 1) { print $0 } }
			/full/ { full++ }
		'
	`"

	echo "To be removed: $TO_DELETE"
	[ -z "$TO_DELETE" ] || rm -r $TO_DELETE
}


echo "Starting script ($(date))"

full=0
if [ "$#" -ge 1 ] && [ "$1" = "full" ]; then
	full=1
	echo "** Starting a local full backup of the database..."
	db_local_backup full
else
	echo "** Starting a local incremental backup of the database..."
	db_local_backup
fi

data_borg_backup

db_borg_backup

if [ "$(date '+%H')" -eq "04" ]; then
	db_clean
fi

if [ $full -eq 1 ]; then
	curl -s -m 10 --retry 5 $(cat /root/healthchecks/prod-sauvegarde-complete.txt)
else
	curl -s -m 10 --retry 5 $(cat /root/healthchecks/prod-sauvegarde-incrementale.txt)
fi
echo # to make a newline after the "OK" written by curl

echo "End of script ($(date))"
