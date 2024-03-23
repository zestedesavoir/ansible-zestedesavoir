from .prod import *

# Required in Vagrant since Django 4
# (see https://docs.djangoproject.com/en/5.0/releases/4.0/#csrf-trusted-origins-changes-4-0)
CSRF_TRUSTED_ORIGINS = ["http://127.0.0.1:8080", "http://localhost:8080"]
