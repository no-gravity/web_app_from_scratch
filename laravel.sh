#!/bin/bash

# ========================
# From Zero to Laravel App
# ========================
#
# This script will setup Laravel in a Docker container (see Laravel Sail)
# For use without Docker, please use composer to install Laravel.
#
# By default this script will setup your app with MySQL.
# To learn more about what datastore options you have,
# please visit https://laravel.com/docs/8.x/installation#choosing-your-sail-services
#

# Update packages
apt update -y && apt upgrade -y

# Prompt the user for an app name
echo Please provide a name for your application:
read APP_NAME

# Install mysql-server package
apt install mysql-server

# Restart the service
# This sometimes causes the install script
# to bug if we don't restart the service beforehand
/etc/init.d/mysql restart

# Run the MySQL installation script
# IMPORTANT - Remember to save the root password somewhere
mysql_secure_installation

# Create our application's DB
mysql -e "CREATE DATABASE $APP_NAME;"
echo Created database

# Create the application's DB user
mysql -e "CREATE USER '$APP_NAME'@'localhost' IDENTIFIED BY 'password';"
echo Created database user

# Grant the DB user permissions on the DB
mysql -e "GRANT ALL PRIVILEGES ON $APP_NAME.* TO '$APP_NAME'@'localhost' WITH GRANT OPTION;"
echo Granted privileges to user

# Flush privileges
mysql -e "FLUSH PRIVILEGES;"
echo Flushed privileges

# Install base Laravel with mysql
curl -s "https://laravel.build/"$APP_NAME"?with=mysql" | bash

# Change the DB_USERNAME in the .env (defaults to sail)
sed -i "s/\(DB_USERNAME *= *\).*/\1$APP_NAME/" $APP_NAME/.env

# Start the container
cd $APP_NAME && ./vendor/bin/sail up

