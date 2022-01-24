
   
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
# or start autmatically the script in your docker Debian image:
#
# docker run -v $(pwd):/var/www -w /var/www --rm -it -p 8080:80 debian:11-slim bash laravel.sh
#  
# You can copy+paste each command to see the application take
# shape or copy the whole page and paste it in one go.
# You can also download it here: https://...

# ======================
# Let's configure Debian
# ======================
INSTALL_DEBIAN=1

echo $INSTALL_DEBIAN

if [ $INSTALL_DEBIAN == 1 ]; then

    echo "Install debian packages"
    # Do not show dialogs during the upgrade
    export DEBIAN_FRONTEND=noninteractive
    # Update the packages
    apt update -y && apt upgrade -y
    apt install -y unzip git php php-xml php-curl composer
    php -v

fi



# Update the packages
# apt update -y && apt upgrade -y

# ====================
# Let's install Laravel
# ====================

composer global require laravel/installer
export PATH="$PATH:$HOME/.composer/vendor/bin"
# cd /var/www
laravel new mysite
if [ $INSTALL_DEBIAN == 1 ]; then
    chown -R www-data:www-data mysite
fi

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

# Set the view template file
cat << 'EOF' > ./resources/views/index.blade.php
<h1>Hello World</h1>
EOF

# Set the Controller
cat << 'EOF' > ./app/Http/Controllers/MainController.php
<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;

class MainController extends Controller
{
    /**
     * Show the index page.
     *
     * @return \Illuminate\View\View
     */
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

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', [MainController::class, 'index']);
EOF


php artisan --version
# php artisan serve

read -p 'Serving a static site! Hit enter to continue.'

# =========================
# Let's use a base template
# =========================

# Let's create a base template 
# In the View directory 'resources/views'
# create a sub-directory 'layouts' to store layouts / templates
mkdir -p resources/views/layouts
# create a layout 'app.blade.php' with placeeholder for title and content
cat << 'EOF' > resources/views/layouts/app.blade.php
<!DOCTYPE html>
<html>
<head>
    <title>@yield('title')</title>
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

@section('title', 'Hello World')


@section('content')
    <p>This is my body content.</p>
@endsection
EOF

# Yay, we have a working base template!
read -p 'The base template is live! Hit enter to continue.'

# =======================
# Let's add user accounts
# =======================

# ... To be written ...