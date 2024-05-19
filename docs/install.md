# Installation minimale

## Version simple, rapide et efficace

```sh
make install
source venv/bin/activate
```

## Version détaillée

```sh
# Création de l'environnement virtuel
python3 -m venv venv
# Activation de l'environnement
source venv/bin/activate
# Installation des dépendances Python
# - Ansible
# - Pre-commit
pip install -r requirements.txt
# Installation des hooks Pre-Commit
# - Ansible Lint pour avoir un code propre
pre-commit install
```


## Ruby

Surtout utile pour lancer localement ce qui est exécuté par GitHub Actions.


### Installation

```sh
sudo apt install bundler
bundle config set --local path 'vendor/bundle'
bundle install
```


### Exécuter localement kitchen

Pour lancer les tests:
```sh
LANG=C.UTF-8 bundle exec kitchen test
```
Il y a un bug qui fait échouer les tests si la langue du système n'est pas l'anglais, d'où la variable d'environnement `LANG`.


### Mettre à jour les dépendances

```sh
bundle update
```
Cela modifie le fichier `Gemfile.lock`, qu'il faut committer.
