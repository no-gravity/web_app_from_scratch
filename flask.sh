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

# =================================================
# Let's install Flask & create our project folders
# =================================================

cd /var/www
apt install -y python3-flask
mkdir -p mysite
cd mysite

mkdir -p flasky
cd flasky

mkdir -p logs
mkdir -p static

# ====================
# Let's install Apache
# ====================
apt install -y apache2
apt install -y libapache2-mod-wsgi-py3

# =======================
# Let's create our app.py
# =======================

cat << 'EOF' > app.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def index():
    return "Hello, World!"

if __name__ == "__main__":
    app.run()
EOF

# ==========================
# Let's create our wsgi file
# ==========================
cat << 'EOF' > wsgi.py
#!/usr/bin/python
import sys
sys.path.insert(0,"/var/www/mysite/")
from flasky.app import app as application
EOF

# ==========================
# Let's configure APACHE2
# ==========================
cat << 'EOF' > /etc/apache2/sites-enabled/000-default.conf
<VirtualHost *:80>
    ErrorLog /var/www/mysite/flasky/logs/error.log
    CustomLog /var/www/mysite/flasky/logs/access.log combined
    WSGIDaemonProcess flasky user=www-data group=www-data threads=5
    WSGIProcessGroup flasky
    WSGIScriptAlias / /var/www/mysite/flasky/wsgi.py
    Alias /static/ /var/www/mysite/flasky/static
    <Directory /var/www/mysite/mysite>
        Order allow,deny
        Allow from all
        Require all granted
    </Directory>
</VirtualHost>
EOF

# move to mysite directory & change ownership
cd ../../

chown -R www-data:www-data mysite


service apache2 start

# A Hello, World! Flask app is now running
# Now 127.0.0.1 has the user page
read -p 'Flask is running'

# ==========================================
# Let's use templates to return an HTML page
# ==========================================
cd mysite/flasky

mkdir templates

cat << 'EOF' > templates/index.html
<h1>Hello Flasky</h1>
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

# =====================================
# Let's modify app.py to return template
# =====================================
cat << 'EOF' > app.py
from flask import Flask, render_template
app = Flask(__name__)

@app.route("/")
def index():
    return render_template('index.html')

if __name__ == "__main__":
    app.run()
EOF


service apache2 restart

# Yay, we have a working base template!
read -p 'The base template is live! Hit enter to continue.'

