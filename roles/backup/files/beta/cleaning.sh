#!/bin/sh

# Get the list of full database backups, excluding the 60 more recent ones:
db_full_backups_to_remove=`find /opt/sauvegarde/db -type d -name *-full | sort -nr | tail -n +61`

for db_full_backup in $db_full_backups_to_remove
do
    # We remove the 0315-full part to keep only the day
    db_daily_backups=`echo $db_full_backup | head -c -10`
    # We remove the full database backup, its incremental database backups and logs:
    echo "rm -r $db_daily_backups*"
    rm -r $db_daily_backups*
done

# We keep the data backups for last 60 days and remove the rest
borg prune --keep-within 60d --list /opt/sauvegarde/data/
