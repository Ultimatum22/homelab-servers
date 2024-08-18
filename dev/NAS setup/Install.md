# Install NAS

## Install the server with this script, change DISK1 and DISK2 if needed

`bash
#!/bin/bash

# Define the devices and RAID array
DISK1="/dev/sda"
DISK2="/dev/sdb"
RAID_ARRAY="/dev/md0"
MOUNT_POINT="/mnt/boot"
HOSTNAME="my-debian-server"

# Ensure that necessary packages are installed on the live environment
apt-get update
apt-get install -y mdadm debootstrap grub-pc parted

# Wipe the partition tables on both disks to avoid conflicts
sgdisk --zap-all $DISK1
sgdisk --zap-all $DISK2

# Create a new GPT partition table on each disk
parted -s $DISK1 mklabel gpt
parted -s $DISK2 mklabel gpt

# Create a BIOS boot partition (2MB) at the beginning of each disk
parted -s $DISK1 mkpart primary 1MiB 3MiB
parted -s $DISK2 mkpart primary 1MiB 3MiB

# Set the BIOS boot flag on the BIOS boot partition
parted -s $DISK1 set 1 bios_grub on
parted -s $DISK2 set 1 bios_grub on

# Create a single primary partition for RAID on each disk, after the BIOS boot partition
parted -s -a optimal $DISK1 mkpart primary 3MiB 100%
parted -s -a optimal $DISK2 mkpart primary 3MiB 100%

# Set the partition type to Linux RAID
parted -s $DISK1 set 2 raid on
parted -s $DISK2 set 2 raid on

# Create the RAID 1 array
mdadm --create --verbose $RAID_ARRAY --level=1 --raid-devices=2 ${DISK1}2 ${DISK2}2

# Wait for RAID array to sync
echo "Waiting for RAID 1 array to synchronize..."
while [ $(cat /proc/mdstat | grep -c "\<md0\>") -eq 0 ]; do
    sleep 1
done
echo "RAID array synchronization started."

# Create the filesystem on the RAID array
mkfs.ext4 $RAID_ARRAY

# Create a mount point and mount the RAID array
mkdir -p $MOUNT_POINT
mount $RAID_ARRAY $MOUNT_POINT

# Install the base Debian system using debootstrap
debootstrap --arch=amd64 bullseye $MOUNT_POINT http://deb.debian.org/debian/

# Mount necessary filesystems
mount --bind /dev $MOUNT_POINT/dev
mount --bind /dev/pts $MOUNT_POINT/dev/pts
mount --bind /proc $MOUNT_POINT/proc
mount --bind /sys $MOUNT_POINT/sys

# Enter the chroot environment to configure the new system
chroot $MOUNT_POINT /bin/bash <<EOF
# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Install necessary packages in the chroot environment
apt-get update
apt-get install -y mdadm initramfs-tools grub-pc

# Update /etc/mdadm/mdadm.conf with the RAID array information
mdadm --detail --scan >> /etc/mdadm/mdadm.conf

# Update initramfs
update-initramfs -u

# Install GRUB on both drives explicitly
grub-install --target=i386-pc --boot-directory=/boot $DISK1
grub-install --target=i386-pc --boot-directory=/boot $DISK2

# Update GRUB configuration
update-grub

# Set root password
echo "root:password" | chpasswd

# Create /etc/fstab
UUID=$(blkid -s UUID -o value $RAID_ARRAY)
echo "UUID=$UUID / ext4 defaults,nofail,discard 0 1" > /etc/fstab
echo "proc /proc proc defaults 0 0" >> /etc/fstab

# Exit chroot
exit
EOF

# Unmount filesystems
umount -l $MOUNT_POINT/dev/pts
umount -l $MOUNT_POINT/dev
umount -l $MOUNT_POINT/proc
umount -l $MOUNT_POINT/sys
umount -l $MOUNT_POINT

# Finish
echo "Debian installed on RAID 1 array. You can reboot into your new system."
`

