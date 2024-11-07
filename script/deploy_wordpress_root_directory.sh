#!/bin/bash

set -ex

source .env # Inportamos el contenido de variables de entorno

# Eliminamos los archivos de Wordpress de /tmp
rm -rf  /tmp/latest.tar.gz

# Descargamos coddigo fuente de wordpress
wget http://wordpress.org/latest.tar.gz -P /tmp

# Descomprimimos el codigo fuente de Wordpress
tar -xzvf /tmp/latest.tar.gz -C /tmp

# Elimino los archivos de Wordpres para que posteriormente pueda 
rm -rf /var/www/html/*

# Movemos los archivos de Wordpress a /var/html
mv -f /tmp/wordpress/* /var/www/html

# Creamos la base de datos para utilizarla con Wordpress
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# Creamos un archivo de configuracion de wp-config
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Configuramos el archivo wp-config
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wp-config.php

# Cambiamos el propietario y el grupo
chown -R www-data:www-data /var/www/html/