#!/bin/bash

## cryptmypi
## Copyright (C) 2018-2019 Richard Nelson <unixabg@gmail.com>
##
## This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING.
## This is free software, and you are welcome to redistribute it
## under certain conditions; see COPYING for details.

# FIXME: it complains that something isn't lined up properly on the parted commands
# FIXME - allow override from cmdline input

# Source in config
#  - Important setting here is _BLKDEV
# Source in config
if [ ! -f config/cryptmypi.conf ]; then
	echo "cryptmypi.conf file missing in config folder."
	echo "This should have been done prior to running stage 1"
	exit 1
fi
. config/cryptmypi.conf

# Simple check for type of sdcard block device
if echo ${_BLKDEV} | grep -qs "mmcblk"
then
	__PARTITIONPREFIX=p
else
	__PARTITIONPREFIX=""
fi


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ ! -d "${_BUILDDIR}/root" ];then
   echo "cryptmypi build missing root folder. Exiting ..."
   exit 1
fi

clear
cat << EOF
#########################################################
		   C R Y P T M Y P I
		  Stage-2   (${_VER})
#########################################################
Cryptmypi stage-2 requires a stage-1 prepared Kali Linux
root folder!

Cryptmypi stage-2 will attempt to perform the following
operations on the sdcard:
     1. Partition and format the sdcard.
     2. Create bootable sdcard with LUKS encrypted root
        partition.

The following screen will display a sanity check to
verify we are working with the correct block device.

EOF

read -p "Press enter to continue."

clear
cat << EOF

##################### W A R N I N G #####################
This process can damage your local install if the script
has the wrong block device for your system.

******************** P l e a s e ************************
Double check and know you have the correct block device
that matches your sdcard.

##################### W A R N I N G #####################
  ** ** ** There is no undoing these actions! ** ** **
  ** ** **  If you are unsure DO NOT proceed. ** ** **

-------------------Sanity Check Prompt ------------------
This is a listing of your system block devices:

$(lsblk)

And below is the block device to be used with the script:

block device:  ${_BLKDEV}

If the block device is wrong DO NOT continue. Adjust the
block device in the cryptmypi.conf file located in your
cloned directory. After adjusting the block device run
the stage-2.sh script again.

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

# Attempt to unmount just to be safe
umount ${_BLKDEV}${__PARTITIONPREFIX}1
umount ${_BLKDEV}${__PARTITIONPREFIX}2
umount ${_BLKDEV}${__PARTITIONPREFIX}3
umount ${_BLKDEV}${__PARTITIONPREFIX}4
umount /mnt/cryptmypi
[ -d /mnt/cryptmypi ] && rm -r /mnt/cryptmypi


# Format SD Card
echo "Partitioning SD Card"
parted ${_BLKDEV} --script -- mklabel msdos
parted ${_BLKDEV} --script -- mkpart primary fat32 0 64
parted ${_BLKDEV} --script -- mkpart primary 64 -1
sync
sync
echo "Formatting Boot Partition"
mkfs.vfat ${_BLKDEV}${__PARTITIONPREFIX}1


# Create LUKS
echo "Attempting to create LUKS ${_BLKDEV}${__PARTITIONPREFIX}2 ..."
if cryptsetup -v -y --cipher ${_LUKSCIPHER} --key-size 256 luksFormat ${_BLKDEV}${__PARTITIONPREFIX}2
then
	echo "LUKS created."
else
	echo "Aborting since we failed to create LUKS on ${_BLKDEV}${__PARTITIONPREFIX}2 !"
	exit 1
fi
echo

# Open LUKS
echo "Attempting to open LUKS ${_BLKDEV}${__PARTITIONPREFIX}2 ..."
if cryptsetup -v luksOpen ${_BLKDEV}${__PARTITIONPREFIX}2 cryptmypi_root
then
	echo "LUKS opened."
else
	echo "Aborting since we failed to open LUKS on ${_BLKDEV}${__PARTITIONPREFIX}2 !"
	exit 1
fi
echo

# Format LUKS
echo "Attempting to format LUKS on /dev/mapper/cryptmypi_root ..."
if mkfs.ext4 /dev/mapper/cryptmypi_root
then
	echo "LUKS formatted to ext4."
else
	echo "Aborting since we failed to format /dev/mapper/cryptmypi_root to ext4 !"
	exit 1
fi
echo

# Mount ext4 formatted LUKS
echo "Attempting to mount /dev/mapper/cryptmypi_root to /mnt/cryptmypi ..."
mkdir /mnt/cryptmypi
if mount /dev/mapper/cryptmypi_root /mnt/cryptmypi
then
	echo "Mounted /dev/mapper/cryptmypi_root to /mnt/cryptmypi ."
else
	echo "Aborting since we failed to mount /dev/mapper/crypt to /mnt/cryptmypi !"
	exit 1
fi
echo

# Mount boot partition
echo "Attempting to mount ${_BLKDEV}${__PARTITIONPREFIX}1 to /mnt/cryptmypi/boot ..."
mkdir /mnt/cryptmypi/boot
if mount ${_BLKDEV}${__PARTITIONPREFIX}1 /mnt/cryptmypi/boot
then
	echo "Mounted ${_BLKDEV}${__PARTITIONPREFIX}1 to /mnt/cryptmypi/boot."
else
	echo "Aborting since we failed to mount ${_BLKDEV}${__PARTITIONPREFIX}1 to /mnt/cryptmypi/boot !"
	exit 1
fi
echo

# Attempt to rsync files from build to mounted device
echo "Attempting to rsync ${_BUILDDIR}/root/ to /mnt/cryptmypi/ ..."
rsync -HPavz -q "${_BUILDDIR}"/root/ /mnt/cryptmypi/
echo

# Sync file system
echo "Syncing the filesystems ...."
sync
sync
echo "Done syncing the filesystems."
echo

##########
# Stage-2 hook operations
#
## .hook - file to manipulate build operations
##
_HOOKOP="stage-2"
echo "Attempting to run ${_HOOKOP} hooks ..."
for _HOOK in ${_BASEDIR}/hooks/????-${_HOOKOP}-*.hook
do
	if [ -e ${_HOOK} ]; then
		echo "Calling $(basename ${_HOOK}) ..."
		${_HOOK}
	fi
done

# Unmount boot partition
echo "Attempting to unmount ${_BLKDEV}${__PARTITIONPREFIX}1 ..."
if umount ${_BLKDEV}${__PARTITIONPREFIX}1
then
	echo "Unmounted ${_BLKDEV}${__PARTITIONPREFIX}1 ."
else
	echo "Aborting since we failed to unmount ${_BLKDEV}${__PARTITIONPREFIX}1 !"
	exit 1
fi
echo

# Unmount root partition
echo "Attempting to unmount /dev/mapper/cryptmypi_root ..."
if umount /dev/mapper/cryptmypi_root
then
	echo "Unmounted /dev/mapper/cryptmypi_root ."
else
	echo "Aborting since we failed to unmount /dev/mapper/cryptmypi_root !"
	exit 1
fi
echo


# Close LUKS
echo "Attempting to close open LUKS ${_BLKDEV}${__PARTITIONPREFIX}2 ..."
if cryptsetup -v luksClose /dev/mapper/cryptmypi_root
then
	echo "LUKS closed."
else
	echo "Aborting since we failed to close LUKS /dev/mapper/cryptmypi_root !"
	exit 1
fi
echo

rm -r /mnt/cryptmypi
sync
sync

echo "Goodbye from cryptmypi stage-2 (${_VER})."
exit 0
