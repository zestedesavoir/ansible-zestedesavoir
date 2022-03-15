#!/bin/sh

# Script from https://borgbackup.readthedocs.io/en/stable/quickstart.html#automating-backups

# Setting this, so the repo does not need to be given on the commandline:

# See the section "Passphrase notes" for more infos.
#export BORG_PASSPHRASE='XYZl0ngandsecurepa_55_phrasea&&123'

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

DATE=`date '+%Y%m%d-%H%M'`

BORG_REPO=ssh://root@scaleway.zestedesavoir.com/opt/sauvegarde/data \
borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
                                    \
    ::$DATE                         \
    /opt/zds/data                   \

backup_exit1=$?

# ... here go the external backup commands ...

# backup_exit2=$?
backup_exit2=$backup_exit1

global_exit=$(( backup_exit1 > backup_exit2 ? backup_exit1 : backup_exit2 ))

if [ ${global_exit} -eq 0 ]; then
    info "Backups finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup finished with warnings"
else
    info "Backup finished with errors"
fi

exit ${global_exit}
