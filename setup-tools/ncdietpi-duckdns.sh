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

# Request the DuckDNS token from the user
while true; do
    echo "Enter your DuckDNS token:"
    read -r first_token

    if [[ -n "$first_token" ]]; then
        while true; do
            # Prompt the user to enter the token again for confirmation
            echo -e -n "Please re-enter the token to confirm: "
            read -r second_token

            # Check if the second token matches the first one
            if [ "$second_token" == "$first_token" ]; then
                break 2  # Exit both loops if the tokens match
            else
                echo " [ERROR] Tokens do not match. Please try again."
            fi
        done
    else
        echo " [ERROR] DuckDNS token cannot be empty. Please try again."
    fi
done

# Request the DuckDNS domain from the user
while true; do
    # Prompt the user to enter the domain (without '.duckdns.org')
    echo -e -n "Enter your DuckDNS domain ([${BOLD_YELLOW}!${RESET_COLOR}] do not need to type ".duckdns.org", just the domain): "
    read -r domain

    # Add '.duckdns.org' to the domain
    first_domain="${domain}.duckdns.org"

    # Verify domain format
    while true; do
        if [[ ! "$first_domain" =~ ^[a-zA-Z0-9.-]+\.duckdns\.org$ || "$first_domain" == *":"* ]]; then
            echo  -e " [ERROR] Invalid domain format. Please enter only the domain part without '.duckdns.org'."
            echo -e -n "Please re-enter the domain: "
            read -r first_domain
            first_domain="${first_domain}.duckdns.org"
        else
            break
        fi
    done

    while true; do
        # Prompt the user to enter the domain again for confirmation
        echo -e -n "Please re-enter the domain to confirm: "
        read -r second_domain

        # Add '.duckdns.org' to the second_domain
        second_domain="${second_domain}.duckdns.org"

        # Remove blank/empty spaces
        second_domain=$(echo "$second_domain" | tr -d '[:space:]')

        # Check if the second domain matches the first one
        if [ "$second_domain" == "$first_domain" ]; then
            break 2  # Exit both loops if the domains match
        else
            echo -e " [ERROR] Domains do not match. Please try again."
        fi
    done
done

# Create the duck.sh file with user-inserted variables
sudo tee duck.sh > /dev/null <<EOF
#!/bin/bash

# Replace 'exampledomain' with the DuckDNS domain entered by the user and '$first_token' with the entered token
echo url="https://www.duckdns.org/update?domains=$first_domain&token=$first_token&ip=" | curl -k -o ~/duckdns/duck.log -K -
EOF

# Make the file executable
sudo chmod 700 duck.sh

# Check if the cron job is already in crontab
if sudo crontab -l | grep -q '*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1'; then
    echo "Cron job is already in crontab. Nothing to do."
else
    # Add the cron task to run the script every 5 minutes
    echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1" | sudo crontab -
    echo "Cron job added to crontab."
fi

echo "The DuckDNS script has been successfully configured. Be sure to review the settings in duck.sh and replace the token and domain as needed."
