
# First clean up the old system parations and mdadm arrays if needed

`bash
#!/bin/bash

# Stop all active RAID arrays
echo "Stopping all RAID arrays..."
mdadm --stop --scan

# Remove all RAID devices
echo "Removing all RAID devices..."
for raid in $(ls /dev/md* | grep -v 'stat'); do
    mdadm --stop $raid
    mdadm --remove $raid
done

# Zero out superblocks and clear partitions on specific disks from /dev/sda to /dev/sdf
echo "Wiping RAID superblocks and clearing partitions from /dev/sda to /dev/sdf..."
for disk in {a..f}; do
    if [ -e /dev/sd$disk ]; then
        # Zero out RAID superblock
        mdadm --zero-superblock /dev/sd$disk
        echo "Cleared RAID superblock on /dev/sd$disk"

        # Clear all partitions
        sgdisk --zap-all /dev/sd$disk
        echo "Cleared partitions on /dev/sd$disk"
    else
        echo "/dev/sd$disk does not exist, skipping..."
    fi
done

# Optional: Remove mdadm configuration files
echo "Removing mdadm configuration..."
rm -f /etc/mdadm/mdadm.conf
update-initramfs -u

# Uninstall mdadm package (Optional)
# Uncomment the following lines if you want to uninstall mdadm completely
# echo "Uninstalling mdadm package..."
# apt-get remove --purge -y mdadm
# apt-get autoremove -y

# Final message
echo "All RAID arrays have been removed, and disks /dev/sda to /dev/sdf have been cleaned."
`