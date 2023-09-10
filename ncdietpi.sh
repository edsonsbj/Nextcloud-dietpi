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

#EXAMPLE
#echo -e "${Blue}Welcome ${WHITE}to ${RED}France"
################## END OF COLLOR PALETTE ###################


# Check if the user is in the Linux root directory
if [ "$PWD" != "/" ]; then
    echo "[ ${BOLD_RED}! ] This script must be executed in the root directory of the system."
    exit 1
fi
echo "[ ${BOLD_RED}! ] Changing to the root directory..."
cd /
echo "[ ${BOLD_RED}! ] pwd result is: $(pwd)"

# Redirect verbose to log file and display on screen
exec > >(tee -i nextcloud-dietpi.log)
exec 2>&1

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 0 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# Get the local IP address of the device
NEXTCLOUD_IP=$(hostname -I | awk '{print $1}')

# Prompt the user to confirm and use the local IP address
read -p "Your local IP address is $NEXTCLOUD_IP. Is this correct? (Y/N): " confirm

if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
    echo "Please configure your local IP address correctly and re-run the script."
    exit 1
fi
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 0 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 1 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
echo -e "\033[1;32mInstalling rsync from debian repository through 'apt install'.\033[0m"
sudo apt install rsync
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

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 1 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 2 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

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
    read -p "Is the LOCAL IP address in $CONF_FILE correct for your Nextcloud? (Y/N): " user_input
    if [ "$user_input" == "Y" ] || [ "$user_input" == "y" ]; then
        break
    elif [ "$user_input" == "N" ] || [ "$user_input" == "n" ]; then
        nano $CONF_FILE
    else
        echo -e "\033[1;31mInvalid input. Please enter 'Y' or 'N'.\033[0m"
    fi
done


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
echo -e "\033[1;32mConfig.php updated and maintenance:update:htaccess executed.\033[0m"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 7 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 9 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Prompt user to configure NGINX Proxy Manager
while true; do
    read -p "Please configure NGINX Proxy Manager now (E-mail Adsress: admin@example.com | Password: changeme) . Once done, type 'CONTINUE' to proceed with the script: " user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "\033[1;31mInvalid input. Please type 'CONTINUE' to proceed IF NGINX is configured.\033[0m"
    fi
done
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIM ETAPA 9 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ETAPA 10 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

while true; do
    read -p "Do you want to install an External HDD/SSD as Data Storage? (Y/N): " user_input
    if [ "$user_input" == "Y" ]; then
        read -p "Please plug in the External HDD/SSD into USB 3.0. All data on the drive will be lost as it will be formatted. Continue? (Y/N): " format_input
        if [ "$format_input" == "Y" ]; then
            # Execute the script for external storage (assuming it's in the root directory)
            sudo /nextcloud-dietpi-external-storage.sh
        fi
        break
    elif [ "$user_input" == "N" ]; then
        break
    else
        echo -e "\033[1;31mInvalid input. Please type 'Y' for Yes or 'N' for No.\033[0m"
    fi
done

while true; do
    read -p "Access /var/www/nextcloud/config/config.php to edit domain and IP in another SSH Terminal Screen. After that, type 'CONTINUE' to proceed with the script: " user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "\033[1;31mInvalid input. Please type 'CONTINUE' to proceed IF config.php is configured.\033[0m"
    fi
done

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
