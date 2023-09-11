# Path to the config.php backup file
config_file_bak='/var/www/nextcloud/config/config.php.bak'

# Check if the config.php backup file exists
if [ ! -f "$config_file_bak" ]; then
    echo "Config.php backup file not found."
    exit 1
fi

# Extract values from the config.php backup file
passwordsalt_extracted=$(grep -oP "'passwordsalt' => '\K[^']+" "$config_file_bak")
secret_extracted=$(grep -oP "'secret' => '\K[^']+" "$config_file_bak")
dbpassword_extracted=$(grep -oP "'dbpassword' => '\K[^']+" "$config_file_bak")
instanceid_extracted=$(grep -oP "'instanceid' => '\K[^']+" "$config_file_bak")

# Display the extracted values
echo "variável_1 = $passwordsalt"
echo "variável_2 = $secret"
echo "variável_3 = $dbpassword"
echo "variável_4 = $instanceid"

sudo rm "$config_file"

cat <<EOF > $config_file
<?php
$CONFIG = array (
  'passwordsalt' => $passwordsalt_extracted,
  'secret' => $secret_extracted,
  'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => $NEXTCLOUD_IP,
    ),
  'overwritehost' => $new_domain,
  'overwriteprotocol' => 'https',
  'datadirectory' => '/media/myCloudDrive/nextcloud_data',
  'dbtype' => 'mysql',
  'version' => '27.0.2.1',
  'hashingThreads' => 4,
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'filelocking.enabled' => true,
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => array ('host' => '/run/redis/redis-server.sock', 'port' => 0,),
  'overwrite.cli.url' => 'http://localhost',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'oc_admin',
  'dbpassword' => $dbpassword_extracted,
  'installed' => true,
  'instanceid' => $instanceid_extracted,
  'maintenance' => false,
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

while true; do
    echo -e "Edit ${YELLOW}$config_file{RESET_COLOR} has been changed. In another SSH Terminal Screen check if everything is okay and after that, type 'CONTINUE' to proceed with the script: "
    read user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "Invalid input. Please type 'CONTINUE' to proceed IF config.php is configured."
    fi
done
