#!/bin/bash

# Check if the user is in the Linux root directory
if [ "$PWD" != "/" ]; then
    echo "This script must be executed in the root directory of the system."
    exit 1
fi
echo "Changing to the root directory..."
cd /
echo "pwd is $(pwd)"
echo "location of the database backup file is " '/'

# Check if the site is online
if ! wget --spider https://download.nextcloud.com/server/releases/latest.zip; then
    echo "The site https://download.nextcloud.com is not online. Check your Internet connection."
    exit 1
fi

# Get the IP address of the Nextcloud device from the user
read -p "Please enter the IP address of the device where Nextcloud will be installed: " NEXTCLOUD_IP
read -p "Please enter the IP address again for verification: " NEXTCLOUD_IP_VERIFY

# Verify that the IP addresses match
if [ "$NEXTCLOUD_IP" != "$NEXTCLOUD_IP_VERIFY" ]; then
    echo "IP addresses do not match. Please try again."
    exit 1
fi

# Function to read a password without special characters
read_password() {
    local input
    while true; do
        read -s -p "$1: " input
        if [[ "$input" =~ ^[a-zA-Z0-9]+$ ]]; then
            echo "$input"
            break
        else
            echo "Password cannot contain special characters. Please try again."
        fi
    done
}

# Request username
read -p "Enter desired Nextcloud Administrator username (Recommended to use \"admin\"): " NCUSER

# Request user password
NCPASS=$(read_password "Enter desired admin password for NextCloud")

# Request user password again for verification
NCPASS2=$(read_password "Enter admin password again for confirmation")

# Check if passwords match
if [ "$NCPASS" != "$NCPASS2" ]; then
    echo "Passwords do not match. Please try again."
    exit 1
fi

# Request user password for the Database
DBPASS=$(read_password "Enter desired password for the Database (preferably different from the previous one)")

# Request the password again for verification
DBPASS2=$(read_password "Enter the database password again for confirmation")

# Check if database passwords match
if [ "$DBPASS" != "$DBPASS2" ]; then
    echo "Database passwords do not match. Please try again."
    exit 1
fi

# Log File
LOGFILE="/var/log/install-nextcloud.log"

# Nextcloud Folder
NEXTCLOUD_CONF="/var/www/nextcloud"

# Database
HOSTNAME=localhost
NC_DB=nextcloud_db
NC_USER=nextcloud
NC_PASSWORD="$DBPASS" # Change Here to a password of your choice

# Administrator
USER="$NCUSER"
PASS="$NCPASS"

# Redirect verbose to log file and display on screen
exec > >(tee -i nextcloud-dietpi.log)
exec 2>&1

# Check if the script is executed by root
#
if [ "$(id -u)" != "0" ]
then
        errorecho "ERROR: This script must be executed as root!"
        exit 1
fi

# Install Apache2, MariaDB, and PHP 8.2

apt install unzip -y
apt install apache2 apache2-utils -y libapache2-mod-php -y
apt install mariadb-server mariadb-client -y
apt install imagemagick php8.2 php8.2-{cli,curl,gd,mbstring,xml,zip,bz2,intl,bcmath,gmp,imagick,mysql,phpdbg,fpm,cgi} -y
apt install libphp8.2-embed libapache2-mod-php8.2 -y
apt install bzip2 -y
apt install redis-server php-redis -y

# Configure PHP-FPM
sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php/8.2/apache2/php.ini
sed -i 's/;date.timezone.*/date.timezone = America\/\Sao_Paulo/' /etc/php/8.2/fpm/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 10240M/' /etc/php/8.2/fpm/php.ini
sed -i 's/post_max_size = .*/post_max_size = 10240M/' /etc/php/8.2/fpm/php.ini
a2dismod php8.2 && sleep 2 && a2enmod proxy_fcgi setenvif && sleep 2 && a2enconf php8.2-fpm && sleep 2 && systemctl restart php8.2-fpm && sleep 2 && systemctl restart apache2

# Configure MariaDB
#mysql_secure_installation

# Create the database for Nextcloud
#mysql -e "CREATE DATABASE $NC_DB;"
#mysql -e "CREATE USER '$NC_USER'@'localhost' IDENTIFIED BY '$NC_PASSWORD';"
#mysql -e "GRANT ALL PRIVILEGES ON $NC_DB.* TO '$NC_USER'@'localhost';"
#mysql -e "FLUSH PRIVILEGES;"ID
mysql -e "CREATE DATABASE $NC_DB;"
mysql -e "CREATE USER '$NC_USER'@'localhost' IDENTIFIED BY '$NC_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON $NC_DB.* TO '$NC_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"


# Download and install Nextcloud
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
mv nextcloud /var/www/
chown -R www-data:www-data /var/www/nextcloud
chmod -R 755 /var/www/nextcloud

# Create VirtualHost for Nextcloud
cat <<EOF >>/etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
	ServerName $NEXTCLOUD_IP
	#ServerAlias thepandacloud.duckdns.org
	#ServerAdmin webmaster@example.com
	DocumentRoot /var/www/nextcloud

<Directory /var/www/nextcloud>
	Options FollowSymLinks MultiViews
	AllowOverride All
</Directory>

	ErrorLog ${APACHE_LOG_DIR}/example.com-error.log
	CustomLog ${APACHE_LOG_DIR}/example.com-access.log combined

	SetEnv HOME /var/www/nextcloud
	SetEnv HTTP_HOME /var/www/nextcloud
</VirtualHost>
EOF

cat <<EOF >> /etc/apache2/apache2.conf
ServerName $NEXTCLOUD_IP
EOF

# Enable VirtualHost and restart Apache
a2ensite nextcloud.conf && sleep 2 && systemctl reload apache2 && sleep 2 && systemctl status apache2 

# Run the Nextcloud installation script
sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "$NC_DB" --database-user "$NC_USER" --database-pass "$NC_PASSWORD" --admin-user $USER --admin-pass $PASS

# Install Docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove $pkg -y
done

apt-get install ca-certificates curl gnupg -y

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt-get install docker docker-compose docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Install Nginx Proxy Manager
cd /
mkdir docker/ && cd docker/
cd /docker/
mkdir nginx && cd nginx
touch docker-compose.yml
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

docker-compose up -d

# Nextcloud Adjustments
cp /var/www/nextcloud/config/config.php /var/www/nextcloud/config/config.php.bk
sed -i '/);/d' /var/www/nextcloud/config/config.php
sed -i '/;/d' /var/www/nextcloud/config/config.php
sudo cat <<EOF >>/var/www/nextcloud/config/config.php
  'default_phone_region' => 'BE',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'localhost',
    'port' => 6379,
  ),
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
);
EOF

# Activate Cron
sudo cat <<EOF >>/var/spool/cron/crontabs/root
# DO NOT EDIT THIS FILE - edit the master and reinstall.
# (/tmp/crontab.vdSxK9/crontab installed on Wed May 10 23:14:30 2023)
# (Cron version -- $Id: crontab.c,v 2.13 1994/01/17 03:20:37 vixie Exp $)
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
*/5 * * * * sudo -u www-data php -f /var/www/nextcloud/cron.php
EOF
chown root:crontab /var/spool/cron/crontabs/root
chmod 600 /var/spool/cron/crontabs/root

# Change data directory for external storage
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

sudo umount /dev/sda1
sudo mkfs.ext4 /dev/sda1
UUID=$(sudo blkid -s UUID -o value /dev/sda1)
sudo mount -a

echo "UUID=$UUID /media/myCloudDrive ext4 defaults 0 0" | sudo tee -a /etc/fstab
sudo mkdir /media/myCloudDrive		# Change this if you want to mount the drive elsewhere, like /mnt/, or change the name of the drive
rsync -avh /var/www/nextcloud/data /media/myCloudDrive
chown -R www-data:www-data /media/myCloudDrive/data
chmod -R 770 /media/myCloudDrive/data

sed -i "s/'datadirectory' => '\/var\/www\/nextcloud\/data',.*/'datadirectory' => '\/media\/myCloudDrive\/data',/" /var/www/nextcloud/config/config.php

# Replace trusted_domains in the config.php file
sed -i "/'trusted_domains' =>/s/0 => 'localhost',/0 => 'localhost',\n    1 => '$NEXTCLOUD_IP',\n    2 => 'thepandacloud.duckdns.org',/" /var/www/nextcloud/config/config.php

sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# If Using Swap

sudo swapoff -a
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
free -h

unset NCUSER
unset NCPASS
unset NCPASS2
unset DBPASS
unset DBPASS2

sudo a2dissite 000-default && sleep 2 && sudo systemctl restart apache2

echo -e "\n\n\033[1;33m[\033[0m\033[1;32m OK \033[0;33m\033[1;33m]\033[0m \033[0mINSTALLATION COMPLETED!"
echo -e "\033[1;32m───────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m"
echo -e "\033[1;32mThank you for using this script!"
echo -e "If you found it helpful, consider supporting the developer by buying a coffee using the link below:\033[0m"
echo -e "\n\033[1;34m    \033[34mbuymeacoffee.com/lstavares84\033[0m"
echo ""
echo -e "\033[1;32mYour contribution helps maintain this project and enables the creation of more useful features in the future.\033[0m"
echo -e "\033[1;32mThank you for your support!\033[0m"
echo -e "\033[1;32m───────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m"
