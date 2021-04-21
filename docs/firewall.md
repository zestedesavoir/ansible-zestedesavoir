# Documentation du pare-feu

Le pare-feu actuellement utilisé sur les serveurs de production et de bêta est `ufw`.

Les règles par défaut sont :

- accepter toutes les connexions sortantes ;
- rejeter toutes les connexions entrantes sauf celles sur les ports 80 (HTTP), 443 (HTTPS), 22 (SSH), 4949 (Munin)
  ainsi que 25, 465 et 587 (SMTP) avec le protocole TCP.

Commandes bonnes à savoir :

- `sudo ufw status verbose` pour lister les règles actuellement appliquées ;
- `sudo ufw insert 1 deny from IP` pour rejeter les connexions entrantes d'une IP ;
- `sudo ufw status numbered` puis `sudo ufw delete NOMBRE` pour supprimer une règle.

Deux ressources utiles :

- [Comment mettre en place un pare-feu avec UFW sur Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-20-04-fr)
- [ufw - Wifi ubuntu-fr](https://doc.ubuntu-fr.org/ufw)
