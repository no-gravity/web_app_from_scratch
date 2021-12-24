# ======================
# From Debian to Web App
# ======================

# This page contains a list of terminal commands that
# create a Django web application with routing, templates
# and user accounts.
#
# You can start from a fresh debian installation. Or with a
# fresh debian container:
#
# docker run -v $(pwd):/var/www --rm -it -p 80:80 debian:11-slim
#  
# You can copy+paste each command to see the application take
# shape or copy the whole page and paste it in one go.
# You can also download it here: https://...

# ======================
# Let's configure Debian
# ======================

# Do not show dialogs during the upgrade
export DEBIAN_FRONTEND=noninteractive
# Update the packages
apt update -y && apt upgrade -y

# ====================
# Let's install Django
# ====================

cd /var/www
apt install -y python3-django
django-admin startproject mysite
cd mysite
python3 manage.py migrate

# ====================
# Let's install Apache
# ====================

apt install -y apache2
apt install -y libapache2-mod-wsgi-py3

cat << 'EOF' > /etc/apache2/sites-enabled/000-default.conf
WSGIPythonPath /var/www/mysite
<VirtualHost *:80>
    WSGIScriptAlias / /var/www/mysite/mysite/wsgi.py
    <Directory /var/www/mysite/mysite>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>
</VirtualHost>
EOF

service apache2 start

# Yay, we have a working Django instance!
# Now 127.0.0.1 has the user page
# And 127.0.0.1/admin/ has an admin page
read -p 'Django is running! Hit enter to continue.'

# ===================
# Let's use templates
# ===================

# mysite/ in mysite/ is the code dir in Django
cd mysite

mkdir templates

cat << 'EOF' > templates/index.html
<h1>Hello World</h1>
EOF

cat << 'EOF' > views.py
from django.shortcuts import render
def index(request):
    return render(request, 'index.html')
EOF

cat << 'EOF' > urls.py
from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.index),
]
EOF

cat << 'EOF' >> settings.py
INSTALLED_APPS += ['mysite']
EOF

service apache2 restart

# Yay, we have static site!
read -p 'Serving a static site! Hit enter to continue.'

# =========================
# Let's use a base template
# =========================

# Let's create a base template 
cat << 'EOF' > templates/base.html
<!DOCTYPE html>
<html>
<head>
    <title>Hello World</title>
    <style>
        body {background: #60a060}
    </style>
</head>
<body>{% block content %}{% endblock %}</body>
</html>
EOF

# And use it for the index page:
cat << 'EOF' > templates/index.html
{% extends "base.html" %}
{% block content %}
    <h1>Hello World</h1>
{% endblock %}
EOF

service apache2 restart

# Yay, we have a working base template!
read -p 'The base template is live! Hit enter to continue.'

# =======================
# Let's add user accounts
# =======================

# ... To be written ...
