#!/bin/bash

set -ex

source .env # Importamos el contenido de variables de entorno

# Eliminamos los archivos de WordPress de /tmp
rm -rf  /tmp/latest.tar.gz

# Descargamos código fuente de WordPress
wget http://wordpress.org/latest.tar.gz -P /tmp

# Descomprimimos el código fuente de WordPress
tar -xzvf /tmp/latest.tar.gz -C /tmp

# Elimino los archivos de WordPress para que posteriormente pueda 
rm -rf /var/www/html/$WORDPRESS_DIRECTORY/*

# Creamos el directorio donde lo vamos ha tener después
mkdir -p /var/www/html/$WORDPRESS_DIRECTORY

# Movemos los archivos de WordPress a /var/html y al directorio que queramos
mv -f /tmp/wordpress/* /var/www/html/$WORDPRESS_DIRECTORY

# Creamos la base de datos para utilizarla con WordPress
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# Creamos un archivo de configuración de wp-config
cp /var/www/html/$WORDPRESS_DIRECTORY/wp-config-sample.php /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php

# Configuramos el archivo wp-config
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php

# Cambiamos el propietario y el grupo
chown -R www-data:www-data /var/www/html/$WORDPRESS_DIRECTORY/

# Configuramos la dirección de WordPress y de home
sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$LE_DOMAIN/$WORDPRESS_DIRECTORY');" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$LE_DOMAIN');" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php

# Copiamos el index y no lo llevamos a /var/www/html
cp /var/www/html/$WORDPRESS_DIRECTORY/index.php /var/www/html

# Combiamos el contenido del index
sed -i "s#wp-blog-header.php#$WORDPRESS_DIRECTORY/wp-blog-header.php#" /var/www/html/index.php 

# Copiamos el archivo .htaccess a /var/www/html
cp ../htaccess/.htaccess /var/www/html

# Habilitamos el modulo de reescribir de apache
a2enmod rewrite

# Reiniciamos apache para que se apliquen los cambios
systemctl restart apache2