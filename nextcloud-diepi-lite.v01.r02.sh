#!/bin/bash

CONF_FILE="/etc/apache2/sites-available/nextcloud.conf"

# Check if the script is executed by root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be executed as root!"
    exit 1
fi

#NEXTCLOUD_IP = '192.168.0.71'
#DOMAIN_NEXTCLOUD = 'thepandabay.duckdns.org'


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STEP 1 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

echo -e "\033[1;32mInstalling Nextcloud from DietPi Market.\033[0m"
/boot/dietpi/dietpi-software install 114
echo -e "\033[1;32mInstalling Docker from DietPi Market.\033[0m"
/boot/dietpi/dietpi-software install 162
echo -e "\033[1;32mInstalling Docker-Composer from DietPi Market.\033[0m"
/boot/dietpi/dietpi-software install 134
echo -e "\033[1;32mInstalling FFMPEG from DietPi Market.\033[0m"
/boot/dietpi/dietpi-software install 7
echo -e "\033[1;32mAll softwares needed from market were installed.\033[0m"

# Install Nginx Proxy Manager
echo -e "\033[1;32mPreparing for NGINX PROXY MANAGER installation\033[0m"
cd /
mkdir docker/ && cd docker/
cd /docker/
mkdir nginx && cd nginx
touch docker-compose.yml
echo -e "Creating docker-compose.yml..."
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
echo -e "Opening folder of docker-compose.yml"
cd /docker/nginx
echo -e "Installing NGINX PROXY MANAGER using Docker Compose"
docker compose up -d
echo -e "\033[1;32mNGINX PROXY MANAGER INSTALLED VIA DOCKER\033[0m"

while true; do
    read -p "Were all softwares well installed? Once done, type 'CONTINUE' to proceed with the script: " user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "\033[1;31mInvalid input. Please type 'CONTINUE' to proceed IF NGINX is configured.\033[0m"
    fi
done

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END OF STEP 1 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STEP 2 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# Create the nextcloud.conf file
cat <<EOF > $CONF_FILE
<VirtualHost *:80>
    ServerName 192.168.0.71
    #ServerAlias thepandabay.duckdns.org
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

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END OF STEP 2 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STEP 3 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

echo -e "\033[1;31mServers update.\033[0m"
# Enable the new configuration
sudo a2ensite nextcloud.conf
# Disable other configurations
sudo a2dissite 000-default.conf
sudo a2dissite dietpi-nextcloud.conf
# Restart Apache
sudo systemctl reload apache2

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END OF STEP 3 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STEP 4 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# Edit config.php and make necessary changes
sudo sed -i "/'htaccess.RewriteBase' => '\/nextcloud/d" /var/www/nextcloud/config/config.php
sudo sed -i "s|'http://localhost/nextcloud|'http://localhost|g" /var/www/nextcloud/config/config.php

# Execute maintenance:update:htaccess
sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess
echo -e "\033[1;32mConfig.php updated and maintenance:update:htaccess executed.\033[0m"

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END OF STEP 4 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STEP 5 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# Prompt user to configure NGINX Proxy Manager
while true; do
    read -p "Please configure NGINX Proxy Manager now. Once done, type 'CONTINUE' to proceed with the script: " user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "\033[1;31mInvalid input. Please type 'CONTINUE' to proceed IF NGINX is configured.\033[0m"
    fi
done

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END OF STEP 5 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 10 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Append the required lines to config.php


echo -e "\033[1;32mLines added to config.php.\033[0m"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 10 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# Output TODO items with formatting
echo -e "\n\n\033[1;30m[\033[0m\033[1;33m   \033[1;1mTODO   \033[0m\033[1;30m]\033[0m \033[0;37mChange the password of Nextclou Admin.\033[0m"
sudo -u www-data php /var/www/nextcloud/occ user:resetpassword admin


echo -e "\n\n\033[1;33m[\033[0m\033[1;32m OK \033[0;33m\033[1;33m]\033[0m \033[0mINSTALLATION COMPLETED!"
echo -e "\033[1;32m───────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m"
echo -e "\033[1;32mThank you for using this script!"
echo -e "If you found it helpful, consider supporting the developer by buying a coffee using the link below:\033[0m"
echo -e "\n\033[1;34m    \033[34mbuymeacoffee.com/lstavares84\033[0m"
echo ""
echo -e "\033[1;32mYour contribution helps maintain this project and enables the creation of more useful features in the future.\033[0m"
echo -e "\033[1;32mThank you for your support!\033[0m"
echo -e "\033[1;32m───────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m"
