#!/bin/bash

set -ex

source .env # Inportamos el contenido de variables de entorno

# ELiminamos clonados previos del repo
rm -rf /tmp/iaw-practica-lamp

# Clonamos el repositorio de la aplicacion en /tmp/iaw-practica-lamp
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git /tmp/iaw-practica-lamp

# Movemos el codigo fuente del directorio src a /var/www/html
mv /tmp/iaw-practica-lamp/src/* /var/www/html

# Creamos base de datos para la aplicacion
mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME;"
mysql -u root <<< "CREATE DATABASE $DB_NAME;"

mysql -u root <<< "DROP USER IF EXISTS '$DB_USER'@'localhost';"
mysql -u root <<< "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"

# Modifico la conexion a la bd de la aplicacion en el config.php
sed -i "s/database_name_here/$DB_NAME/" /var/www/html/config.php
sed -i "s/username_here/$DB_USER/" /var/www/html/config.php
sed -i "s/password_here/$DB_PASSWORD/" /var/www/html/config.php

# Hay que modificar el script de creacion de la base de datos
sed -i "s/lamp_db/$DB_NAME/" /tmp/iaw-practica-lamp/db/database.sql

# Ejecutamos el script de creacion de la base de datos
mysql -u root $DB_NAME < /tmp/iaw-practica-lamp/db/database.sql