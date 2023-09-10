#!/bin/bash

###################### COLLOR PALETTE ######################
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

BACKGROUND_BLACK='\033[40m'
BACKGROUND_RED='\033[41m'
BACKGROUND_GREEN='\033[42m'
BACKGROUND_YELLOW='\033[43m'
BACKGROUND_BLUE='\033[44m'
BACKGROUND_MAGENTA='\033[45m'
BACKGROUND_CYAN='\033[46m'
BACKGROUND_WHITE='\033[47m'

LIGHT_GREEN='\033[0;92m'  # Light Green
ORANGE='\033[0;33m'       # Orange
PURPLE='\033[0;35m'       # Purple
LIGHT_BLUE='\033[0;94m'   # Light Blue
RESET_COLOR='\033[0m'  # Restaura as configurações de cores para o padrão.

#EXAMPLE
#echo -e "${Blue}Welcome ${WHITE}to ${RED}France"
################## END OF COLLOR PALETTE ###################


###################### STEP 0 ######################
# Check if the user is in the Linux root directory
if [ "$PWD" != "/" ]; then
    echo "[ ${BOLD_RED}!${RESET_COLOR} ] This script must be executed in the root directory of the system."
    exit 1
fi
echo "[ ${BOLD_RED}!${RESET_COLOR} ] Changing to the root directory..."
cd /
echo "[ ${BOLD_RED}!${RESET_COLOR} ] pwd result is: $(pwd)"

# Redirect verbose to log file and display on screen
exec > >(tee -i nextcloud-dietpi.log)
exec 2>&1

# Get the local IP address of the device
NEXTCLOUD_IP=$(hostname -I | awk '{print $1}')

# Prompt the user to confirm and use the local IP address
read -p "[ ${BOLD_YELLOW}!${RESET_COLOR} ] Your local IP address is ${YELLOW}$NEXTCLOUD_IP${RESET_COLOR}. Is this correct? (Y/N): " confirm

if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
    echo "Please configure your local IP address correctly and re-run the script."
    exit 1
fi
################## END OF STEP 0 ###################


###################### STEP 1 ######################
echo -e "${LIGHT_GREEN}Installing rsync from debian repository through 'apt install'.${RESET_COLOR}"
sudo apt install rsync
echo -e "${LIGHT_GREEN}Installing Nextcloud from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 114
echo -e "\${LIGHT_GREEN}Installing Docker from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 162
echo -e "${LIGHT_GREEN}Installing Docker-Composer from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 134
echo -e "${LIGHT_GREEN}Installing FFMPEG from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 7


# Install Nginx Proxy Manager
echo -e "${LIGHT_GREEN}Preparing for NGINX PROXY MANAGER installation${RESET_COLOR}"
cd /
sudo mkdir docker/ && cd docker/
cd /docker/
sudo mkdir nginx && cd nginx
touch docker-compose.yml
echo -e "Creating docker-compose.yml..."
sudo cat <<EOF >>/docker/nginx/docker-compose.yml
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

echo -e "${LIGHT_GREEN}Opening folder of docker-compose.yml${RESET_COLOR}"
cd /docker/nginx
echo -e "${LIGHT_GREEN}Installing NGINX PROXY MANAGER using Docker Compose${RESET_COLOR}"
docker compose up -d
echo -e "${LIGHT_GREEN}NGINX PROXY MANAGER INSTALLED VIA DOCKER$${RESET_COLOR}"

echo -e "[ ${BOLD_YELLOW}!${RESET_COLOR} ] All softwares needed were installed.{$RESET_COLOR}"

################## END OF STEP 1 ###################


###################### STEP 2 ######################

# Create the nextcloud.conf file
CONF_FILE="/etc/apache2/sites-available/nextcloud.conf"
cat <<EOF > $CONF_FILE
<VirtualHost *:80>
    ServerName $NEXTCLOUD_IP
    #ServerAlias domain.duckdns.org
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

echo -e "\033[1;32mCreated $CONF_FILE with the specified content.\033[0m"
cat $CONF_FILE

while true; do
    read -p "[ ${BOLD_YELLOW}!${RESET_COLOR} ] Is the LOCAL IP address in $CONF_FILE correct for your Nextcloud? (Y/N): " user_input
    if [ "$user_input" == "Y" ] || [ "$user_input" == "y" ]; then
        break
    elif [ "$user_input" == "N" ] || [ "$user_input" == "n" ]; then
        nano $CONF_FILE
    else
        echo -e "Invalid input. Please enter 'Y' or 'N'."
    fi
done

################## END OF STEP 2 ###################

###################### STEP 3 ######################

# Enable the new configuration
sudo a2ensite nextcloud.conf

# Disable other configurations
sudo a2dissite 000-default.conf
sudo a2dissite dietpi-nextcloud.conf

# Restart Apache
sudo systemctl reload apache2

################## END OF STEP 3 ###################

###################### STEP 4 ######################

# Edit config.php and make necessary changes
sudo sed -i "/'htaccess.RewriteBase' => '\/nextcloud/d" /var/www/nextcloud/config/config.php
sudo sed -i "s|'http://localhost/nextcloud|'http://localhost|g" /var/www/nextcloud/config/config.php

# Execute maintenance:update:htaccess
sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess
echo -e "\033[1;32mConfig.php updated and maintenance:update:htaccess executed.\033[0m"

################## END OF STEP 4 ###################

###################### STEP 5 ######################
# Prompt user to configure NGINX Proxy Manager
while true; do
    read -p "[ ${BOLD_YELLOW}!${RESET_COLOR} ] Please configure NGINX Proxy Manager now (E-mail Adsress: ${YELLOW}admin@example.com${RESET_COLOR} | Password: ${YELLOW}changeme${RESET_COLOR}) . Once done, type 'CONTINUE' to proceed with the script: " user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "Invalid input. Please type 'CONTINUE' to proceed IF NGINX is configured."
    fi
done
################## END OF STEP 5 ###################

###################### STEP 6 ######################

while true; do
    read -p "Access /var/www/nextcloud/config/config.php to edit domain and IP in another SSH Terminal Screen. After that, type 'CONTINUE' to proceed with the script: " user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "Invalid input. Please type 'CONTINUE' to proceed IF config.php is configured."
    fi
done

################## END OF STEP 6 ###################

###################### STEP 7 ######################
# Output TODO items with formatting
echo -e "\n\n\[ ${BOLD_YELLOW}!${RESET_COLOR} ]Change the password of Nextcloud Admin."
sudo -u www-data php /var/www/nextcloud/occ user:resetpassword admin
################## END OF STEP 7 ###################


echo -e "\n\n\${BOLD_GREEN}INSTALLATION COMPLETED!${RESET_COLOR}"
echo -e "LOG of this script can be found saved as ${YELLOW}nextcloud-dietpi.log${RESET_COLOR}"
echo -e "${LIGHT_GREEN}───────────────────────────────────────────────────────────────────────────────────────────────────────${RESET_COLOR}"
echo -e "Thank you for using this script!"
echo -e "If you found it helpful, consider supporting the developer by buying a coffee using the link below:"
echo -e "\n                        ${LIGHT_GREEN}buymeacoffee.com/lstavares84${RESET_COLOR}"
echo -e "\nYour contribution helps maintain this project and enables the creation of more useful features in the future."
echo -e "Thank you for your support!"
echo -e "${LIGHT_GREEN}───────────────────────────────────────────────────────────────────────────────────────────────────────${RESET_COLOR}"
