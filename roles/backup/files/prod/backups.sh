#!/bin/sh

set -eu

readonly BORG126=/usr/local/bin/borg1.2.6
readonly BORG1117=/usr/local/bin/borg
readonly BORG_OPTIONS="--list --verbose --filter AME --show-rc --compression zstd,6 --exclude-caches --info" # --stats
readonly BACKUP_DATE=`date '+%Y%m%d-%H%M'`
readonly DATA_SAVED_DIR=/opt/zds/data
readonly DB_SAVED_DIR=/var/backups/mysql

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

backup2beta2023()
{
	echo "Backup data to the 2023 beta server..."
	date
	$BORG126 create $BORG_OPTIONS                           \
	    beta-backup-2023:/opt/sauvegarde/data::$BACKUP_DATE \
	    $DATA_SAVED_DIR
	rc_data=$?
	date

	echo "Backup database to the 2023 beta server..."
	date
	$BORG126 create $BORG_OPTIONS                         \
	    beta-backup-2023:/opt/sauvegarde/db::$BACKUP_DATE \
	    $DB_SAVED_DIR
	rc_db=$?
	date

	return $((rc_data+rc_db))
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
	[ -z "$TO_DELETE" ] || rm -r $TO_DELETE
}


# Big separator in log between executions of the script:
echo "#######################################################################################################################"
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

# Exception handling: if the first backup fails, we don't want it to stop the others.
set +e
backup2beta2023; err1=$?
echo
# Ajouter ici les autres appels aux fonctions de sauvegarde
# backup2toto; err2=?
# echo
err=$((err1+err2))
set -e

if [ "$(date '+%H')" -eq "04" ]; then
	db_clean
fi

if [ $err -gt 0 ]; then
	echo "At least one backup failed!"
else
	echo "All backups completed successfully."
	if [ $full -eq 1 ]; then
		curl -s -m 10 --retry 5 $(cat /root/healthchecks/prod-sauvegarde-complete.txt)
	else
		curl -s -m 10 --retry 5 $(cat /root/healthchecks/prod-sauvegarde-incrementale.txt)
	fi
	echo # to make a newline after the "OK" written by curl
fi

echo "End of script ($(date))"
# Big separator in log between executions of the script:
echo "#######################################################################################################################"
echo
echo
echo
