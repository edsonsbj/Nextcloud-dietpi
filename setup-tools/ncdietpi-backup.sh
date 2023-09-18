#!/bin/bash

# Execute lsblk com as colunas desejadas e capture a saída em um arquivo temporário
lsblk -o NAME,SIZE,RO,FSTYPE,TYPE,MOUNTPOINT,UUID,PTUUID
lsblk -o NAME,UUID,PTUUID,SIZE,RO,FSTYPE,TYPE,MOUNTPOINT | grep -E '[0-9]$' > lsblk_output.txt

# Exiba as opções para o usuário
echo -e "\nEscolha o NAME do HDD de backup:"

# Use um contador para gerar as opções (a, b, c, ...)
index=0
options=()

# Leia o arquivo temporário e processe as linhas
while IFS= read -r line; do
    if [ "$line" != "NAME   UUID                                   PTUUID                                 SIZE RO TYPE MOUNTPOINT" ]; then
        name=$(echo "$line" | awk '{print $1}')
        options+=("$name")
        index=$((index + 1))
        echo -e "   $index) $name"
    fi
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
filesystem=$(blkid -s TYPE -o value /dev/$backup_name)

if [ "$filesystem" != "ext4" ]; then
    echo "A partição $backup_name não está formatada como ext4."
    echo -n "Deseja formatar a partição como ext4 (s/n)? "
    read format_option
    if [ "$format_option" == "s" ]; then
        echo "Formatando a partição $backup_name como ext4..."
        # Comente ou remova a linha abaixo para evitar formatação acidental
        mkfs.ext4 /dev/$backup_name  # Formatar a partição como ext4
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

# Remova o arquivo temporário
rm lsblk_output.txt
