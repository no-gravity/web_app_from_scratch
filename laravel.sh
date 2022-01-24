
   
# ======================
# From Debian to Web App
# ======================

# This page contains a list of terminal commands that
# create a Laravel web application with routing, views
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
# Let's install Laravel
# =====================

apt install -y unzip git php php-xml php-curl composer
composer global require laravel/installer
export PATH="$PATH:$HOME/.composer/vendor/bin"
cd /var/www
laravel new mysite
chown -R www-data:www-data mysite
cd mysite

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

# Yay, we have a working Laravel instance!
# You can see it at 127.0.0.1
read -p 'Laravel is running! Hit enter to continue.'

# ===================
# Let's use templates
# ===================

cat << 'EOF' > ./resources/views/index.blade.php
<h1>Hello World</h1>
EOF

cat << 'EOF' > ./app/Http/Controllers/MainController.php
<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;

class MainController extends Controller
{
    public function index()
    {
        return view('index');
    }
}
EOF

# Set routing

cat << 'EOF' > ./routes/web.php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MainController;

Route::get('/', [MainController::class, 'index']);
EOF

# Yay, we have static site!
read -p 'Serving a static site! Hit enter to continue.'

# =========================
# Let's use a base template
# =========================

# Let's create a base template 
mkdir -p resources/views/layouts

cat << 'EOF' > resources/views/layouts/app.blade.php
<!DOCTYPE html>
<html>
<head>
    <title>Hello World</title>
    <style>
        body {background: #60a060}
    </style>
</head>
<body>
@yield('content')
</body>
</html>
EOF

# And use it for the index page:
cat << 'EOF' > ./resources/views/index.blade.php
@extends('layouts.app')
@section('content')
    <h1>Hello World</h1>
@endsection
EOF

# Yay, we have a working base template!
read -p 'The base template is live! Hit enter to continue.'

# =======================
# Let's add user accounts
# =======================

# ... To be written ...
