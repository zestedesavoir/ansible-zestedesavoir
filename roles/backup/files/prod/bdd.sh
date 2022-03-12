#!/bin/sh

BASE=opt/sauvegarde

echo "Synchronisation des sauvegardes de la base de donnée"
rsync -azvr /var/backups/mysql/ root@scaleway.zestedesavoir.com:/$BASE/db
