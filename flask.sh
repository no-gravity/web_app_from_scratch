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
    <Directory /var/www/mysite>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>
</VirtualHost>
EOF

chown -R www-data:www-data .

service apache2 start

# A Hello, World! Flask app is now running
# You can see it on 127.0.0.1
read -p 'Flask is running! Hit enter to continue.'

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

# ===========================================
# Let's add user accounts
# first we install the necessary dependencies
# ===========================================

apt install -y python3-flask-login python3-flask-sqlalchemy python3-flaskext.wtf

# Let's create the forms to render for login & registration
cat << 'EOF' > forms.py
from wtforms import Form, BooleanField, StringField, PasswordField, validators
class UserRegisterForm(Form):
    username = StringField('Username', [validators.Length(min=1, max=100)])
    email = StringField('Email Address', [validators.Length(max=100)])
    password = PasswordField('Password', [
        validators.DataRequired(),
        validators.EqualTo('password2', message='Passwords must match')
    ])
    password2 = PasswordField('Repeat Password')
class UserLoginForm(Form):
    username = StringField('Username', [validators.Length(min=1, max=100)])
    password = PasswordField('Password', [
        validators.DataRequired(),
        validators.EqualTo('password2', message='Passwords must match')
    ])
EOF

# Let's create the user model
cat << 'EOF' > models.py
from flask_login import UserMixin
from app import db
class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True)
    email = db.Column(db.String(100), unique=True)
    password = db.Column(db.String(100))
EOF

# Let's create the main blueprint
cat << 'EOF' > main.py
from flask import Blueprint, render_template
from flask_login import current_user
from app import db
main = Blueprint('main', __name__)
@main.route('/')
def index():
    return render_template('index.html')
EOF

# Let's create the auth blueprint
cat << 'EOF' > auth.py
from flask_login import login_user, logout_user
from flask import Blueprint, render_template, redirect, url_for, request, flash
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import or_
from forms import UserRegisterForm, UserLoginForm
from models import User
from app import db
auth = Blueprint('auth', __name__)
@auth.route('/login', methods=['GET','POST'])
def login():
    form = UserLoginForm(request.form)
    if request.method == 'GET':
        return render_template('login.html', form=form)
    else:
        username = form.username.data
        password = form.password.data
        user = User.query.filter_by(username=username).first()

        if not user or not check_password_hash(user.password, password):
            flash('Please check your login details and try again.')
            return render_template('login.html', form=form)

        login_user(user)
        return render_template('index.html', user=user)
@auth.route('/register', methods=['GET', 'POST'])
def register():
    form = UserRegisterForm(request.form)
    if request.method == 'POST' and form.validate():
        new_user = User(
            username=form.username.data,
            email=form.email.data,
            password=generate_password_hash(form.password.data, method='sha256')
            )
        user = User.query.filter(or_(User.username==form.username.data, User.email==form.email.data)).first()
        if user:
            flash('Username/Email taken, try with different username.')
            return render_template('register.html', form=form)

        db.session.add(new_user)
        db.session.commit()
        return redirect(url_for('auth.login'))
    else:
        return render_template('register.html', form=form)
@auth.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('main.index'))
EOF

# ==================================================================================
# Let's modify our app base file
# Basic reading on blueprints available at
# https://stackoverflow.com/questions/24420857/what-are-flask-blueprints-exactly
# ==================================================================================
cat << 'EOF' > app.py
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
# init SQLAlchemy so we can use it later in our models
db = SQLAlchemy()
def create_app():
    app = Flask(__name__)

    app.config['SECRET_KEY'] = os.environ.get('SECRET','secret-key-goes-here')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////var/www/mysite/flask.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    db.init_app(app)

    @app.before_first_request
    def create_tables():
        print("Creatingg DB")
        db.create_all()

    login_manager = LoginManager()
    login_manager.login_view = 'auth.login'
    login_manager.init_app(app)
    from models import User
    @login_manager.user_loader
    def load_user(user_id):
        # since the user_id is just the primary key of our user table, use it in the query for the user
        return User.query.get(int(user_id))
    # blueprint for auth routes in our app
    from auth import auth as auth_blueprint
    app.register_blueprint(auth_blueprint)
    # blueprint for non-auth parts of app
    from main import main as main_blueprint
    app.register_blueprint(main_blueprint)
    return app
EOF

# Let's create a base template
cat << 'EOF' > templates/base.html
<!DOCTYPE html>
<html>
<head>
    <title>Hello World</title>
    <style>
        body {background: #60a060}
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.2/css/bulma.min.css" />
</head>
<body>{% block content %}{% endblock %}</body>
</html>
EOF

# And use it for the index page:
cat << 'EOF' > templates/index.html
{% extends "base.html" %}
{% block content %}
{% if not user %}
<h1>Hello, World!</h1>
<a href="{{ url_for('auth.login') }}"><button>Login</button></a>
<a href="{{ url_for('auth.register') }}"><button>Register</button></a>
{% elif user.is_authenticated %}
<h1>Hello, {{ user.username }}!</h1>
<h3>You are logged in as {{ user.username }} </h3>
<a href="{{ url_for('auth.logout') }}"><button>Logout</button></a>
{% endif %}
{% endblock %}
EOF

# Create the login template
cat << 'EOF' > templates/login.html
{% extends 'base.html' %}
{% block content %}
{% with messages = get_flashed_messages() %}
{% if messages %}
<div class="notification is-danger">
    {{ messages[0] }}. Go to <a href="{{ url_for('auth.login') }}">login page</a>.
</div>
{% endif %}
{% endwith %}
<form method="POST" action="/login">
    {{ form.csrf_token }}
    {{ form.username.label }} {{ form.username }}
    {{ form.password.label }} {{ form.password }}
    <button type="submit">Log In</button>
</form>
<p>
    Dont have an Account? <a href="{{ url_for('auth.register') }}"><button>Register</button></a>
</p>
{% endblock %}
EOF

# And use it for the index page:
cat << 'EOF' > templates/index.html
{% extends "base.html" %}
{% block content %}
{% if not user %}
<h1>Hello, World!</h1>
<a href="{{ url_for('auth.login') }}"><button>Login</button></a>
<a href="{{ url_for('auth.register') }}"><button>Register</button></a>
{% elif user.is_authenticated %}
<h1>Hello, {{ user.username }}!</h1>
<h3>You are logged in as {{ user.username }} </h3>
<a href="{{ url_for('auth.logout') }}"><button>Logout</button></a>
{% endif %}
{% endblock %}
EOF

# Create the user registration template
cat << 'EOF' > templates/register.html
{% extends 'base.html' %}
{% block content %}
{% with messages = get_flashed_messages() %}
{% if messages %}
<div class="notification is-danger">
    {{ messages[0] }}. Go to <a href="{{ url_for('auth.login') }}">login page</a>.
</div>
{% endif %}
{% endwith %}
<form method="POST">
    {{ form.csrf_token }}
    {{ form.username.label }} {{ form.username }}
    {{ form.email.label }} {{ form.email }}
    {{ form.password.label }} {{ form.password }}
    {{ form.password2.label }} {{ form.password2 }}
    {% if form.email.errors %}
    <ul class="errors">
        {% for error in form.email.errors %}
        <li>{{ error }}</li>
        {% endfor %}
    </ul>
    {% endif %}
    <button type="submit">Sign Up</button>
</form>
<p>
    Already have an Account? <a href="{{ url_for('auth.login') }}"><button>Register</button></a>
</p>
{% endblock %}
EOF

cat << 'EOF' > db_init.py
from app import create_app, db
import models
db.create_all(app=create_app())
EOF

# ==========================
# Let's amend our wsgi file
# ==========================
cat << 'EOF' > wsgi.py
#!/usr/bin/python
import sys
sys.path.insert(0,"/var/www/")
from mysite.app import create_app
application = create_app()
EOF

export FLASK_APP=app.py

# initialize the database
python3 db_init.py

chown -R www-data:www-data .

service apache2 restart

# Yay, we have a working base template!
read -p 'User accounts are live! Hit enter to continue.'
