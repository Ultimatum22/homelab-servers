#!/bin/bash

# Define the desired IP address and the network interface
IP_ADDR="192.168.56.20"
NET_IFACE="enp0s8"

# Check if the interface exists
if ! ip link show $NET_IFACE > /dev/null 2>&1; then
  echo "Network interface $NET_IFACE does not exist."
  exit 1
fi

# Configure the interface with the desired static IP
sudo ip addr flush dev $NET_IFACE
sudo ip addr add $IP_ADDR/24 dev $NET_IFACE
sudo ip link set $NET_IFACE up

# Update /etc/hosts to map the hostname to the new IP
echo "$IP_ADDR nas-archlinux" | sudo tee -a /etc/hosts

# Restart the network service to apply changes (this may vary by distro)
sudo systemctl restart systemd-networkd.service  # For Arch Linux
# sudo systemctl restart networking  # For Debian/Ubuntu
# sudo service network restart  # For RedHat/CentOS
