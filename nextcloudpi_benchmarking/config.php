#/var/www/nextcloud/config/config.php

<?php
$CONFIG = array (
  'passwordsalt' => 'lthwZgUaMDm6RjzdB1Z4CDFiFB7pBI',
  'secret' => 'NSHyR8E+S1P73er7YJ6TD0oV8Rew4RNSIGsLAZpURDaajQ9T',
  'trusted_domains' =>
  array (
    0 => 'localhost',
    7 => 'nextcloudpi',
    5 => 'nextcloudpi.local',
    8 => 'nextcloudpi.lan',
    3 => 'nextcloudpi',
    11 => '179.130.29.13',
    1 => '192.168.0.71',
    14 => 'nextcloudpi',
  ),
  'datadirectory' => '/media/USBdrive/ncdata/data',
  'dbtype' => 'mysql',
  'version' => '26.0.3.2',
  'overwrite.cli.url' => 'https://nextcloudpi/',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'ncadmin',
  'dbpassword' => 'a4GicQ3uJX4eW+Q9b891arHIMyiYIwyrd45iGoyK2xw=',
  'installed' => true,
  'instanceid' => 'ochghoy8fko5',
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' =>
  array (
    'host' => '/var/run/redis/redis.sock',
    'port' => 0,
    'timeout' => 0.0,
    'password' => '0RQkxt+9b+TglKqf6S2lwhXb8XUKarU62Kc+BczHBPw=',
  ),
  'tempdirectory' => '/media/USBdrive/ncdata/data/tmp',
  'mail_smtpmode' => 'sendmail',
  'mail_smtpauthtype' => 'LOGIN',
  'mail_from_address' => 'admin',
  'mail_domain' => 'ownyourbits.com',
  'preview_max_x' => '2048',
  'preview_max_y' => '2048',
  'jpeg_quality' => '60',
  'overwriteprotocol' => 'https',
  'maintenance' => false,
  'logfile' => '/media/USBdrive/ncdata/data/nextcloud.log',
  'trusted_proxies' =>
  array (
    11 => '127.0.0.1',
    12 => '::1',
    13 => 'nextcloudpi',
    14 => '',
  ),
  'htaccess.RewriteBase' => '/',
);
