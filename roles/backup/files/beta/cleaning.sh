#!/bin/sh

# We keep the data backups for last 60 days and remove the rest
sudo -u zds-prod /usr/local/bin/borg prune --keep-within 60d --list --stats /opt/sauvegarde/data/
sudo -u zds-prod /usr/local/bin/borg prune --keep-within 60d --list --stats /opt/sauvegarde/db-borg/
