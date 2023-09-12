#!/bin/bash

# Check if the user is in the root directory (/)
if [ "$PWD" != "/" ]; then
    echo "You are not in the root directory (/). Changing to the root directory..."
    cd /
fi

# Check if cron is installed
if ! ps -ef | grep -q '[c]ron'; then
    echo "Cron is not installed. Please install cron on your system."
    exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Curl is not installed. Please install curl on your system."
    exit 1
fi

# Create the directory and change to it
sudo mkdir -p ~/duckdns
cd ~/duckdns

# Request the DuckDNS domain from the user
while true; do
    # Prompt the user to enter the domain (without 'http', 'https', 'www', or 'http://')
    echo -e -n "Please enter the domain (without 'http', 'https', 'www', or 'http://') for 'overwritehost' (e.g., example.com): "
    read first_domain

    # Remove blank/empty spaces
    first_domain=$(echo "$first_domain" | tr -d '[:space:]')

    # Verify domain format
    if [[ ! "$first_domain" =~ ^[a-zA-Z0-9.-]+$ || "$first_domain" == *":"* ]]; then
        echo  -e " [ ${BOLD_RED}!${RESET_COLOR} ] Invalid domain format or contains ':' symbol at the end. Please try again."
    else
        while true; do
            # Prompt the user to enter the domain again for confirmation
            echo -e -n "Please re-enter the domain to confirm: "
            read second_domain

            # Remove blank/empty spaces
            second_domain=$(echo "$second_domain" | tr -d '[:space:]')

            # Check if the second domain matches the first one
            if [ "$second_domain" == "$first_domain" ]; then
                break 2  # Exit both loops if the domains match
            else
                echo -e " [ ${BOLD_RED}!${RESET_COLOR} ] Domains do not match. Please try again."
            fi
        done
    fi
done

# Request the DuckDNS token from the user
echo "Enter your DuckDNS token:"
while true; do
    echo "Enter your DuckDNS token:"
    read -r duckdns_token

    if [[ -n "$duckdns_token" ]]; then
        break
    else
        echo " [ERROR] DuckDNS token cannot be empty. Please try again."
    fi
done

# Create the duck.sh file with user-inserted variables
cat <<EOF > duck.sh
!/bin/bash

echo url="https://www.duckdns.org/update?domains=$first_domain&token=$duckdns_token&ip=" | curl -k -o ~/duckdns/duck.log -K -

EOF

# Make the file executable
sudo chmod 700 duck.sh

# Add the cron task to run the script every 5 minutes
sudo (crontab -l ; echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1") | crontab -

# Test the script
sudo ./duck.sh

echo "The DuckDNS script has been successfully configured. Be sure to review the settings in duck.sh and replace the token and domain as needed."
