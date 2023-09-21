#!/bin/bash

######################################################## FOREPLAY ########################################################
# Check if the user is in the Linux root directory
if [ "$PWD" != "/" ]; then
    echo "This script must be executed in the root directory of the system."
    exit 1
fi
echo "Changing to the root directory..."
cd /
echo "pwd is $(pwd)"
echo "location of the database backup file is " '/'

# Função para verificar se a partição é ext4
check_ext4_partition() {
    local partition="$1"
    local fs_type=$(lsblk -o FSTYPE -n "/dev/$partition")
    [ "$fs_type" == "ext4" ]
}

# Loop para permitir que o usuário escolha novamente se a partição não for ext4
while true; do
    # Execute lsblk com as colunas desejadas e capture a saída em um arquivo temporário
    lsblk -o NAME,SIZE,RO,FSTYPE,TYPE,MOUNTPOINT,UUID,PTUUID
    lsblk -o NAME,SIZE,RO,FSTYPE,TYPE,MOUNTPOINT,UUID,PTUUID | awk 'NR > 1 && $1 ~ /[0-9]+$/ { print $0 }' > lsblk_output.txt

    # Exiba as opções para o usuário
    echo -e "\nEscolha o NAME do HDD de backup:"

    # Use um contador para gerar as opções (a, b, c, ...)
    index=0
    options=()

    # Leia o arquivo temporário e processe as linhas
    while IFS= read -r line; do
        name=$(echo "$line" | awk '{print $1}' | sed -e 's/└─//g' -e 's/─//g' -e 's/├//g')
        options+=("$name")
        index=$((index + 1))
        echo -e "   $index) $name"
    done < lsblk_output.txt

    # Peça ao usuário para digitar o número correspondente à escolha do HDD de backup
    echo -n "Digite o número correspondente (1, 2, 3, ...) do HDD de backup: "
    read choice

    # Verifique se a entrada do usuário é válida
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -le 0 ] || [ "$choice" -gt "$index" ]; then
        echo "Opção inválida. Saindo."
        exit 1
    fi

    # Obtenha o NAME correspondente com base na escolha do usuário
    backup_name="${options[$choice - 1]}"

    # Verifique o sistema de arquivos da partição escolhida
    fs_type=$(lsblk -o FSTYPE -n "/dev/$backup_name")

    if [ "$fs_type" != "ext4" ]; then
        echo "A partição $backup_name não está formatada como ext4."
        echo -n "Deseja formatar a partição como ext4 (s/n)? "
        read format_option
        if [ "$format_option" == "s" ]; then
            # Desmonte a partição se estiver montada
            if grep -qs "/dev/$backup_name" /proc/mounts; then
                sudo umount "/dev/$backup_name"
            fi

            echo "Formatando a partição $backup_name como ext4..."
            # Formate a partição como ext4
            sudo mkfs.ext4 "/dev/$backup_name"
            sudo lsblk -o NAME,SIZE,FSTYPE,TYPE

            # Verifique se a partição foi formatada com sucesso como ext4
            if check_ext4_partition "$backup_name"; then
                echo "Partição formatada com sucesso como ext4."
                break  # Saia do loop, a partição agora é ext4
            else
                echo "Falha na formatação da partição. Tente novamente."
            fi
        else
            echo "Operação cancelada. Saindo."
            exit 1
        fi
    else
        break  # A partição já é ext4
    fi
done

# Verifique se o Git está instalado e instale-o, se necessário
if ! command -v git &> /dev/null; then
    echo "3) Git não está instalado. Instalando..."
    sudo apt install git -y  # Instalar Git se não estiver instalado
fi

# Crie o diretório $BACKUPDIR para montar o HD secundário
BACKUPDIR="/media/myCloudBackup"
if [ ! -d "$BACKUPDIR" ]; then
    echo "4) Criando o diretório $BACKUPDIR..."
    sudo mkdir $BACKUPDIR  # Criar o diretório se não existir
fi

# Monte a partição escolhida na pasta $BACKUPDIR
echo "Montando /dev/$backup_name em $BACKUPDIR/ ..."
sudo mount "/dev/$backup_name" $BACKUPDIR

# Remova o arquivo temporário
rm lsblk_output.txt
######################################################## END OF FOREPLAY ########################################################












#!/bin/bash

#
# Pre defined variables
#
uuid='05E1A73C04E337C0'
BackupDir='/mnt/nextcloud_backup'
NextcloudConfig='/var/www/nextcloud'
NextcloudDataDir=$(sudo -u www-data $NextcloudConfig/occ config:system:get datadirectory)
DatabaseSystem=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbtype)
NextcloudDatabase=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbname)
DBUser=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbuser)
DBPassword=$(sudo -u www-data $NextcloudConfig/occ config:system:get dbpassword)
BackupRestoreConf='BackupRestore.conf'

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

# echo "Enter the directory to which the backups should be saved."
echo "Enter the UUID of the drive"
echo "Default: ${uuid}"
echo ""
read -p "Enter the UUID corresponding to the unit that will serve as a backup or press ENTER if the UUID is ${uuid}: " UUID

[ -z "$UUID" ] ||  uuid=$UUID
clear

echo "Enter the backup drive mount point here."
echo "Default: ${BackupDir}"
echo ""
read -p "Enter a directory or press ENTER if the backup directory is ${BackupDir}: " BACKUPDIR

[ -z "$BACKUPDIR" ] ||  BackupDir=$BACKUPDIR
clear

echo "Enter the path to the Nextcloud file directory."
echo "Usually: ${NextcloudConfig}"
echo ""
read -p "Enter a directory or press ENTER if the file directory is ${NextcloudConfig}: " NEXTCLOUDCONF

[ -z "$NEXTCLOUDCONF" ] ||  NextcloudConfig=$NEXTCLOUDCONF
clear

echo "UUID: ${uuid}"
echo "BackupDir: ${BackupDir}"
echo "NextcloudConfig: ${NextcloudConfig}"
echo "NextcloudDataDir: ${NextcloudDataDir}"

read -p "Is the information correct? [y/N] " CORRECTINFO

if [ "$CORRECTINFO" != 'y' ] ; then
  echo ""
  echo "ABORTING!"
  echo "No file has been altered."
  exit 1
fi

{ echo "# Configuration for Backup-Restore scripts"
  echo ""
  echo "# TODO: The uuid of the backup drive"
  echo "uuid='$uuid'"
  echo ""
  echo "# TODO: The Backup Drive Mount Point"
  echo "BackupDir='$BackupDir'"
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
  echo "# Backup Destinations"

  echo ""
  echo "# Log File"
  echo "LOG_PATH='/var/log/'"

 } > ./"${BackupRestoreConf}"

echo ""
echo "Done!"
echo ""
echo ""
echo "IMPORTANT: Please check $BackupRestoreConf if all variables were set correctly BEFORE running the backup/restore scripts!"
