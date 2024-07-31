#!/bin/bash

# List of hosts (space-separated)
# hosts=("homelab-node01" "homelab-node02" "homelab-node04")
hosts=("192.168.2.221" "192.168.2.222" "192.168.2.224")
user="system"

# Temporary password for SSH connections
read -sp "Enter temporary password: " password
echo

# Path to your public key
public_key_path="$HOME/.ssh/homelab-infra"

# Check if the public key file exists
if [[ ! -f "$public_key_path" ]]; then
  echo "Public key file not found: $public_key_path"
  exit 1
fi

# Remove old keys from known_hosts
for host in "${hosts[@]}"; do
  ssh-keygen -R "$host"
done

# Add new key to each host
for host in "${hosts[@]}"; do
  sshpass -p "$password" ssh-copy-id -i "$public_key_path" "$user@$host"
done

echo "Keys have been updated for the specified hosts."
