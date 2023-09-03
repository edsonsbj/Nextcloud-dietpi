# Change data directory for external storage
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

sudo apt install btrfs-progs -y
sudo umount /dev/sda1
sudo mkfs.btrfs -f /dev/sda1
sudo mkdir /media/myCloudDrive          # Change this if you want to mount the drive elsewhere, like /mnt/, or change
UUID=$(sudo blkid -s UUID -o value /dev/sda1)
echo "UUID=$UUID /media/myCloudDrive btrfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo systemctl daemon-reload

rsync -avh /mnt/dietpi_userdata/nextcloud_data /media/myCloudDrive
chown -R www-data:www-data /media/myCloudDrive/nextcloud_data
chmod -R 770 /media/myCloudDrive/nextcloud_data

sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

sudo systemctl restart redis-server
sudo systemctl restart apache2

# If Using Swap

sudo swapoff -a
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
free -h
