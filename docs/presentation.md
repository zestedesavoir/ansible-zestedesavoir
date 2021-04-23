# Présentation générale

Nous avons actuellement deux serveurs :

- le serveur de production (« la prod ») à l'adresse `zestedesavoir.com` ;
- le serveur de préproduction (« la bêta ») à l'adresse `beta.zestedesavoir.com`.

Ces deux serveurs doivent être identiques autant que possible pour pouvoir reproduire les bugs de la prod sur la bêta. Néanmoins, le système de sauvegarde de la base de données et des fichiers est mis en place uniquement sur le serveur de production.

## Logiciels utilisés

| Paramètre                                                    | Valeur               |
| ------------------------------------------------------------ | -------------------- |
| Système d'exploitation                                       | Debian 10 « Buster » |
| Serveur web                                                  | nginx                |
| Interface WSGI (entre le serveur web et Django)              | Gunicorn             |
| Base de donnée                                               | MariaDB              |
| Moteur de recherche                                          | ElasticSearch        |
| Outil de surveillance du système d'exploitation et des requêtes de Zeste de Savoir * | Munin                |
| Outil de surveillance des erreurs de Zeste de Savoir *       | Sentry               |
| Outil pour les certificats TLS                               | Certbot              |

\* Actuellement, les deux outils de surveillance sont installés sur un serveur à part du serveur de production. (Un serveur appartenant à [vhf] pour le Munin et un serveur appartenant à [Sandhose] pour le Sentry.)

## Arborescence des fichiers

| Paramètre                                                    | Valeur                                     |
| ------------------------------------------------------------ | ------------------------------------------ |
| Utilisateur et groupe local                                  | `zds` et `zds`                             |
| Dossier dédié à `zds-site`                                   | `/opt/zds/app`                             |
| Dossier avec les données importantes à sauvegarder (dépôts Git des contenus et images des galeries) | `/opt/zds/data`                            |
| Base de données à sauvegarder (et ses sauvegardes régulières) | `/var/lib/mysql` (et `/var/backups/mysql`) |
| Fichiers de journalisation                                   | `/var/log/zds`                             |

<!-- Liens vers les pseudos -->

[vhf]: https://github.com/vhf
[Sandhose]: https://github.com/sandhose