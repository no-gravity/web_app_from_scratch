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

# =====================
# Let's install Symfony
# =====================

apt install -y unzip git php php-xml composer
cd /var/www
composer create-project symfony/website-skeleton mysite --no-interaction
chown -R www-data:www-data mysite
cd mysite

# apache-pack will write the public/.htaccess file that
# routes all requests to public/index.php.
# Unfortunately, this will ask a question and you will
# have to manually type "y" and enter. I have not yet
# found a nice way to automate this.
composer require symfony/apache-pack

# ====================
# Let's install Apache
# ====================

apt install -y apache2 libapache2-mod-php
cat << 'EOF' > /etc/apache2/sites-enabled/000-default.conf
ServerName mysite.local
<Directory /var/www/mysite/public>
    AllowOverride All
</Directory>
<VirtualHost *:80>
    DocumentRoot /var/www/mysite/public
</VirtualHost>
EOF
service apache2 start

# You should now be able to see a dummy website under http://localhost/



# ==================================
# Create a controller and a template
# ==================================

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
