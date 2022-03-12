#!/bin/sh

set -eu

WD=/var/backups/mysql
LATEST=$WD/latest

PREVIOUS=`readlink -f $LATEST`
NEXT=$WD/`date '+%Y%m%d-%H%M'`


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
