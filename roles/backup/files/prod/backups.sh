#!/bin/bash

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


do_full_db_backup=0
parallel_remote_backup=0  # Don't parallelize borg backups by default, since it mixes up log ouput
while [ $# -gt 0 ]; do
	case $1 in
		full ) do_full_db_backup=1
			;;
		--parallel-remote-backup ) parallel_remote_backup=1
			;;
	esac
	shift
done

if [ -e /opt/zds/webroot/maintenance.html ]; then
	echo "Maintenance is in progress, enabling parallel remote borg backups"
	parallel_remote_backup=1
fi


# Big separator in log between executions of the script:
echo "#######################################################################################################################"
echo "Starting script ($(date))"

if [ $do_full_db_backup -eq 1 ]; then
	echo "** Starting a local full backup of the database..."
	db_local_backup full
else
	echo "** Starting a local incremental backup of the database..."
	db_local_backup
fi
echo "done ($(date))."

echo

# Exception handling: if the first backup fails, we don't want it to stop the others.
set +e
err1=1
# err2=2
if [ $parallel_remote_backup -eq 1 ]; then
	taskset --cpu-list -p 0,1 $$  # use only 2 cores for parallel backup, to leave the third core available for other processes

	backup2beta2023 &
	pid_beta=$!
	# Ajouter ici les autres appels aux fonctions de sauvegarde
	# backup2toto &
	# pid_toto=$!

	wait $pid_beta
	err1=$?
	# wait $pid_toto
	# err2=$?
else
	backup2beta2023; err1=$?
	echo
	# Ajouter ici les autres appels aux fonctions de sauvegarde
	# backup2toto; err2=?
	# echo
fi
err=$((err1+err2))
set -e

echo

if [ "$(date '+%H')" -eq "04" ]; then
	db_clean
fi

if [ $err -gt 0 ]; then
	echo "At least one backup failed!"
else
	echo "All backups completed successfully."
	if [ $do_full_db_backup -eq 1 ]; then
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
