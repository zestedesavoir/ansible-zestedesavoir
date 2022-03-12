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
