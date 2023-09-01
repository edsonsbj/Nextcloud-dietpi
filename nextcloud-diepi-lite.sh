#!/bin/bash

CONF_FILE="/etc/apache2/sites-available/nextcloud.conf"

# Check if the script is executed by root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be executed as root!"
    exit 1
fi

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 2 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# Create the nextcloud.conf file
cat <<EOF > $CONF_FILE
<VirtualHost *:80>
    ServerName 192.168.0.70
    #ServerAlias thepandacloud.duckdns.org
    #ServerAdmin webmaster@example.com
    DocumentRoot /var/www/nextcloud

    <Directory /var/www/nextcloud>
        Options FollowSymLinks MultiViews
        AllowOverride All
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/example.com-error.log
    CustomLog \${APACHE_LOG_DIR}/example.com-access.log combined

    SetEnv HOME /var/www/nextcloud
    SetEnv HTTP_HOME /var/www/nextcloud
</VirtualHost>
EOF

echo "Created $CONF_FILE with the specified content."

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 2 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 3 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Enable the new configuration
sudo a2ensite nextcloud.conf
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 3 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 4 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Disable other configurations
sudo a2dissite 000-default.conf
sudo a2dissite dietpi-nextcloud.conf
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 4 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 5 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Restart Apache
sudo systemctl reload apache2
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 5 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 6 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Edit config.php and make necessary changes
sudo sed -i "/'htaccess.RewriteBase' => '\/nextcloud/d" /var/www/nextcloud/config/config.php
sudo sed -i "s|'http://localhost/nextcloud|'http://localhost|g" /var/www/nextcloud/config/config.php
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 6 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 7 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Execute maintenance:update:htaccess
sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess
echo "Config.php updated and maintenance:update:htaccess executed."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 7 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 8 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# Install Nginx Proxy Manager
echo "Preparing for NGINX PROXY MANAGER installation"
cd /
mkdir docker/ && cd docker/
cd /docker/
mkdir nginx && cd nginx
touch docker-compose.yml
echo "Creating docker-compose.yml..."
cat <<EOF >>/docker/nginx/docker-compose.yml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '8880:80' # CHANGE THE PORT 8880 TO AN HTTP PORT OF YOUR CHOICE
      - '81:81'
      - '8443:443' # CHANGE THE PORT 8443 TO AN HTTPS PORT OF YOUR CHOICE
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

EOF
echo "Opening folder of docker-compose.yml"
cd /docker/nginx
echo "Installing NGINX PROXY MANAGER using Docker Compose"
docker compose up -d
echo "NGINX PROXY MANAGER INSTALLED VIA DOCKER"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 8 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 9 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Prompt user to continue
read -p "Please configure NGINX Proxy Manager now. Once done, type 'CONTINUE' to proceed with the script: " user_input

# Check if user input is 'CONTINUE'
if [ "$user_input" != "CONTINUE" ]; then
    echo "Script will exit. Please configure NGINX Proxy Manager and run the script again."
    exit 1
fi
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 9 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 10 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Append the required lines to config.php
sudo cat <<EOF >>/var/www/nextcloud/config/config.php
  'default_phone_region' => 'BE',
  'enable_previews' => true,
  'enabledPreviewProviders' =>
  array (
    0 => 'OC\\Preview\\PNG',
    1 => 'OC\\Preview\\JPEG',
    2 => 'OC\\Preview\\GIF',
    3 => 'OC\\Preview\\BMP',
    4 => 'OC\\Preview\\XBitmap',
    5 => 'OC\\Preview\\Movie',
    6 => 'OC\\Preview\\PDF',
    7 => 'OC\\Preview\\MP3',
    8 => 'OC\\Preview\\TXT',
    9 => 'OC\\Preview\\MarkDown',
    10 => 'OC\\Preview\\Image',
    11 => 'OC\\Preview\\HEIC',
    12 => 'OC\\Preview\\TIFF',
  ),
  'trashbin_retention_obligation' => 'auto,30',
  'versions_retention_obligation' => 'auto,30',
  'overwritehost' => 'www.iclouud.com.br:8443',
  'overwriteprotocol' => 'https',
);
EOF

echo "Lines added to config.php."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 10 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
