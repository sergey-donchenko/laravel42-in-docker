#!/bin/bash

echo "⏳ Waiting for the database to be ready..."
echo "DB_HOST=$DB_HOST"
echo "DB_USERNAME=$DB_USERNAME"
echo "DB_PASSWORD=$DB_PASSWORD"
echo "WEB_DOCUMENT_ROOT=$WEB_DOCUMENT_ROOT"
echo "PHP_TIMEOUT=$PHP_TIMEOUT"

sed -i "s|<PHP_TIMEOUT>|$PHP_TIMEOUT|" /etc/apache2/conf-enabled/10-php.conf

if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
sed -i "s|<DOCUMENT_ROOT>|$WEB_DOCUMENT_ROOT|" /etc/apache2/sites-enabled/000-default.conf
fi
 
sed -i "s|<DOCUMENT_ROOT>|$WEB_DOCUMENT_ROOT|" /etc/apache2/conf-enabled/10-server.conf 

# Set ServerName parameter
echo "ServerName localhost" >> /etc/apache2/apache2.conf

echo "📁 Checking that DocumentRoot was replaced properly:"
grep DocumentRoot /etc/apache2/conf-enabled/10-server.conf
grep DocumentRoot /etc/apache2/sites-enabled/000-default.conf

find /etc/apache2 /etc/apache2/conf-enabled -type f -name '*.conf' -exec sed -i "s|<DOCUMENT_ROOT>|/var/www/html/public|g" {} +

# Create folder for logs
mkdir -p /var/log/apache2

# Activate modules
if ! apache2ctl -M | grep -q php7; then
    echo "🧩 Enabling PHP module for Apache..."
    a2enmod php7.0
fi

if ! apache2ctl -M | grep -q rewrite; then
    echo "🧩 Enabling REWRITE module for Apache..."
    a2enmod rewrite
fi

# 🛠 Install Composer if not available
if ! command -v composer &> /dev/null; then
  echo "📥 Installing Composer..."
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php composer-setup.php --2
  mv composer.phar /usr/bin/composer
  rm composer-setup.php
else
  echo "✅ Composer already installed."
fi

# Install dependecies
echo "📦 Installing composer dependencies..."
COMPOSER_MEMORY_LIMIT=-1 composer install --no-interaction --prefer-dist --optimize-autoloader

until mysqladmin ping -h"$DB_HOST" --silent; do
  echo "Waiting for DB to respond to ping..."
  sleep 2
done

echo "✅ Database is ready!"

# Create database if it does not exists
echo "🛠  Creating database if it doesn't exist..."
mysql -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Install dependecies
echo "📦 Installing composer dependencies..."
COMPOSER_MEMORY_LIMIT=-1 composer install --no-interaction --prefer-dist --optimize-autoloader

if ! php artisan key:check >/dev/null 2>&1; then
  php artisan key:generate
fi

# Run migrations
echo "▶️ Running migrations..."
php artisan migrate --force

if [ -f /var/www/html/.docker/db/dump.sql ]; then
  echo "💾 Importing database dump..."
  mysql -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /var/www/html/.docker/db/dump.sql
fi

# 🚀 Run Apache onl if it is not run before
echo "🚀 Ensuring Apache is running..."
if ! pgrep apache2 > /dev/null; then
  echo "Starting Apache on http://localhost:${APP_PORT} in foreground..."
  exec apachectl -D FOREGROUND
else
  echo "Apache already running. Restarting on http://localhost:${APP_PORT} gracefully..."
  apachectl -k graceful
  tail -f /var/log/apache2/error.log
fi