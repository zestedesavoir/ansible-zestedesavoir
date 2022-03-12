# Sauvegardes de Zeste de Savoir

Zeste de Savoir c'est une communauté mais aussi un site web avec ses membres, ses contenus, ses messages, etc. Que faire pour ne pas perdre tout ça ?

Dans le cas de Zeste de Savoir, deux points sont critiques :

- la base de données avec les utilisateurs, les messages, les contenus, etc. (dans `/var/lib/mysql`) ;
- les fichiers importants, c'est-à-dire les dépôts Git des contenus et les galeries d'images (dans `/opt/zds/data`).

Le reste (code source, configuration du serveur, etc) n'est finalement pas très important car tout est présent sur Github et un nouveau serveur peut être rapidement installé !

Deux sauvegardes de la prod sont actuellement en place :

- une sauvegarde sur un serveur appartenant à Sandhose, dont je ne parlerais pas ici ;
- une sauvegarde sur le serveur de bêta, dont je vais parler ici.

## Comment est mise en place la sauvegarde ?

### Sur le serveur de prod

Pour les fichiers importants, il n'y a pas de sauvegarde sur le serveur de prod lui-même. Par contre, la base de données fait l'objet :

- d'une sauvegarde complète chaque jour à 3h15 ;
- d'une sauvegarde incrémentale aux heures paires, donc toutes les deux heures.

Ces sauvegardes sont disponibles dans le dossier `/var/backups/mysql` avec comme nom la date et l'heure de la sauvegarde (au format `AAAAMMJJ-HHMM`). On supprime au fur et à mesure les anciennes sauvegardes pour libérer de l'espace disque.

On utilise l'utilitaire `cron` pour lancer ces sauvegardes :

```cron
# min hour dom month dow command
0 */2 * * * /var/backups/mysql/backup.sh
15 3 * * * /var/backups/mysql/backup.sh full
15 4 * * * /var/backups/mysql/cleanup.sh
```

Les scripts [backup.sh](../roles/backup/files/prod/backup.sh) et
[cleanup.sh](../roles/backup/files/prod/cleanup.sh) sont disponibles dans ce
dépôt.


### Sur le serveur de bêta

On utilise :

- rsync pour les sauvegardes de la base de données ;
- [BorgBackup](https://borgbackup.readthedocs.io/en/stable/index.html) pour les fichiers importants.

Sur la bêta et sur la prod, `borg` est installé en récupérant les binaires
fournis par BorgBackup, plutôt que d'utiliser la version des dépôts Debian qui
est un peu veillissante. L'installation est faite comme recommandée par la
[documentation](https://borgbackup.readthedocs.io/en/stable/installation.html#standalone-binary) :
```sh
wget https://github.com/borgbackup/borg/releases/download/1.1.17/borg-linux64
mv borg-linux64 /usr/local/bin/borg
chown root:root /usr/local/bin/borg
chmod 755 /usr/local/bin/borg
```
On reste actuellement sur la branche 1.1.*, car comme dit la
[documentation](https://borgbackup.readthedocs.io/en/stable/changes.html#version-1-2-0-2022-02-22-22-02-22) :
*do you already want to upgrade? 1.1.x also will get fixes for a while*.

Un volume dédié aux sauvegardes de 50 Go est monté sur `/opt/sauvegarde` sur le serveur de bêta et contient :

- les sauvegardes de la base de données dans `/opt/sauvegarde/db` (l'équivalent de `/var/backups/mysql` mais sans la suppression des anciennes sauvegardes) ;
- les sauvegardes des fichiers importants dans `/opt/sauvegarde/data` (que l'on initialise au préalable avec `borg init --encryption=none /opt/sauvegarde/data` avec l'utilisateur `root`).

On utilise l'utilitaire `cron` *depuis le serveur de prod* pour envoyer les données vers le serveur de bêta :

```cron
# min hour dom month dow command
0 */2 * * * /root/sauvegarde-vers-la-beta/donnees.sh
5 */2 * * * /root/sauvegarde-vers-la-beta/bdd.sh
15 3 * * * /root/sauvegarde-vers-la-beta/donnees.sh
20 3 * * * /root/sauvegarde-vers-la-beta/bdd.sh
```

Les scripts [donnees.sh](../roles/backup/files/prod/donnees.sh) et
[bdd.sh](../roles/backup/files/prod/bdd.sh) sont disponibles dans ce dépôt.


Enfin, [cleaning.sh](../roles/backup/files/beta/cleaning.sh) est le script qui
s'occupe de garder les 60 derniers jours de sauvegardes et de supprimer le
reste. Il est lancé chaque jour sur la bêta avec l'utilitaire `cron` pour
garder toujours assez d'espace libre sur le disque dédié aux sauvegardes :
```cron
# min hour dom month dow command
0 5 * * * /opt/sauvegarde/cleaning.sh
```


### Précisions concernant BorgBackup

Ce petit logiciel est installé à la fois sur le serveur de bêta et le serveur de prod tel que recommandé par la documentation ([Quickstart > Remote repositories](https://borgbackup.readthedocs.io/en/stable/quickstart.html#remote-repositories)). Par défaut, il n'est pas très verbeux donc il ne faut pas hésiter à lui demander une barre de progression avec `-p` ou un peu plus de verbosité avec `-v` !

Le cache de Borgbackup peut prendre plusieurs gigaoctets de données ce qui n'est pas souhaitable sur la bêta car l'espace disque y est assez restreint. Il a donc été désactivé en suivant les instructions de la documentation ([Frequently asked questions > The borg cache eats way too much disk space, what can I do?](https://borgbackup.readthedocs.io/en/stable/faq.html#the-borg-cache-eats-way-too-much-disk-space-what-can-i-do)).

## Comment est mise en place la restauration ?

C'est bien beau d'avoir des sauvegardes, mais fonctionneront-elles le jour où on en aura besoin ? Pour cela, il est impératif de vérifier que la restauration des sauvegardes fonctionne. Une bonne manière de tester cela est d'utiliser les sauvegardes du serveur de prod sur le serveur de bêta !

Le script [restore-from-prod.sh](../roles/backup/files/beta/restore-from-prod.sh)
permet de restaurer la bêta à partir des sauvegardes de la prod. Il faut
l'exécuter en root et préciser ce qu'il doit faire :
```sh
./restore-from-prod.sh all # restaure les données et la base de données de la dernière sauvegarde
./restore-from-prod.sh clean # supprime tous les éléments intermédiaires créés par la commande précédente
```
D'autres sous-commandes permettent de ne lancer que des portions du scripts.

## Perdre des données, cela n'arrive pas qu'aux autres !

Il y a déjà eu deux pertes de données dans l'histoire de Zeste de Savoir, avec à chaque fois un article explicatif :

- [Retour sur une semaine compliquée pour Zeste de Savoir](https://zestedesavoir.com/articles/194/retour-sur-une-semaine-compliquee-pour-zeste-de-savoir/)
- [Retour dans le passé pour ZdS :(](https://zestedesavoir.com/articles/1432/retour-dans-le-passe-pour-zds/)
