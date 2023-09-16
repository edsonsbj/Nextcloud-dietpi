#!/bin/bash

# 1) Checar se ambos os hds estão na partição ext4
root_uuid=$(lsblk -no UUID /dev/sda1)  # Obter o UUID do HD principal
data_uuid=$(lsblk -no UUID /dev/sdb1)  # Obter o UUID do HD secundário

if grep -q "$data_uuid" /etc/fstab; then
    echo "1) O HD secundário já está no /etc/fstab e não deve ser formatado."
else
    echo "1) O HD secundário não está no /etc/fstab e pode ser formatado."
    echo -n "Deseja formatar o HD secundário (s/n)? "
    read format_option
    if [ "$format_option" == "s" ]; then
        echo "Formatando o HD secundário..."
        mkfs.ext4 /dev/sdb1  # Formatar o HD secundário como ext4
    fi
fi

# 2) Instalar RCLONE e borgbackup
echo -e "\033[1;32m2) Instalando RCLONE do DietPi Market...\033[0m"
/boot/dietpi/dietpi-software install 202  # Instalar RCLONE
echo -e "\033[1;32m2) Instalando GIT do DietPi Market...\033[0m"
/boot/dietpi/dietpi-software install 17   # Instalar GIT
echo -e "\033[1;32m2) Todos os softwares necessários do DietPi Market foram instalados.\033[0m"

# Instalar borgbackup
sudo apt install borgbackup -y  # Instalar borgbackup

# 3) Verificar se o git está instalado e instalá-lo, se necessário
if ! command -v git &> /dev/null; then
    echo "3) Git não está instalado. Instalando..."
    sudo apt install git -y  # Instalar Git se não estiver instalado
fi

# 4) Criar o diretório /media/myCloudBackup para montar o HD secundário
if [ ! -d "/media/myCloudBackup" ]; then
    echo "4) Criando o diretório /media/myCloudBackup..."
    sudo mkdir /media/myCloudBackup  # Criar o diretório se não existir
fi

# 5) Copiar example.conf e renomear conforme necessário
echo -n "5) Digite o nome do arquivo de configuração (exemplo: meu_backup.conf): "
read conf_file
cp example.conf "$conf_file"  # Copiar example.conf para o novo arquivo

# 6) Adicionar as pastas a serem backup no arquivo patterns.lst
echo "6) Agora, vamos configurar as pastas a serem incluídas no backup."
echo "Digite uma pasta por linha no arquivo patterns.lst (Digite '.' para parar):"
while true; do
    read -r folder
    if [ "$folder" == "." ]; then
        break
    else
        echo "$folder" >> patterns.lst  # Adicionar pasta ao arquivo patterns.lst
    fi
done

# 7) Configurar variáveis no arquivo .conf
echo "7) Agora, vamos configurar as variáveis no arquivo de configuração $conf_file."
echo -n "Digite o caminho do dispositivo externo (exemplo: /dev/sdX): "
read device
sed -i "s|^DEVICE=.*|DEVICE=\"$device\"|" "$conf_file"  # Configurar DEVICE no arquivo .conf

# Continue configurando as outras variáveis conforme necessário...

# 8) Opcionalmente, mover arquivos para /root/ncdietpi-backup/
echo "8) Você deseja mover os arquivos para /root/ncdietpi-backup/ (s/n)?"
read move_files
if [ "$move_files" == "s" ]; then
    mv "$conf_file" backup.sh patterns.lst restore.sh /root/ncdietpi-backup/  # Mover arquivos para pasta de backup
fi

# 9) Atualizar CONFIG nos arquivos backup.sh e restore.sh
sed -i "s|^CONFIG=.*|CONFIG=\"$(pwd)/$conf_file\"|" /root/ncdietpi-backup/backup.sh  # Atualizar CONFIG nos scripts de backup
sed -i "s|^CONFIG=.*|CONFIG=\"$(pwd)/$conf_file\"|" /root/ncdietpi-backup/restore.sh  # Atualizar CONFIG nos scripts de restore

# 10) Tornar os scripts executáveis
chmod +x /root/ncdietpi-backup/backup.sh /root/ncdietpi-backup/restore.sh  # Tornar os scripts executáveis

# 11) Atualizar valores em Backup.service
echo -n "11) Digite o caminho para o arquivo rclone.conf: "
read rclone_conf
sed -i "s|--config=/path/user/rclone.conf|--config=$rclone_conf|" /etc/systemd/system/Backup.service  # Atualizar o caminho do arquivo rclone.conf

echo -n "11) Digite o valor Borg: para o serviço: "
read borg_remote
sed -i "s|Borg:|$borg_remote|" /etc/systemd/system/Backup.service  # Atualizar o valor Borg: no serviço

# 12) Mover Backup.service para /etc/systemd/system/
mv Backup.service /etc/systemd/system/  # Mover o arquivo de serviço

# 13) Agendar o backup com Cron às 4 da manhã no fuso horário GMT -3
echo "13) Agendando o backup para as 4 da manhã (GMT -3)..."
echo "00 04 * * * sudo /root/ncdietpi-backup/backup.sh" | crontab -  # Configurar agendamento do backup

echo "Configuração concluída. O backup está agendado para as 4 da manhã (GMT -3)."
