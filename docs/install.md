# Installation minimale

## Version simple, rapide et efficace

```shell
make install
source venv/bin/activate
```

## Version détaillée

```shell
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