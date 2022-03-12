#!/bin/sh

# Script from https://borgbackup.readthedocs.io/en/stable/quickstart.html#automating-backups

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=ssh://root@scaleway.zestedesavoir.com/opt/sauvegarde/data

# See the section "Passphrase notes" for more infos.
#export BORG_PASSPHRASE='XYZl0ngandsecurepa_55_phrasea&&123'

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

DATE=`date '+%Y%m%d-%H%M'`

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

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

#borg prune                          \
#    --list                          \
#    --show-rc                       \
#    --keep-within 1w                \

#prune_exit=$?

# use highest exit code as global exit code
#global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=${backup_exit}

if [ ${global_exit} -eq 0 ]; then
    info "Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup and/or Prune finished with warnings"
else
    info "Backup and/or Prune finished with errors"
fi

exit ${global_exit}
