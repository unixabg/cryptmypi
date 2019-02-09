#!/bin/bash

## cryptmypi
## Copyright (C) 2018-2019 Richard Nelson <unixabg@gmail.com>
##
## This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING.
## This is free software, and you are welcome to redistribute it
## under certain conditions; see COPYING for details.

# Start with pristine install of kali for raspberry pi

# Dependencies
if [ "$(id -u)" -ne "0" ]
then
	echo "E: You need to be the root user to run this script.";

	exit 1
fi

# FIXME - allow override from cmdline input
_BLKDEV="/dev/mmcblk0"
_PARTITION="/dev/mmcblk0p2"

cat << EOF

##################### W A R N I N G #####################
	This is stage-2 script of cryptmypi.
** stage-1 prepared Kali Linux sdcard is required **
##################### W A R N I N G #####################

Stage-2 information:
 * Stage-2 was designed to be ran from Linux.
 * Stage-2 requires a stage-1 prepared Kali Linux sdcard.
 * Stage-2 attempts to perform the following operations
   on the sdcard:
     1. Backup the root files.
     2. Drop the root files partition.
     3. Create a LUKS encrypted partition.
     4. Format the LUKS encrypted partition to be ext4.
     5. Restore the root files to the the LUKS enctyped partition.

This process will damage your local install if the script has
the wrong partition and block device for your system.

##################### W A R N I N G #####################
** ** ** There is no undoing these actions! ** ** **
** ** **  If you are unsure DO NOT proceed. ** ** **
##################### W A R N I N G #####################

Device information to be used with the script:

block device:  $_BLKDEV
partition:  $_PARTITION

To continue type in the phrase 'Yes, do as I say!'
EOF

echo -n ": "
read _CONTINUE

case "${_CONTINUE}" in
	'Yes, do as I say!')

		;;

	*)
		echo "Abort."

		exit 1
		;;
esac

# Clean old work area
echo "Removing /mnt/cryptmypi/{chroot,backup,encrypted} ..."
rm -rfv /mnt/cryptmypi/{chroot,backup,encrypted}
echo "Done removing old work area."
echo
echo "Making folders for new work area mkdir -p /mnt/cryptmypi/{chroot,backup,encrypted} ..."
mkdir -pv /mnt/cryptmypi/{chroot,backup,encrypted}
echo "Done making new work area."
echo

# See if the partition is mounted and attempt to unmount.
if mount | grep -qs $_PARTITION
then
	echo "$_PARTITION appears to be mounted ..."
	echo "Attempting to unmount $_PARTITION ..."
	if umount -lv $_PARTITION
	then
		echo "It appears that we were able to unmount $_PARTITION ."
	else
		echo "Appears $_PARTITION is still mounted ..."
		mount | grep $_PARTITION
		echo "Aborting since we were unable to unmount $_PARTITION !"
		exit 1
	fi
else
	echo "It appears that $_PARTITION is not mounted."
fi
echo

# Attempt to mount the partition to chroot
echo "Attempting to mount $_PARTITION ..."
if mount $_PARTITION /mnt/cryptmypi/chroot
then
	echo "We were able to mount $_PARTITION to /mnt/cryptmypi/chroot."
else
	echo "Aborting since we failed to mount $_PARTITION !"
	exit 1
fi
echo

# Attempt to backup files from the chroot mount to the backup folder
echo "Attempting to backup /mnt/cryptmypi/chroot to /mnt/cryptmypi/backup/ ..."
rsync -avh /mnt/cryptmypi/chroot/* /mnt/cryptmypi/backup/
echo

# Attempt to unmount the chroot mount
echo "Attempting to unmount /mnt/cryptmypi/chroot ..."
if umount -lv /mnt/cryptmypi/chroot
then
	echo "It appears that we were able to unmount /mnt/cryptmypi/chroot ."
else
	echo "Aborting since we failed to unmount  /mnt/cryptmypi/chroot !"
	exit 1
fi
echo

# Attempt to do partition operations
# First attempt to drop partition
echo "Attempting to drop second partition on $_BLKDEV ..."
if echo -e "d\n2\nw" | fdisk $_BLKDEV
then
	echo "It appears that we were able to drop the partition on $_BLKDEV ."
	echo "Below is the output of lsblk."
	lsblk
else
	echo "Aborting since we failed to drop the partition on $_BLKDEV !"
	exit 1
fi
echo

# Second attempt to create new partition
echo "Attempting to create new partition on $_BLKDEV ..."
if echo -e "n\np\n2\n\n\nw" | fdisk $_BLKDEV
then
	echo "It appears that we were able to create the new partition on $_BLKDEV ."
	echo "Below is the output of lsblk."
	lsblk
else
	echo "Aborting since we failed to create the partition on $_BLKDEV !"
	exit 1
fi
echo

# Create LUKS
echo "Attempting to create LUKS $_PARTITION ..."
if cryptsetup -v -y --cipher aes-cbc-essiv:sha256 --key-size 256 luksFormat $_PARTITION
then
	echo "LUKS created."
else
	echo "Aborting since we failed to create LUKS on $_PARTITION !"
	exit 1
fi
echo

# Open LUKS
echo "Attempting to open LUKS $_PARTITION ..."
if cryptsetup -v luksOpen $_PARTITION crypt
then
	echo "LUKS opened."
else
	echo "Aborting since we failed to open LUKS on $_PARTITION !"
	exit 1
fi
echo

# Format LUKS
echo "Attempting to format LUKS on /dev/mapper/crypt ..."
if mkfs.ext4 /dev/mapper/crypt
then
	echo "LUKS formatted to ext4."
else
	echo "Aborting since we failed to format /dev/mapper/crypt to ext4 !"
	exit 1
fi
echo

# Mount ext4 formatted LUKS
echo "Attempting to mount /dev/mapper/crypt to /mnt/cryptmypi/encrypted/ ..."
if mount /dev/mapper/crypt /mnt/cryptmypi/encrypted/
then
	echo "Mounted /dev/mapper/crypt to /mnt/cryptmypi/encrypted ."
else
	echo "Aborting since we failed to mount /dev/mapper/crypt to /mnt/cryptmypi/encrypted !"
	exit 1
fi
echo

# Attempt to restore files from the chroot backup to the mounted encrypted folder
echo "Attempting to restore /mnt/cryptmypi/backup to /mnt/cryptmypi/encrypted/ ..."
rsync -avh /mnt/cryptmypi/backup/* /mnt/cryptmypi/encrypted/
echo

# Sync file system
echo "Syncing the filesystems ...."
sync
sync
echo "Done syncing the filesystems."
echo

# Unmount ext4 formatted LUKS
echo "Attempting to unmount /mnt/cryptmypi/encrypted/ ..."
if umount /mnt/cryptmypi/encrypted/
then
	echo "Unmounted /mnt/cryptmypi/encrypted ."
else
	echo "Aborting since we failed to unmount /mnt/cryptmypi/encrypted !"
	exit 1
fi
echo


# Close LUKS
echo "Attempting to close open LUKS $_PARTITION ..."
if cryptsetup -v luksClose /dev/mapper/crypt
then
	echo "LUKS closed."
else
	echo "Aborting since we failed to open LUKS on $_PARTITION !"
	exit 1
fi
echo

echo "Stage-2 appears completed!"

