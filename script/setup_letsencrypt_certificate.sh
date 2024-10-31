#!/bin/bash

set -ex

source .env # Inportamos el contenido de variables de entorno

# Realizamos la instalacion de snap y actualizarlo
snap install core
snap refresh core

# Eliminas si existe la intalacion previa de cerbot con apt
apt remove certbot -y

# Instalamod el clinete de Crebot con snap
snap install --classic certbot

# Creamos un enlace simbolico de cerbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# Solicitamos un certificado SSL en Let´s Encript
certbot --apache -m $LE_EMAIL --agree-tos --no-eff-email -d $LE_DOMAIN --non-interactive