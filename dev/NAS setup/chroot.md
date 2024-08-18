# When accessing chroot only to make changes

`bash
RAID_ARRAY="/dev/md0"
MOUNT_POINT="/mnt/boot"

mkdir -p $MOUNT_POINT
mount $RAID_ARRAY $MOUNT_POINT

# Mount necessary filesystems
mount --bind /dev $MOUNT_POINT/dev
mount --bind /dev/pts $MOUNT_POINT/dev/pts
mount --bind /proc $MOUNT_POINT/proc
mount --bind /sys $MOUNT_POINT/sys

chroot $MOUNT_POINT
`