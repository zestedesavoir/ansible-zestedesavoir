#!/bin/sh

set -e

echo "Starting script ($(date))"

# We keep the data backups for last 60 days and remove the rest
echo "** data **"
sudo -u zds-prod /usr/local/bin/borg prune --keep-within 60d --list --stats /opt/sauvegarde/data/
echo "** db **"
sudo -u zds-prod /usr/local/bin/borg prune --keep-within 60d --list --stats /opt/sauvegarde/db-borg/
echo "** matomo **"
sudo -u zds-matomo /usr/local/bin/borg prune -m 2 --keep-within 10d --list --stats /opt/sauvegarde/matomo/

curl -s -m 10 --retry 5 $(cat /root/healthchecks-backup-cleaning-url)
echo # to make a newline after the "OK" written by curl

echo "End of script ($(date))"
