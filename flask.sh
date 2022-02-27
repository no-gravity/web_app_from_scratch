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
apt install -y python3-flask python3-flask-login python3-flask-sqlalchemy
mkdir mysite
cd mysite

# ====================
# Let's install Apache
# ====================

apt install -y apache2
apt install -y libapache2-mod-wsgi-py3

# ===============================
# Let's create our app base file
# Basic reading on blueprints available at
# https://stackoverflow.com/questions/24420857/what-are-flask-blueprints-exactly
# ===============================

cat << 'EOF' > __init__.py
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager

# init SQLAlchemy so we can use it later in our models
db = SQLAlchemy()

def create_app():
    app = Flask(__name__)

    # before the first request initialize the DB
    @app.before_first_request
    def create_tables():
        db.create_all()


    app.config['SECRET_KEY'] = os.environ.get('SECRET','secret-key-goes-here')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///db.sqlite'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)
    
    # user mgmt and default login view setting
    login_manager = LoginManager()
    login_manager.login_view = 'auth.login'
    login_manager.init_app(app)

    from .models import User

    # tell your flask app how to get a userr
    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))

    # blueprints are just reusable components & you can read about them below
    # https://stackoverflow.com/questions/24420857/what-are-flask-blueprints-exactly
    from .auth import auth as auth_blueprint
    app.register_blueprint(auth_blueprint)
    
    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    return app
EOF

# # ============================
# Let's create our auth.py file
# ==============================
cat << 'EOF' > auth.py
from flask_login import login_user, logout_user, @login_required
from flask import Blueprint, render_template, redirect, url_for, request, flash
from werkzeug.security import generate_password_hash, check_password_hash
from .models import User
from . import db

# name to be imported in __init__.py
auth = Blueprint('auth', __name__)

@auth.route('/login',methods=['GET','POST'])
def login():
    if request.method == 'GET':
        return render_template('login.html')

    else:
        username = request.form.get('username')
        password = request.form.get('password')
        remember = True if request.form.get('remember') else False

        user = User.query.filter_by(username=username).first()

        if not user or not check_password_hash(user.password, password):
            flash('Please check your login details and try again.')
            return redirect(url_for('auth.login')) 
    
        login_user(user, remember=remember)
        return redirect(url_for('main.profile'))

@auth.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'GET':
        return render_template('signup.html')
    
    else:
        username = request.form.get('username')
        password = request.form.get('password')

        user = User.query.filter_by(username=username).first() 

        if user: 
            flash('Email address already exists')
            return redirect(url_for('auth.signup'))

        new_user = User(username=username, password=generate_password_hash(password, method='sha256'))

        db.session.add(new_user)
        db.session.commit()

    return redirect(url_for('auth.login'))

@auth.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('main.index'))

EOF

# ======================================
# Let's create our main.py file
# This is the index and profile module
# ======================================
cat << 'EOF' > main.py
from flask import Blueprint, render_template
from flask_login import current_user, login_required
from . import db

main = Blueprint('main', __name__)

@main.route('/')
def index():
    return render_template('index.html')

@main.route('/profile')
@login_required
def profile():
    return render_template('profile.html',name=current_user.username)
EOF

# ======================================
# Let's create our models.py file
# This contains are user model
# ======================================
cat << 'EOF' > models.py
from flask_login import UserMixin
from . import db

# UserMixin saves us the trouble of implementing
# is_authenticated, is_active, is_anonymous, get_id methods
# needed by LoginManager
class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True) 
    username = db.Column(db.String(100), unique=True)
    password = db.Column(db.String(100))    
    
EOF

# Flask requiers all HTML content in templates folder
# so let's make one
mkdir templates

# =========================
# Let's create a base template
# =========================

# Let's create a base template
cat << 'EOF' > templates/base.html
<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Flask Auth Example</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.2/css/bulma.min.css" />
</head>

<body>
    <section class="hero is-primary is-fullheight">

        <div class="hero-head">
            <nav class="navbar">
                <div class="container">
                    <div id="navbarMenuHeroA" class="navbar-menu">
                        <div class="navbar-end">
                            <a href="{{ url_for('main.index') }}" class="navbar-item">
                                Home
                            </a>
                            {% if current_user.is_authenticated %}
                            <a href="{{ url_for('main.profile') }}" class="navbar-item">
                                Profile
                            </a>
                            {% endif %}
                            {% if not current_user.is_authenticated %}
                            <a href="{{ url_for('auth.login') }}" class="navbar-item">
                                Login
                            </a>
                            <a href="{{ url_for('auth.signup') }}" class="navbar-item">
                                Sign Up
                            </a>
                            {% endif %}
                            {% if current_user.is_authenticated %}
                            <a href="{{ url_for('auth.logout') }}" class="navbar-item">
                                Logout
                            </a>
                            {% endif %}
                        </div>
                    </div>
                </div>
            </nav>
        </div>

        <div class="hero-body">
            <div class="container has-text-centered">
                {% block content %}
                {% endblock %}
            </div>
        </div>
    </section>
</body>

</html>
EOF

# And now time for the index template
cat << 'EOF' > templates/index.html
{% extends "base.html" %}

{% block content %}
<h1 class="title">
  Hello, Flasky
</h1>
{% endblock %}
EOF

# A nice login template
cat << 'EOF' > templates/login.html
{% extends "base.html" %}

{% block content %}
<div class="column is-4 is-offset-4">
    <h3 class="title">Login</h3>
    <div class="box">
        {% with messages = get_flashed_messages() %}
        {% if messages %}
        <div class="notification is-danger">
            {{ messages[0] }}
        </div>
        {% endif %}
        {% endwith %}
        <form method="POST" action="/login">
            <div class="field">
                <div class="control">
                    Username: <input class="input is-large" type="text" name="username" placeholder="Your Username" autofocus="">
                </div>
            </div>

            <div class="field">
                <div class="control">
                    Password: <input class="input is-large" type="password" name="password" placeholder="Your Password">
                </div>
            </div>
            <div class="field">
                <label class="checkbox">
                    <input type="checkbox" name="remember">
                    Remember me
                </label>
            </div>
            <button class="button is-block is-info is-large is-fullwidth">Login</button>
        </form>
    </div>
</div>
{% endblock %}
EOF

# A profile screen
cat << 'EOF' > templates/profile.html
{% extends "base.html" %}

{% block content %}
<h1 class="title">
  Welcome, {{ name }}!
</h1>
{% endblock %}
EOF

# A signup screen
cat << 'EOF' > templates/signup.html
{% extends "base.html" %}

{% block content %}
<div class="column is-4 is-offset-4">
    <h3 class="title">Sign Up</h3>
    <div class="box">
        {% with messages = get_flashed_messages() %}
        {% if messages %}
        <div class="notification is-danger">
            {{ messages[0] }}. Go to <a href="{{ url_for('auth.login') }}">login page</a>.
        </div>
        {% endif %}
        {% endwith %}
        <form method="POST" action="/signup">
            <div class="field">
                <div class="control">
                    Username: <input class="input is-large" type="text" name="username" placeholder="Username" autofocus="">
                </div>
            </div>

            <div class="field">
                <div class="control">
                    Password: <input class="input is-large" type="password" name="password" placeholder="Password">
                </div>
            </div>

            <button class="button is-block is-info is-large is-fullwidth">Sign Up</button>
        </form>
    </div>
</div>
{% endblock %}
EOF

cd /var/www/mysite

# ==========================
# Let's create our wsgi file
# more reading here 
# https://flask.palletsprojects.com/en/1.1.x/deploying/mod_wsgi/
# ==========================
cat << 'EOF' > wsgi.py
#!/usr/bin/python
import sys
sys.path.insert(0,"/var/www/")
from mysite import create_app
application = create_app()
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

# Yay, we have a working base template!
read -p 'Our app is now live! Hit enter to continue.'
