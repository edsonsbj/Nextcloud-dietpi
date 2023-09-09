# Change data directory for external storage
sudo lsblk

# Prompt the user to select the correct folder
while true; do
    read -p "Where is the main volume? Please enter (a) 'sda1', (b) 'sdb1', (c) 'sdc1', or (d) 'sdd1': " drive_option
    case $drive_option in
        [aA])
            drive="/dev/sda1"
            break
            ;;
        [bB])
            drive="/dev/sdb1"
            break
            ;;
        [cC])
            drive="/dev/sdc1"
            break
            ;;
        [dD])
            drive="/dev/sdd1"
            break
            ;;
        *)
            echo "Invalid input. Please enter 'a', 'b', 'c', or 'd'."
            ;;
    esac
done

sudo apt install btrfs-progs -y
sudo umount "$drive"
sudo mkfs.btrfs -f "$drive"
sudo mkdir /media/myCloudBackup
UUID=$(sudo blkid -s UUID -o value "$drive")
echo "UUID=$UUID /media/myCloudBackup btrfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo systemctl daemon-reload

rsync -avh /mnt/dietpi_userdata/nextcloud_data /media/myCloudDrive
