# ======================
# From Debian to Web App
# ======================

# This page contains a list of terminal commands that
# create a Flask web application with routing, templates
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
mkdir mysite
cd mysite

mkdir mysite
mkdir logs
mkdir static

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
    return "Hello from Flask!"
if __name__ == "__main__":
    app.run()
EOF

# ==========================
# Let's create our wsgi file
# ==========================
cat << 'EOF' > wsgi.py
#!/usr/bin/python
import sys
sys.path.insert(0,"/var/www/")
from mysite.app import app as application
EOF

# ==========================
# Let's configure APACHE2
# ==========================
cat << 'EOF' > /etc/apache2/sites-enabled/000-default.conf
ServerName mysite.local
WSGIPythonPath /var/www/mysite
<VirtualHost *:80>
    WSGIScriptAlias / /var/www/mysite/wsgi.py
    <Directory /var/www/mysite/mysite>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>
</VirtualHost>
EOF

chown -R www-data:www-data .

service apache2 start

# A Hello, World! Flask app is now running
# Now 127.0.0.1 has the user page
read -p 'Flask is running'

# ===================
# Let's use templates
# ===================

mkdir templates

cat << 'EOF' > templates/index.html
<h1>Hello World</h1>
EOF

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
