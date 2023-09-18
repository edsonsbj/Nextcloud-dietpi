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

# Crie o diretório /media/myCloudBackup para montar o HD secundário
if [ ! -d "/media/myCloudBackup" ]; then
    echo "4) Criando o diretório /media/myCloudBackup..."
    sudo mkdir /media/myCloudBackup  # Criar o diretório se não existir
fi

# Monte a partição escolhida na pasta /media/myCloudBackup
echo "Montando /dev/$backup_name em /media/myCloudBackup/ ..."
sudo mount "/dev/$backup_name" /media/myCloudBackup

# Remova o arquivo temporário
rm lsblk_output.txt

# Crie o arquivo "backup.sh" usando cat << EOF
cat << EOF > /root/ncp-backup/ncp-backup-routine.sh
#!/usr/bin/env bash
# Script Simples para a realização de backup e restauração de pastas e arquivos usando Rsync em HD Externo

# Adicione aqui o caminho para o Arquivo Configs
CONFIG="/media/myCloudBackup"

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

# Crie o arquivo "ncp-backup-configs" usando cat << EOF
cat << EOF > /root/ncp-backup/ncp-backup-configs
#!/bin/bash

# Pastas para Backup e Restauração 
DIR01="/path/to/Imagens"

# Ponto de Montagem do HD externo 
DESTINATIONDIR="/path/to/mount/external-hard-drive"

# Caminho do Hd Externo (checar "fdisk -l")
DEVICE="/dev/sxx"

# Lista de inclusao
INCLIST="/path/to/Rsync/include-lst" 

# Arquivo de Log		
LOGFILE_PATH="/path/to/Backup-\$(date +%Y-%m-%d_%H-%M).txt"
EOF

# Crie o arquivo "include.lst" usando cat << EOF
cat << EOF > /root/ncp-backup/include.lst
path/to/Documento/Abril
path/to/Imagens/Ferias
EOF

# Torne os scripts executáveis
chmod a+x /root/ncp-backup/backup.sh
chmod a+x /root/ncp-backup/ncp-backup-configs

echo "Arquivos de configuração e scripts criados com sucesso."

# ------------------ Fim das novas etapas ------------------

