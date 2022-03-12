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
