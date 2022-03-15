#!/bin/sh

BASE=/opt/sauvegarde

DATE=`date '+%Y%m%d-%H%M'`

borg create                          \
    --verbose                        \
    --filter AME                     \
    --list                           \
    --stats                          \
    --show-rc                        \
    --compression zstd,6             \
    --exclude-caches                 \
    --info                           \
                                     \
    beta-backup:$BASE/db-borg::$DATE \
    /var/backups/mysql
