#!/bin/sh

set -eu

WD=/var/backups/mysql


# Backups

BACKUPS="`echo $WD/*-*/ | tr ' ' '\n' | sort -nr`"

TO_DELETE="`
	echo "$BACKUPS" | awk '
		BEGIN { full=0 }
		{ if (full > 1) { print $0 } }
		/full/ { full++ }
	'
`"

[ -z "$TO_DELETE" ] || rm -r $TO_DELETE


# Logs

LOGS="`echo $WD/*-*.log | tr ' ' '\n' | sort -nr`"

TO_DELETE_LOGS="`
	echo "$LOGS" | awk '
		BEGIN { full=0 }
		{ if (full > 1) { print $0 } }
		/full/ { full++ }
	'
`"

[ -z "$TO_DELETE_LOGS" ] || rm -r $TO_DELETE_LOGS
