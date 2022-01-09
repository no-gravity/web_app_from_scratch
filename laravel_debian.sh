#!/bin/bash
#
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
sudo apt update -y && apt upgrade -y

sudo apt install wget

sudo apt install lsb-release

sudo apt install gnupg

sudo wget https://dev.mysql.com/get/mysql-apt-config_0.8.20-1_all.deb

sudo dpkg -i mysql-apt-config*

sudo apt-get update

clear

# Prompt the user for an app name
echo "============================================="
echo Please provide a name for your application.
echo This will be used to create your database,
echo user account, and will also name the project.
echo "============================================="

echo "============================"
echo Type application name below:
echo "============================"
read APP_NAME

# Install mysql-server package
sudo apt install mysql-server

# Restart the service
# This sometimes causes the install script
# to bug if we don't restart the service beforehand
#/etc/init.d/mysql restart

# Run the MySQL installation script
# IMPORTANT - Remember to save the root password somewhere
sudo mysql_secure_installation

# Create our application's DB
mysql -u root -p -e "CREATE DATABASE $APP_NAME;"
echo Created database

# Create the application's DB user
mysql -u root -p -e "CREATE USER '$APP_NAME'@'%' IDENTIFIED BY 'password';"
echo Created database user

# Grant the DB user permissions on the DB
mysql -u root -p -e "GRANT ALL PRIVILEGES ON $APP_NAME.* TO '$APP_NAME'@'%' WITH GRANT OPTION;"
echo Granted privileges to user

# Flush privileges
mysql -u root -p -e "FLUSH PRIVILEGES;"
echo Flushed privileges

# Install base Laravel with mysql
curl -s "https://laravel.build/"$APP_NAME"?with=mysql" | sudo -u $USER bash

# Change the DB_USERNAME in the .env (defaults to sail)
sed -i "s/\(DB_USERNAME *= *\).*/\1$APP_NAME/" $APP_NAME/.env

# Start the container
cd $APP_NAME && ./vendor/bin/sail up

