# Présentation générale

Nous avons actuellement trois serveurs :

- le serveur de production (« la prod ») à l'adresse `zestedesavoir.com` ;
- le serveur de préproduction (« la bêta ») à l'adresse `beta.zestedesavoir.com` ;
- le serveur qui héberge une instance de Matomo à l'adresse `matomo.zestedesavoir.com`.

Les deux serveurs qui hébergent une instance du site de Zeste de Savoir doivent
être identiques autant que possible pour pouvoir reproduire les bugs de la prod
sur la bêta. Néanmoins, le système de sauvegarde de la base de données et des
fichiers est mis en place uniquement sur le serveur de production.

## Logiciels utilisés

| Paramètre                                                    | Valeur               |
| ------------------------------------------------------------ | -------------------- |
| Système d'exploitation                                       | Debian 12 « Bookworm » |
| Serveur web                                                  | nginx                |
| Interface WSGI (entre le serveur web et Django)              | Gunicorn             |
| Base de donnée                                               | MariaDB              |
| Moteur de recherche                                          | Typesense            |
| Outil de surveillance du système d'exploitation et des requêtes de Zeste de Savoir | Munin                |
| Outil de surveillance des erreurs de Zeste de Savoir         | Sentry               |
| Outil pour les certificats TLS                               | Certbot              |


## Arborescence des fichiers

| Paramètre                                                    | Valeur                                     |
| ------------------------------------------------------------ | ------------------------------------------ |
| Utilisateur et groupe local                                  | `zds` et `zds`                             |
| Dossier dédié à `zds-site`                                   | `/opt/zds/app`                             |
| Dossier avec les données importantes à sauvegarder (dépôts Git des contenus et images des galeries) | `/opt/zds/data`                            |
| Base de données à sauvegarder (et ses sauvegardes régulières) | `/var/lib/mysql` (et `/var/backups/mysql`) |
| Fichiers de journalisation                                   | `/var/log/zds`                             |
