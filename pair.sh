#!/bin/bash

# Array of hosts
hosts=("192.168.2.221" "192.168.2.222" "192.168.2.224")

# Path to your known_hosts file and new RSA key
KNOWN_HOSTS="$HOME/.ssh/known_hosts"
NEW_KEY="$HOME/.ssh/homelab-infra"

# SSH password
PASSWORD="system"

# Function to remove the offending key and re-add the new key
update_known_hosts() {
    local host="$1"
    # Remove the offending key
    ssh-keygen -R "$host"

    # Get the new host key and add it to the known_hosts file
    ssh-keyscan -H "$host" >> "$KNOWN_HOSTS"

    # Use sshpass to add your new RSA key to the authorized_keys of the host
    sshpass -p "$PASSWORD" ssh-copy-id -i "$NEW_KEY" "system@$host"
}

# Loop through the array of hosts
for host in "${hosts[@]}"; do
    update_known_hosts "$host"
done

echo "Updated known_hosts and copied new RSA key for all specified hosts."
