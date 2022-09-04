#!/bin/sh

set -e

echo "Starting script ($(date))"

DATA_DB_RULES="--keep-within 30d -w 8 -m 3"
echo "** data ** ($(date))"
sudo -u zds-prod /usr/local/bin/borg prune $DATA_DB_RULES --list --stats /opt/sauvegarde/data/
echo "** db ** ($(date))"
sudo -u zds-prod /usr/local/bin/borg prune $DATA_DB_RULES --list --stats /opt/sauvegarde/db-borg/
echo "** matomo ** ($(date))"
sudo -u zds-matomo /usr/local/bin/borg prune -m 2 --keep-within 10d --list --stats /opt/sauvegarde/matomo/

curl -s -m 10 --retry 5 $(cat /root/healthchecks-backup-cleaning-url)
echo # to make a newline after the "OK" written by curl

echo "End of script ($(date))"
