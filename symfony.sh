# ======================
# From Debian to Web App
# ======================

# This page contains a list of terminal commands that
# create a Symfony web application with routing, templates
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

apt install -y unzip git php php-xml php-curl composer
cd /var/www
composer create-project symfony/website-skeleton mysite --no-interaction
chown -R www-data:www-data mysite
cd mysite

# Ensure composer doesn't ask us questions about recipes and allow contrib recipes
composer config extra.symfony --json '{"allow-contrib": true}'
# apache-pack will write the public/.htaccess file that
# routes all requests to public/index.php.
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

# Yay, we have a working Symfony instance!
# You can see it at 127.0.0.1
read -p 'Symfony is running! Hit enter to continue.'

# ===================
# Let's use templates
# ===================

cat << 'EOF' > templates/index.html.twig
<h1>Hello World</h1>
EOF

cat << 'EOF' > src/Controller/HomepageController.php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class HomepageController extends AbstractController
{
    /**
     * @Route("/", name="homepage")
     */
    public function index(): Response
    {
        return $this->render('index.html.twig', [
            'controller_name' => 'HomepageController',
        ]);
    }
}
EOF

# Yay, we have static site!
read -p 'Serving a static site! Hit enter to continue.'

# =========================
# Let's use a base template
# =========================

# Let's create a base template
cat << 'EOF' > templates/base.html.twig
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
cat << 'EOF' > templates/index.html.twig
{% extends "base.html.twig" %}
{% block content %}
    <h1>Hello World</h1>
{% endblock %}
EOF

# =======================
# Let's add user accounts
# =======================

# ... To be written ...
