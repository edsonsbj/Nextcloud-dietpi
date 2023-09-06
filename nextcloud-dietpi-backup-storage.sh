sudo lsblk

# Prompt the user to select the correct folder
while true; do
    read -p "Is the /media/myCloudDrive/ folder allocated on (a) sda1 or (b) sdb1? Please enter 'a' or 'b': " drive_option
    case $drive_option in
        [aA])
            drive="/dev/sda1"
            other_drive="/dev/sdb1"
            break
            ;;
        [bB])
            drive="/dev/sdb1"
            other_drive="/dev/sda1"
            break
            ;;
        *)
            echo "Invalid input. Please enter 'a' or 'b'."
            ;;
    esac
done

# Unmount and format the selected drive
echo "You selected $drive as the drive for /media/myCloudDrive/."

sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on
sudo umount "$other_drive"
sudo mkfs.ext4 -f "$other_drive"
sudo mkdir /media/myCloudBackup         # Change this if you want to mount the drive elsewhere, like /mnt/, or change
UUID=$(sudo blkid -s UUID -o value $other_drive)
echo "UUID=$UUID /media/myCloudBackup ext4 defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo systemctl daemon-reload
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
sudo systemctl restart redis-server
sudo systemctl restart apache2
