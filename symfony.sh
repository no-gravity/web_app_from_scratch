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



# =========================
# Let's install PHP/Symfony
# =========================

# Install PHP runtime
apt install -y unzip git php php-xml

# Install composer, a PHP package manager - see https://getcomposer.org/download/
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

# Create a project from the website-skeleton template
cd /var/www
composer create-project symfony/website-skeleton my-project --no-interaction



# ====================
# Let's install Apache
# ====================

apt install -y apache2 libapache2-mod-php
cat << 'EOF' > /etc/apache2/sites-enabled/000-default.conf
ServerName my-project.local
<VirtualHost *:80>
    DocumentRoot /var/www/my-project/public
</VirtualHost>
EOF
service apache2 start

# You should now be able to see a dummy website under http://localhost/



# ==================================
# Create a controller and a template
# ==================================

cd my-project
bin/console make:controller HomepageController

# modify the controller to respond to GET / instead of GET /homepage
sed 's:/homepage:/:' -i src/Controller/HomepageController.php 

# The contents of http://localhost/ are served from
# - the controller template templates/homepage/index.html.twig
# - the base template templates/base.html.twig



# =======================
# Let's add user accounts
# =======================

# ... To be written ...
