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
fs_type=$(lsblk -o FSTYPE -n /dev/$backup_name)

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
    else
        echo "Operação cancelada. Saindo."
        exit 1
    fi
fi

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















######################################################## BACKUP ROUTINE ########################################################
# Crie o arquivo "backup.sh" usando cat << EOF
cat << EOF > /root/ncp-backup/ncp-backup-routine.sh
#!/usr/bin/env bash
# Script Simples para a realização de backup e restauração de pastas e arquivos usando Rsync em HD Externo

# Adicione aqui o caminho para o Arquivo Configs
CONFIG="$BACKUPDIR"

. \${CONFIG}

# NÃO ALTERE
MOUNT_FILE="/proc/mounts"
NULL_DEVICE="1> /dev/null 2>&1"
REDIRECT_LOG_FILE="1>> \$LOGFILE_PATH 2>&1"

# O Dispositivo está Montado?
grep -q "\$DEVICE" "\$MOUNT_FILE"
if [ "\$?" != "0" ]; then
  # Se não, monte em \$DESTINATIONDIR
  echo "---------- Dispositivo não montado. Monte \$DEVICE ----------" >> \$LOGFILE_PATH
  eval mount -t auto "\$DEVICE" "\$DESTINATIONDIR" "\$NULL_DEVICE"
else
  # Se sim, grep o ponto de montagem e altere o \$DESTINATIONDIR
  DESTINATIONDIR=\$(grep "\$DEVICE" "\$MOUNT_FILE" | cut -d " " -f 2)
fi

cd "/"

# Há permissões de excrita e gravação?
[ ! -w "\$DESTINATIONDIR" ] && {
  echo "---------- Não tem permissões de gravação ----------" >> \$LOGFILE_PATH
  exit 1
}
## ------------------------------------------------------------------------ #

  echo "---------- Iniciando Backup. ----------" >> \$LOGFILE_PATH

# -------------------------------FUNCTIONS----------------------------------------- #
backup() {
sudo rsync -avh --delete --progress "\$DIR01" "\$DESTINATIONDIR" --files-from "\$INCLIST" 1>> \$LOGFILE_PATH

  # Funcionou bem? Remova a Midia Externa.
  [ "\$?" = "0" ] && {
    echo "---------- Backup Finalizado. Desmonte a Unidade \$DEVICE ----------" >> \$LOGFILE_PATH
 	eval umount "\$DEVICE" "\$NULL_DEVICE"
	eval sudo udisksctl power-off -b "\${DEVICE}" >>\$LOGFILE_PATH
    exit 0
  }
}

preparelogfile () {
  # Insira um cabeçalho simples no arquivo de log com o carimbo de data/hora
  echo "----------[ \$(date) ]----------" >> \$LOGFILE_PATH
}

main () {
  preparelogfile
  backup
}
# ------------------------------------------------------------------------ #

# -------------------------------EXECUTION----------------------------------------- #
main
# ------------------------------------------------------------------------ #
EOF
######################################################## END OF BACKUP ROUTINE ########################################################















######################################################## ncp-backup-configs ########################################################
# Consulte o arquivo config.php do Nextcloud para obter o valor de datadirectory
config_file="/var/www/nextcloud/config/config.php"
datadirectory=$(grep -oP "(?<='datadirectory' => ')(.*)(?=')" "$config_file")

# Crie o arquivo de log em $BACKUPDIR
LOGFILE_PATH="$BACKUPDIR/Backup-$(date +%Y-%m-%d_%H-%M).txt"

# Crie o arquivo "ncp-backup-configs" usando cat << EOF
cat << EOF > /root/ncp-backup/ncp-backup-configs
#!/bin/bash

# Pastas para Backup e Restauração 
DIR01="$datadirectory"

# Ponto de Montagem do HD externo 
DESTINATIONDIR="$BACKUPDIR"

# Caminho do Hd Externo (checar "fdisk -l")
DEVICE="/dev/$backup_name"

# Lista de inclusao
INCLIST="/root/ncp-backup/include.lst" 

# Arquivo de Log		
LOGFILE_PATH="$BACKUPDIR/Backup-$(date +%Y-%m-%d_%H-%M).log"
EOF
######################################################## END OF ncp-backup-configs ########################################################















######################################################## include.lst ########################################################
# Crie o arquivo "include.lst" usando cat << EOF
cat << EOF > /root/ncp-backup/include.lst
path/to/Documento/Abril
path/to/Imagens/Ferias
EOF
######################################################## END OF include.lst ########################################################















# Torne os scripts executáveis
chmod a+x /root/ncp-backup/backup.sh
chmod a+x /root/ncp-backup/ncp-backup-configs

echo "Instalação e configuração da rotina de backup do seu Nextcloud realizada com sucesso!"



