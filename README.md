# Despliegue de WordPress

Este es la continuación de la [practica 1.5, puedes ver la documentación en el repositorio de GitHub](https://github.com/ArturoCarrilloJimenez/Practica-daw-1.5)

El despliegue de este lo realizaremos de dos formas, en el directorio raíz y en un directorio concreto

## Estructura de carpetas

En primer lugar copiaremos los siguientes archivos del ejercicio anterior y crearemos los siguientes archivos: ``deploy_wordpress_own_directory.sh`` y ``deploy_wordpress_root_directory.sh``

```plaintext
Practica-daw-1.6/
├── conf/
│   └── 000-default.conf
├── htaccess/
│   └── .htaccess
├── php/
│   └── index.php
├── script/
│   ├── .env
│   ├── .env.ejemplo
│   ├── deploy_wordpress_own_directory.sh
│   ├── deploy_wordpress_root_directory.sh
│   ├── install_lamp.sh
│   └── setup_letsencrypt_https.sh
├── .gitignore
└── README.md
```

## Despliegue en el directorio raíz

Para esto debemos de haber ejecutado el archivo ``install_lamp.sh`` y ``setup_letsencrypt_https.sh`` para poder tener la pila LAMP y el certificado para poder hacer las búsquedas mediante HTTPS

Una vez hecho eso comenzaremos con la estructura básica del script que es la siguiente

``` sh
#!/bin/bash

set -ex

source .env
```

En primer lugar eliminaremos los archivos que allá de WordPress en /temp o archivos temporales mediante el comando ``rm -rf  /tmp/latest.tar.gz``

Posteriormente realizaremos la descarga del código fuente de WordPress que este esta comprimido
``` sh
wget http://wordpress.org/latest.tar.gz -P /tmp
```

Como anteriormente he dicho, este esta comprimido y deberemos de descomprimirlo

``` sh
tar -xzvf /tmp/latest.tar.gz -C /tmp
```

Para asegurar la que no hay nada antes en los archivos __/var/www/html__ de apache eliminaremos todo el contenido de este mediante el comando ``rm -rf /var/www/html/*`` con el carácter comodín __*__ siendo todos los archivos que hay en este

Una vez que emos asegurado que no hay nada __movemos el código fuente de WordPress a /var/www/html__ con el comando ``mv -f /tmp/wordpress/* /var/www/html``

WordPress necesita una base de datos y para esto, crearemos una y un usuario para acceder solo ha esta base de datos y no lo aremos con el usuario root

``` sh
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
```

Ademas debemos de añadir 3 variables al __.env__
- __WORDPRESS_DB_USER__ es el usuario con el que accederá posteriormente WordPress

- __WORDPRESS_DB_PASSWORD__ es la contraseña del usuario
- __WORDPRESS_DB_NAME__ es el nombre de la base de datos

Ahora para automatizar la configuración con la base de datos copiaremos archivo de configuración mediante el comando ``cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php`` y lo configuraremos con __sed__ de la siguiente forma

``` sh
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wp-config.php
```
Debemos de añadir en el __.env__ la variable ``WORDPRESS_DB_HOST`` con ``localhost`` ya que no tenemos servidor dedicado para la base de datos

Por ultimo debemos de cambiar la propiedad y el grupo mediante el comando ``chown -R www-data:www-data /var/www/html/``

Una vez hecho todo esto ya podremos comenzar con la instalación de WordPress

## Despliegue en un directorio personal

Este sera muy parecido al anterior, pero hay ligeros cambios a este, aquí podremos tener multiples despliegues sin colisionar uno con el otro ya que cada uno tendrá su propio directorio

En primer lugar copiamos el script anterior y lo pegamos en el archivo ``deploy_wordpress_own_directory.sh``

Posteriormente las rutas ``/var/www/html`` las cambiaremos por ``/var/www/html/$WORDPRESS_DIRECTORY`` siendo __$WORDPRESS_DIRECTORY__ el directorio personal donde queremos hacer el desplegué, esto lo debemos de hacer en todas las partes que aparezca esa ruta

Debemos de añadir en el __.env__ la variable ``WORDPRESS_DIRECTORY``

A continuación, una vez que emos desoprimido el el código de WordPress crearemos el directorio para asegurar que existe y lo realizaremos de la siguiente forma

``` sh
mkdir -p /var/www/html/$WORDPRESS_DIRECTORY
```

El comando __-p__ asegura que el directorio exista, y si existe no lo crea

Y movemos el contenido de WordPress a este directorio

``` sh
mv -f /tmp/wordpress/* /var/www/html/$WORDPRESS_DIRECTORY
```
Al final del script añadiremos las siguientes cosas, para comenzar, configuraremos la dirección de WordPress y de Home mediante el comando ``sed``

``` sh
sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$LE_DOMAIN/$WORDPRESS_DIRECTORY');" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$LE_DOMAIN');" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
```

Ademas debemos de copiar el index de este y lo sacaremos fuera de el directorio propio y lo moveremos al raíz

``` sh
cp /var/www/html/$WORDPRESS_DIRECTORY/index.php /var/www/html
```

Y cambiaremos el contenido de este para que pueda sacar las cosas del directorio propio

``` sh
sed -i "s#wp-blog-header.php#$WORDPRESS_DIRECTORY/wp-blog-header.php#" /var/www/html/index.php 
```

Posteriormente crearemos un archivo __.htaccess__ con el siguiente contenido

``` sh
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
```

Y lo copiaremos en el raíz de /var/www/html mediante el comando  ``cp ../htaccess/.htaccess /var/www/html``

Activamos el modulo de reescribir de apache
``a2enmod rewrite``

Y por ultimo reiniciamos apache para que se apliquen los cambios
``` sh
systemctl restart apache2
```

## Modificar el archivo 000-default.conf

Debemos de modificar la configuración de este para poder utilizar rutas personalizadas en wordpress, que este sera añadiendo la reescritura siempre de la síguete forma
```
<VirtualHost *:80>
    #ServerName www.example.com
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/

    DirectoryIndex index.php index.html

    <Directory /var/www/html>
        AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

Una vez modificado este archivo debemos de lanzar la instalación de la pila LAMP, el certificado de Lest`Encrypt y el despliegue de WordPress