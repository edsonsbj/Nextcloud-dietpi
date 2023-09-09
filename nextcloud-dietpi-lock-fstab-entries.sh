#!/bin/bash

# Check if the script is executed as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be executed as root!"
    exit 1
fi

# Remove any previous entries in the /etc/fstab file
echo "" > /etc/fstab

# Identify devices and UUIDs of partitions using lsblk
LSBLK_OUTPUT=$(lsblk -o NAME,UUID)

# Iterate through the lines of lsblk output to create entries in /etc/fstab
while read -r line; do
    # Extract the device name and UUID from the line
    DEVICE=$(echo "$line" | awk '{print $1}')
    UUID=$(echo "$line" | awk '{print $2}')

    # Ignore lines that do not have a UUID (headers)
    if [ "$UUID" != "UUID" ]; then
        # Create the entry in /etc/fstab using the UUID
        echo "UUID=$UUID  /media/$DEVICE  ext4  defaults  0  0" >> /etc/fstab
    fi
done <<< "$LSBLK_OUTPUT"

# Show the updated /etc/fstab content
cat /etc/fstab

echo "Updated /etc/fstab configuration successfully!"
