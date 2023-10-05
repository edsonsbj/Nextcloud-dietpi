#!/bin/bash





##########################################################################################################################################################
#################################################################### FUNÇÃO BACKUP.SH ####################################################################
##########################################################################################################################################################
backup() {

  cat > backup.sh <<EOF
  #!/bin/bash
  
  CONFIG="\$(dirname "\${BASH_SOURCE[0]}")/.conf"
  . \$CONFIG
  
  ## ---------------------------------- TESTS ------------------------------ #
  
  # Check if the script is being executed by root or with sudo
  if [[ \$EUID -ne 0 ]]; then
     echo "########## This script needs to be executed as root or with sudo. ##########" 
     exit 1
  fi
  
  # Check if the removable drive is connected and mounted correctly
  if [[ \$(lsblk -no uuid /dev/sd*) == *"\$uuid"* ]]; then
      echo "########## The drive is connected and mounted. ##########"
      sudo mount -U \$uuid \$BackupDir
  else
      echo "########## The drive is not connected or mounted. ##########"
      exit 1
  fi
  
  # Are there write and read permissions?
  [ ! -w "\$BackupDir" ] && {
    echo "########## No write permissions ##########" >> \$LogFile
    exit 1
  }
  
  echo "Changing to the root directory..."
  cd /
  echo "pwd is \$(pwd)"
  echo "backup file location db is " '/'
  
  if [ \$? -eq 0 ]; then
      echo "Done"
  else
      echo "failed to change to root directory. Restoration failed"
      exit 1
  fi
  
  ## ------------------------------------------------------------------------ #
  
     echo "########## Starting Backup \$( date ). ##########" >> \$LogFile
  
  # -------------------------------FUNCTIONS----------------------------------------- #
  
  # Function to backup Nextcloud settings
  nextcloud_settings() {
      echo "############### Backing up Nextcloud settings... ###############" >> \$LogFile
     	# Enabling Maintenance Mode
  	echo
  	sudo -u www-data php \$NextcloudConfig/occ maintenance:mode --on >> \$LogFile
  	echo
  
  	# Stop Web Server
  	systemctl stop \$webserverServiceName
  
      # Backup
  	sudo rsync -avhP --delete --exclude '*/data/' "\$NextcloudConfig" "\$BackupDir/Nextcloud" 1>> \$LogFile
  
  	# Export the database.
  	mysqldump --quick -n --host=\$HOSTNAME \$NextcloudDatabase --user=\$DBUser --password=\$DBPassword > "\$BackupDir/Nextcloud/nextclouddb_.sql" >> \$LogFile
  
  	# Start Web Server
  	systemctl start \$webserverServiceName
  
  	# Disabling Nextcloud Maintenance Mode
  	echo
  	sudo -u www-data php \$NextcloudConfig/occ maintenance:mode --off >> \$LogFile
  	echo
  }
  
  # Function to backup Nextcloud DATA folder
  nextcloud_data() {
      echo "############### Backing up Nextcloud DATA folder...###############" >> \$LogFile
  	# Enabling Maintenance Mode
  	echo
  	sudo -u www-data php \$NextcloudConfig/occ maintenance:mode --on >> \$LogFile
  	echo
  
      # Backup
  	sudo rsync -avhP --delete --exclude '*/files_trashbin/' "\$NextcloudDataDir" "\$BackupDir/Nextcloud_datadir" 1>> \$LogFile
  
  	# Disabling Nextcloud Maintenance Mode
  	echo
  	sudo -u www-data php \$NextcloudConfig/occ maintenance:mode --off >> \$LogFile
  	echo
  }
  
  # Function to perform a complete Nextcloud backup
  nextcloud_complete() {
      echo "########## Performing complete Nextcloud backup...##########"
      nextcloud_settings
      nextcloud_data
  }
  
  # Function to backup Emby settings
  emby_settings() {
      echo "########## Backing up Emby Server settings...##########" >> \$LogFile
      # Stop Emby
      sudo systemctl stop emby-server.service
  
      # Backup
      sudo rsync -avhP --delete --exclude '*/cache' --exclude '*/logs' --exclude '*/transcoding-temp' "\$Emby_Conf" "\$BackupDir/emby" 1>> \$LogFile
   
      # Start Emby
      sudo systemctl start emby-server.service
  }
  
  # Function to backup Emby Media Server and Nextcloud settings
  nextcloud_and_emby_settings() {
      echo "########## Backing up Emby Media Server and Nextcloud settings...##########"
      nextcloud_settings
      emby_settings
  }
  
  # Function to backup Jellyfin settings
  jellyfin_settings() {
      echo "########## Backing up Jellyfin settings...##########" >> \$LogFile
      # Stop Jellyfin
      sudo systemctl stop jellyfin.service
  
      # Backup
      sudo rsync -avhP --delete --exclude '*/cache' --exclude '*/logs' --exclude '*/transcoding-temp' "\$Jellyfin_Conf" "\$BackupDir/jellyfin" 1>> \$LogFile
  
      # Start Jellyfin
      sudo systemctl start jellyfin.service
  }
  
  # Function to backup Jellyfin and Nextcloud settings
  nextcloud_and_jellyfin_settings() {
      echo "########## Backing up Jellyfin and Nextcloud settings...##########"
      nextcloud_settings
      jellyfin_settings
  }
  
  # Function to backup Plex settings
  plex_settings() {
      echo "########## Backing up Plex Media Server settings...##########" >> \$LogFile
      # Stop Plex
      sudo systemctl stop plexmediaserver
  
      # Backup
      sudo rsync -avhP --delete --exclude '*/Cache' --exclude '*/Crash Reports' --exclude '*/Diagnostics' --exclude '*/Logs' "\$Plex_Conf" "\$BackupDir/Plex" 1>> \$LogFile
  
      # Start Plex
      sudo systemctl start plexmediaserver
  }
  
  # Function to backup Plex Media Server and Nextcloud settings
  nextcloud_and_plex_settings() {
      echo "########## Backing up Plex Media Server and Nextcloud settings...##########"
      nextcloud_settings
      plex_settings
  }
  
  # Check if an option was passed as an argument
  if [[ ! -z \$1 ]]; then
      # Execute the corresponding restore option
      case \$1 in
          1)
              nextcloud_complete
              ;;
          2)
              nextcloud_settings
              ;;
          3)
              nextcloud_data
              ;;
          4)
              emby_settings
              ;;
          5)
              nextcloud_and_emby_settings
              ;;
          6)
              nextcloud_complete_and_emby_settings
              ;;
          7)
              jellyfin_settings
              ;;
          8)
              nextcloud_and_jellyfin_settings
              ;;
          9)
              nextcloud_complete_and_jellyfin_settings
              ;;
          10)
              plex_settings
              ;;
          11)
              nextcloud_and_plex_settings
              ;;
          12)
              nextcloud_complete_and_plex_settings
              ;;
          *)
              echo "Invalid option!"
              ;;
      esac
  
  else
      # Display the menu to choose the restore option
      echo "Choose a restore option:"
      echo "	 1	>> Backup Nextcloud configurations, database, and data folder."
      echo "	 2	>> Backup Nextcloud configurations and database."
      echo "	 3	>> Backup only the Nextcloud data folder. Useful if the folder is stored elsewhere."
      echo "	 4	>> Backup Emby Media Server settings."
      echo "	 5	>> Backup Nextcloud and Emby Settings."
      echo "	 6	>> Backup Nextcloud settings, database and data folder, as well as Emby settings."
      echo "	 7	>> Backup Jellyfin Settings."
      echo "	 8	>> Backup Nextcloud and Jellyfin Settings."
      echo "	 9	>> Backup Nextcloud settings, database and data folder, as well as Jellyfin settings."
      echo "	10	>> Backup Plex Media Server Settings."
      echo "	11	>> Backup Nextcloud and Plex Media Server Settings."
      echo "	12	>> Backup Nextcloud settings, database and data folder, as well as Plex Media Server settings."
  
      # Read the option entered by the user
      read option
  
      # Execute the corresponding restore option
      case \$option in
          1)
              nextcloud_complete
              ;;
          2)
              nextcloud_settings
              ;;
          3)
              nextcloud_data
              ;;
          4)
              emby_settings
              ;;
          5)
              nextcloud_and_emby_settings
              ;;
          6)
              nextcloud_complete_and_emby_settings
              ;;
          7)
              jellyfin_settings
              ;;
          8)
              nextcloud_and_jellyfin_settings
              ;;
          9)
              nextcloud_complete_and_jellyfin_settings
              ;;
          10)
              plex_settings
              ;;
          11)
              nextcloud_and_plex_settings
              ;;
          12)
              nextcloud_complete_and_plex_settings
              ;;
          *)
              echo "Invalid option!"
              ;;
      esac
  fi
  
  # Worked well? Unmount.
  [ "\$?" = "0" ] && {
    echo "############## Backup completed. The removable drive has been unmounted and powered off. ###########" >> \$LogFile
    eval umount /dev/disk/by-uuid/\$uuid
    eval sudo udisksctl power-off -b /dev/disk/by-uuid/\$uuid >>\$LogFile
    exit 0
  }
  EOF
      
  sudo chmod +x backup.sh  # Isso torna o script executável (apenas necessário uma vez)
  sudo ./backup.sh         # Execute o script
  sudo rm backup.sh        # Deletar o script criado
}











###########################################################################################################################################################
#################################################################### FUNÇÃO RESTORE.SH ####################################################################
###########################################################################################################################################################

restore() {
  cat > restore.sh <<EOF
  #!/bin/bash
  
  CONFIG="$(dirname "${BASH_SOURCE[0]}")/.conf"
  . $CONFIG
  
  ## ---------------------------------- TESTS ------------------------------ #
  
  # Check if the script is being executed by root or with sudo
  if [[ $EUID -ne 0 ]]; then
     echo "########## This script needs to be executed as root or with sudo. ##########" 
     exit 1
  fi
  
  # Check if the removable drive is connected and mounted correctly
  if [[ $(lsblk -no uuid /dev/sd*) == *"$uuid"* ]]; then
      echo "########## The drive is connected and mounted. ##########"
      sudo mount -U $uuid $BackupDir
  else
      echo "########## The drive is not connected or mounted. ##########"
      exit 1
  fi
  
  # Are there write and read permissions?
  [ ! -w "$BackupDir" ] && {
    echo "########## No write permissions ##########" >> $LogFile
    exit 1
  }
  
  echo "Changing to the root directory..."
  cd /
  echo "pwd is $(pwd)"
  echo "restore file location db is " '/'
  
  if [ $? -eq 0 ]; then
      echo "Done"
  else
      echo "failed to change to root directory. Restoration failed"
      exit 1
  fi
  
  ## ------------------------------------------------------------------------ #
  
     echo "########## Restoration Started $( date ). ##########" >> $LogFile
  
  # -------------------------------FUNCTIONS----------------------------------------- #
  
  # Function to restore Nextcloud settings
  nextcloud_settings() {
      echo "############### Restoring Nextcloud settings... ###############" >> $LogFile
     	# Enabling Maintenance Mode
  	echo
  	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on >> $LogFile
  	echo
  
  	# Stop Web Server
  	systemctl stop $webserverServiceName
  
  	# Remove the current Nextcloud folder
  	rm -rf "$NextcloudConfig"
  
      # Restore
  	sudo rsync -avhP "$BackupDir/Nextcloud" "$NextcloudConfig" 1>> $LogFile
  
  	# Restore permissions
  	chmod -R 755 $NextcloudConfig
  	chown -R www-data:www-data $NextcloudConfig
  
  	# Export the database.
  	mysql -u --host=localhost --user=$DBUser --password=$PDBPassword $NextcloudDatabase < "$BackupDir/Nextcloud/nextclouddb.sql" >> $LogFile
  
  	# Start Web Server
  	systemctl start $webserverServiceName
  
  	# Disabling Nextcloud Maintenance Mode
  	echo
  	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off >> $LogFile
  	echo
  }
  
  # Function to restore Nextcloud DATA folder
  nextcloud_data() {
      echo "############### Restoring Nextcloud DATA folder...###############" >> $LogFile
  	# Enabling Maintenance Mode
  	echo
  	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --on >> $LogFile
  	echo
  
      # Restore
  	sudo rsync -avhP "$BackupDir/Nextcloud_datadir" "$NextcloudDataDir" 1>> $LogFile
  
  	# Restore permissions
  	chmod -R 770 $NextcloudDataDir
  	chown -R www-data:www-data $NextcloudDataDir
  
  	# Disabling Nextcloud Maintenance Mode
  	echo
  	sudo -u www-data php $NextcloudConfig/occ maintenance:mode --off >> $LogFile
  	echo
  }
  
  # Function to perform a complete Nextcloud restore
  nextcloud_complete() {
      echo "########## Performing complete Nextcloud restore...##########"
      nextcloud_settings
      nextcloud_data
  }
  
  # Function to restore Emby settings
  emby_settings() {
      echo "########## Restoring Emby Server settings...##########" >> $LogFile
      # Stop Emby
      sudo systemctl stop emby-server.service
  
      # Remove the current directory from Emby
      rm -rf $Emby_Conf
  
      # Restore
      sudo rsync -avhP "$BackupDir/emby" "$Emby_Conf" 1>> $LogFile
  
      # Restore permissions
      chmod -R 755 $Emby_Conf
      chown -R emby:emby $Emby_Conf
  
      # Add the Plex User to the www-data group to access Nextcloud folders
      sudo adduser emby www-data
  
      # Start Emby
      sudo systemctl start emby-server.service
  }
  
  # Function to restore Emby Media Server and Nextcloud settings
  nextcloud_and_emby_settings() {
      echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
      nextcloud_settings
      emby_settings
  }
  
  # Function to restore Emby Media Server and Nextcloud settings
  nextcloud_complete_and_emby_settings() {
      echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
      nextcloud_settings
      nextcloud_data
      emby_settings
  }
  
  # Function to restore Jellyfin settings
  jellyfin_settings() {
      echo "########## Restoring Jellyfin settings...##########" >> $LogFile
      # Stop Emby
      sudo systemctl stop jellyfin.service
  
      # Remove the current directory from Jellyfin
      rm -rf "$Jellyfin_Conf"
  
      # Restore
      sudo rsync -avhP "$BackupDir/jellyfin" "$Jellyfin_Conf" 1>> $LogFile
  
      # Restore permissions
      chmod -R 755 $Jellyfin_Conf
      chown -R jellyfin:jellyfin $Jellyfin_Conf
  
      # Add the Plex User to the www-data group to access Nextcloud folders
      sudo adduser jellyfin www-data
  
      # Start Jellyfin
      sudo systemctl start jellyfin.service
  }
  
  # Function to restore Jellyfin and Nextcloud settings
  nextcloud_and_jellyfin_settings() {
      echo "########## Restoring Jellyfin and Nextcloud settings...##########"
      nextcloud_settings
      jellyfin_settings
  }
  
  # Function to restore Emby Media Server and Nextcloud settings
  nextcloud_complete_and_jellyfin_settings() {
      echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
      nextcloud_settings
      nextcloud_data
      jellyfin_settings
  }
  
  # Function to restore Plex settings
  plex_settings() {
      echo "########## Restoring Plex Media Server settings...##########" >> $LogFile
      # Stop Emby
      sudo systemctl stop plexmediaserver
  
      # Remove the current directory from Plex
      rm -rf $Plex_Conf
  
      # Restore 
      sudo rsync -avhP "$BackupDir/Plex" "$Plex_Conf" 1>> $LogFile
  
      # Restore permissions
      chmod -R 755 $Plex_Conf
      chown -R plex:plex $Plex_Conf
  
      # Add the Plex User to the www-data group to access Nextcloud folders
      sudo adduser plex www-data
  
      # Start Plex
      sudo systemctl start plexmediaserver
  }
  
  # Function to restore Plex Media Server and Nextcloud settings
  nextcloud_and_plex_settings() {
      echo "########## Restoring Plex Media Server and Nextcloud settings...##########"
      nextcloud_settings
      plex_settings
  }
  
  # Function to restore Emby Media Server and Nextcloud settings
  nextcloud_complete_and_plex_settings() {
      echo "########## Restoring Emby Media Server and Nextcloud settings...##########"
      nextcloud_settings
      nextcloud_data
      plex_settings
  }
  
  # Check if an option was passed as an argument
  if [[ ! -z $1 ]]; then
      # Execute the corresponding restore option
      case $1 in
          1)
              nextcloud_complete
              ;;
          2)
              nextcloud_settings
              ;;
          3)
              nextcloud_data
              ;;
          4)
              emby_settings
              ;;
          5)
              nextcloud_and_emby_settings
              ;;
          6)
              nextcloud_complete_and_emby_settings
              ;;
          7)
              jellyfin_settings
              ;;
          8)
              nextcloud_and_jellyfin_settings
              ;;
          9)
              nextcloud_complete_and_jellyfin_settings
              ;;
          10)
              plex_settings
              ;;
          11)
              nextcloud_and_plex_settings
              ;;
          12)
              nextcloud_complete_and_plex_settings
              ;;
          *)
              echo "Invalid option!"
              ;;
      esac
  
  else
      # Display the menu to choose the restore option
      echo "Choose a restore option:"
      echo "	 1	>> Restore Nextcloud configurations, database, and data folder."
      echo "	 2	>> Restore Nextcloud configurations and database."
      echo "	 3	>> Restore only the Nextcloud data folder. Useful if the folder is stored elsewhere."
      echo "	 4	>> Restore Emby Media Server settings."
      echo "	 5	>> Restore Nextcloud and Emby Settings."
      echo "	 6	>> Restore Nextcloud settings, database and data folder, as well as Emby settings."
      echo "	 7	>> Restore Jellyfin Settings."
      echo "	 8	>> Restore Nextcloud and Jellyfin Settings."
      echo "	 9	>> Restore Nextcloud settings, database and data folder, as well as Jellyfin settings."
      echo "	10	>> Restore Plex Media Server Settings."
      echo "	11	>> Restore Nextcloud and Plex Media Server Settings."
      echo "	12	>> Restore Nextcloud settings, database and data folder, as well as Plex Media Server settings."
  
      # Read the option entered by the user
      read option
  
      # Execute the corresponding restore option
      case $option in
          1)
              nextcloud_complete
              ;;
          2)
              nextcloud_settings
              ;;
          3)
              nextcloud_data
              ;;
          4)
              emby_settings
              ;;
          5)
              nextcloud_and_emby_settings
              ;;
          6)
              nextcloud_complete_and_emby_settings
              ;;
          7)
              jellyfin_settings
              ;;
          8)
              nextcloud_and_jellyfin_settings
              ;;
          9)
              nextcloud_complete_and_jellyfin_settings
              ;;
          10)
              plex_settings
              ;;
          11)
              nextcloud_and_plex_settings
              ;;
          12)
              nextcloud_complete_and_plex_settings
              ;;
          *)
              echo "Invalid option!"
              ;;
      esac
  fi
  
    # Worked well? Unmount.
    [ "$?" = "0" ] && {
      echo "############## Restore completed. The removable drive has been unmounted and powered off. ###########" >> $LogFile
   	eval umount /dev/disk/by-uuid/$uuid
  	eval sudo udisksctl power-off -b /dev/disk/by-uuid/$uuid >>$LogFile
      exit 0
    }
  }
  
  EOF

  sudo chmod +x restore.sh  # Isso torna o script executável (apenas necessário uma vez)
  sudo ./restore.sh         # Execute o script
  sudo rm restore.sh        # Deletar o script criado

}









###########################################################################################################################################################
##################################################################### FUNÇÃO SETUP.SH #####################################################################
###########################################################################################################################################################


# Função para configuração
setup() {
  cat > setup.sh <<EOF
  #!/bin/bash

#
# Pre defined variables
#
BackupDir='/mnt/nextcloud_backup'
BackupRestoreConf='BackupRestore.conf'
LogFile='/var/log/Rsync-$(date +%Y-%m-%d_%H-%M).txt'
webserverServiceName='nginx'
NextcloudConfig='/var/www/nextcloud'

# Function for error messages
errorecho() { cat <<< "$@" 1>&2; }

#
# Check for root
#
if [ "$(id -u)" != "0" ]
then
	errorecho "ERROR: This script has to be run as root!"
	exit 1
fi

#
# Gather information
#
clear

lsblk -o NAME,SIZE,RO,FSTYPE,TYPE,MOUNTPOINT,UUID,PTUUID | grep 'sd'
 
# List of available partitions
partitions=($(lsblk -o NAME,TYPE | grep 'part' | awk '{print $1}'))
num_partitions=${#partitions[@]}
 
# Check if there is at least one partition
if [ "$num_partitions" -eq 0 ]; then
    echo "No partitions found."
    exit 1
fi
 
# List available partitions with enumerated numbers
echo "Available partitions:"
for ((i = 0; i < num_partitions; i++)); do
    echo "$((i + 1)). ${partitions[i]}"
done
 
# Ask the user to choose a partition by number
read -p "Enter the desired partition number (1-$num_partitions): " partition_number
 
# Check if the partition number is valid
if ! [[ "$partition_number" =~ ^[0-9]+$ ]]; then
    echo "Invalid partition number."
    exit 1
fi
 
# Verifique se o número de partição está dentro do intervalo válido
if [ "$partition_number" -lt 1 ] || [ "$partition_number" -gt "$num_partitions" ]; then
    echo "Número de partição fora do intervalo válido."
    exit 1
fi
 
# Get the name of the selected partition
selected_partition="${partitions[$((partition_number - 1))]}"
#echo "$selected_partition"
selected_partition_cleaned=$(echo "$selected_partition" | sed 's/[└─├]//g')
#echo "$selected_partition_cleaned"
# Use the 'blkid' command to get the UUID of the selected partition
uuid="$(blkid -s UUID -o value /dev/"$selected_partition_cleaned")"
 
# Check if the UUID was found
if [ -n "$uuid" ]; then
    echo "$uuid"
else
    echo "Partition not found or UUID not available."
fi

echo "Enter the backup drive mount point here."
echo "Default: ${BackupDir}"
echo ""
read -p "Enter a directory or press ENTER if the backup directory is ${BackupDir}: " BACKUPDIR

[ -z "$BACKUPDIR" ] ||  BackupDir=$BACKUPDIR
clear

# Nextcloud Backup
read -p "Do you want to Backup Nextcloud? (Y/n) " nextcloud

# Check user response
if [[ $nextcloud == "y" || $nextcloud == "y" ]]; then
     echo "Backing up Nextcloud..."
     echo "Enter the path to the Nextcloud file directory."
     echo "Usually: ${NextcloudConfig}"
     echo ""
     read -p "Enter a directory or press ENTER if the file directory is ${NextcloudConfig}: " NEXTCLOUDCONF

     [ -z "$NEXTCLOUDCONF" ] ||  NextcloudConfig=$NEXTCLOUDCONF
     clear

     echo "Enter the webserver service name."
     echo "Usually: nginx or apache2"
     echo ""
     read -p "Enter an new webserver service name or press ENTER if the webserver service name is ${webserverServiceName}: " WEBSERVERSERVICENAME

     [ -z "$WEBSERVERSERVICENAME" ] ||  webserverServiceName=$WEBSERVERSERVICENAME
     clear

     echo ""
     read -p "Should the backed up data be compressed (pigz should be installed in the machine)? [Y/n]: " USECOMPRESSION

     NextcloudDataDir=$(sudo -u www-data $NextcloudConfig/occ config:system:get datadirectory)
     DatabaseSystem=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbtype)
     NextcloudDatabase=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbname)
     DBUser=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbuser)
     DBPassword=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbpassword)
    
    clear

    echo "UUID: ${uuid}"
    echo "BackupDir: ${BackupDir}"
    echo "NextcloudConfig: ${NextcloudConfig}"
    echo "NextcloudDataDir: ${NextcloudDataDir}"

read -p "Is the information correct? [y/n] " CORRECTINFO

if [ "$CORRECTINFO" != 'y' ] ; then
  echo ""
  echo "ABORTING!"
  echo "No file has been altered."
  exit 1
fi

else
     echo "Nextcloud backup will not be done."
fi

clear

# Ask the user if they want to backup Emby configurations
echo "Do you want to backup Emby configurations? (y/n)"
read backup

if [[ $backup == 'y' ]]; then
    # Ask the user if they run Emby or Jellyfin
    echo "Do you run Emby or Jellyfin? Type 1 for Emby, 2 for Jellyfin."
    read choice

    while true; do
        if [[ $choice == '1' ]]; then
            # Create the Emby_Conf variable and store the output /var/lib/Emby
            Emby_Conf="/var/lib/emby"
            echo "The Emby configuration location is $Emby_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Emby configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for Emby, 2 for Jellyfin."
                read choice
            fi
        elif [[ $choice == '2' ]]; then
            # Create the Jellyfin_Conf variable and store the location /var/lib/jellyfin
            Jellyfin_Conf="/var/lib/jellyfin"
            echo "The Jellyfin configuration location is $Jellyfin_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Jellyfin configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for Emby, 2 for Jellyfin."
                read choice
            fi
        else
            echo "Invalid response. Please type 1 for Emby or 2 for Jellyfin."
            read choice
        fi
    done
else
    echo "Backup of Emby configurations not requested."
fi

echo "Do you want to backup Plex Media Server configurations? (y/n)"
read backup

if [[ $backup == 'y' ]]; then
    # Ask the user how they installed Plex Media Server
    echo "How did you install Plex Media Server? Type 1 for .deb packages or apt install plexmediaserver, 2 for snap install plexmediaserver."
    read choice

    while true; do
        if [[ $choice == '1' ]]; then
            # Store the path /var/lib/plexmediaserver in the Plex_Conf variable
            Plex_Conf="/var/lib/plexmediaserver"
            echo "The Plex Media Server configuration location is $Plex_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Plex Media Server configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for .deb packages or apt install plexmediaserver, 2 for snap install plexmediaserver."
                read choice
            fi
        elif [[ $choice == '2' ]]; then
            # Store the path /var/snap/plexmediaserver in the Plex_Conf variable
            Plex_Conf="/var/snap/plexmediaserver"
            echo "The Plex Media Server configuration location is $Plex_Conf. Is this correct? (y/n)"
            read confirmation

            if [[ $confirmation == 'y' ]]; then
                echo "Plex Media Server configuration confirmed."
                break
            else
                echo "Choose again. Type 1 for .deb packages or apt install plexmediaserver, 2 for snap install plexmediaserver."
                read choice
            fi
        else
            echo "Invalid response. Please type 1 for .deb packages or apt install plexmediaserver, or 2 for snap install plexmediaserver."
            read choice
        fi
    done
else
    echo "Backup of Plex Media Server configurations not requested."
fi

{ echo "# Configuration for Backup-Restore scripts"
  echo ""
  echo "# TODO: The uuid of the backup drive"
  echo "uuid='$'"
  echo ""
  echo "# TODO: The Backup Drive Mount Point"
  echo "BackupDir='$BackupDir'"
  echo ""
  echo "# TODO: The service name of the web server. Used to start/stop web server (e.g. 'systemctl start <webserverServiceName>')"
  echo "webserverServiceName='$webserverServiceName'"
  echo ""  
  echo "# TODO: The directory of your Nextcloud installation (this is a directory under your web root)"
  echo "NextcloudConfig='$NextcloudConfig'"
  echo ""
  echo "# TODO: The directory of your Nextcloud data directory (outside the Nextcloud file directory)"
  echo "# If your data directory is located in the Nextcloud files directory (somewhere in the web root),"
  echo "# the data directory must not be a separate part of the backup"
  echo "NextcloudDataDir='$NextcloudDataDir'"
  echo ""
  echo "# TODO: The name of the database system (one of: mysql, mariadb, postgresql)"
  echo "# 'mysql' and 'mariadb' are equivalent, so when using 'mariadb', you could also set this variable to 'mysql'" and vice versa.
  echo "DatabaseSystem='$DatabaseSystem'"
  echo ""
  echo "# TODO: Your Nextcloud database name"
  echo "NextcloudDatabase='$NextcloudDatabase'"
  echo ""
  echo "# TODO: Your Nextcloud database user"
  echo "DBUser='$DBUser'"
  echo ""
  echo "# TODO: The password of the Nextcloud database user"
  echo "DBPassword='$DBPassword'"
  echo ""
  echo "# TODO: The directory where the Emby or Jellyfin settings are stored (this directory is stored within /var/lib)"
  echo "Emby_Conf='$Emby_Conf'"
  echo "Jellyfin_Conf='$Jellyfin_Conf'"
  echo ""
  echo "# TODO: The directory where the Plex Media Server settings are stored (this directory is stored within /var/lib)"
  echo "Plex_Conf='$Plex_Conf'"
  echo ""
  echo "# Log File"
  echo "LogFile='$LogFile'"

 } > ./"${BackupRestoreConf}"



echo ""
echo "Done!"
echo ""
echo ""
echo "IMPORTANT: Please check $BackupRestoreConf if all variables were set correctly BEFORE running the backup/restore scripts!"
  EOF

  sudo chmod +x setup.sh  # Isso torna o script executável (apenas necessário uma vez)
  sudo ./setup.sh         # Execute o script
  sudo rm setup.sh        # Deletar o script criado

    
}











###########################################################################################################################################################
###################################################################### FUNÇÃO MAIN() ######################################################################
###########################################################################################################################################################


# Menu de seleção
echo "Escolha uma opção:"
echo "1 - Fazer backup"
echo "2 - Restaurar"
echo "3 - Configuração"
read escolha

# Executar a função correspondente à escolha do usuário
case $escolha in
    1)
        backup
        ;;
    2)
        restore
        ;;
    3)
        setup
        ;;
    *)
        echo "Opção inválida"
        ;;
esac
