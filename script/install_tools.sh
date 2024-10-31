#!/bin/bash

# x muestra los comandos que se realizan
# e en caso de fallar detiene la ejecucion
set -ex

source .env # Inportamos el contenido de variables de entorno

# Actualiza la lista de paquetes
apt update

# Actualizamos paquetes de sistema operativo
apt upgrade -y # -y respuesta yes

# Configuramos las respuestas para phpMyAdmin
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections

# Instalamos phpMyAdmin
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y
# -------------------------------------------------------------------------------------------------------------
# Intalacion de adminer

# Crear dir para adminer
mkdir -p /var/www/html/adminer

# Descargo el archivo PHP de Adminer
wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php -P /var/www/html/adminer

# Renombramos el archivo
mv /var/www/html/adminer/adminer-4.8.1-mysql.php /var/www/html/adminer/index.php

# -------------------------------------------------------------------------------------------------------------
# Crear base de datos
mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME"
mysql -u root <<< "CREATE DATABASE $DB_NAME"

# Crear un usuario para la base de datos anterior
mysql -u root <<< "DROP USER IF EXISTS '$DB_USER'@'%'"
mysql -u root <<< "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"

# -------------------------------------------------------------------------------------------------------------
#Install goaccess
sudo apt install goaccess -y

# Crear directorio de stadisticas
mkdir -p /var/www/html/stats # -p Si existe no ocure nada

# Goacess generate html in real time en segundo plano
goaccess /var/log/apache2/access.log -o /var/www/html/stats/index.html --log-format=COMBINED --real-time-html --daemonize

# -------------------------------------------------------------------------------------------------------------
# Control de acceso a un archivo de autenticacion basiica

# copiar archivo de configuracion a apache
cp ../conf/000-default-stats.conf /etc/apache2/sites-available

# Desavilito 000-default
a2dissite 000-default.conf

# Habilito 000-default-stats.conf
a2ensite 000-default-stats.conf

# Reinicio apache
systemctl reload apache2

# Creamos el archivo .htpasswd
htpasswd -bc /etc/apache2/.htpasswd $STATS_USERNAME $STATS_PASSWORD

# -------------------------------------------------------------------------------------------------------------
# Control de acceso a un archivo de autenticacion basica con .htaccess

# copiar archivo de configuracion a apache
cp ../conf/000-default-htaccess.conf /etc/apache2/sites-available

# Desavilito 000-default
a2dissite 000-default-stats.conf

# Habilito 000-default-htaccess.conf
a2ensite 000-default-htaccess.conf

# Reinicio apache
systemctl reload apache2

# Copiamos al archivo al directorio /var/www/html/stats
cp ../conf/000-default-htaccess.conf /var/www/html/stats