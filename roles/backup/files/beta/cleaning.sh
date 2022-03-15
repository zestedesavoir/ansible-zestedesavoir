#!/bin/sh

# We keep the data backups for last 60 days and remove the rest
borg prune --keep-within 60d --list /opt/sauvegarde/data/
borg prune --keep-within 60d --list /opt/sauvegarde/db-borg/
