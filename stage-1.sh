#!/bin/bash

## cryptmypi
## Copyright (C) 2018 Richard Nelson <unixabg@gmail.com>
##
## This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING.
## This is free software, and you are welcome to redistribute it
## under certain conditions; see COPYING for details.

set -e

# Start with pristine install of kali for raspberry pi

# Dependencies
if [ "$(id -u)" -ne "0" ]
then
	echo "E: You need to be the root user to run this script.";

	exit 1
fi

cat << EOF

##################### W A R N I N G #####################
	This is stage-1 script of cryptmypi.
#########################################################
This process was designed to be ran with kali on a
raspberry pi. This process will alter the local
installation. To undo these changes you will need to
reimage the sdcard.

##################### W A R N I N G #####################
You are about to do something potentially harmful to
your installation.

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


# Install luks and dropbear dependencies
sudo apt-get update
sudo apt-get install cryptsetup lvm2 busybox dropbear curl

# Append /boot/config.txt
cat << EOF >> "/boot/config.txt
initramfs initramfs.gz followkernel
EOF

# Update /boot/cmdline to boot crypt
sed -i 's#root=/dev/mmcblk0p2#root=/dev/mapper/crypt cryptdevice=/dev/mmcblk0p2:crypt#g' "/boot/cmdline"

# Update /etc/fstab to mount crypt
sed -i 's#/dev/mmcblk0p2#/dev/mapper/crypt#g' "/etc/fstab"

# FIXME tesing with spaces but might need tabs!
# Create /etc/crypttab
cat << EOF > /etc/crypttab
crypt /dev/mmcblk0p2 none luks
EOF

# Create fake luks filesystem to include cryptsetup into initramsfs
dd if=/dev/zero of=/tmp/fakeroot.img bs=1M count=20
cryptsetup luksFormat /tmp/fakeroot.img
cryptsetup luksOpen /tmp/fakeroot.img crypt
mkfs.ext4 /dev/mapper/crypt

# Download the public rsa key for dropbear inclusion
cat << EOF
######################################################
	cryptmypi - stage-1
######################################################
stage-1 script is asking for the public rsa key
for inclusion with dropbear ssh authorizad_key.
Please paste the url to a copy of client id_rsa.pub
file and press enter. Hint: make sure you are getting
plain text.
EOF

# Ask for _ID_RSA_URL
echo -n ": "
read _READ

_ID_RSA_URL=${_READ:-${_ID_RSA_URL}}
#echo ${_ID_RSA_URL}

_ID_RSA=$(curl $_ID_RSA_URL)
#echo ${_ID_RSA}

# Create /etc/dropbear-initramfs/authorized_keys
cat << EOF > /etc/dropbear-initramfs/authorized_keys
command="export PATH='/sbin:/bin/:/usr/sbin:/usr/bin'; /scripts/local-top/cryptroot && kill -9 `ps | grep -m 1 'cryptroot' | cut -d ' ' -f 3` && exit" ${_ID_RSA}
EOF

# Update dropbear for some sleep in initramfs then rebuild initramfs
sed -i 's/run_dropbear &/sleep 5\nrun_dropbear &/g' "/usr/share/initramfs-tools/scripts/init-premount/dropbear"

# Create new initramfs and check inclusion
mkinitramfs -o /boot/initramfs.gz
lsinitramfs /boot/initramfs.gz | grep cryptsetup
lsinitramfs /boot/initramfs.gz | grep authorized

# Ready for shutdown and copy of sdcard from another device
cat << EOF
We are ready to shutdown the raspberry pi and FIXME perform stage-2
on the sd card from a linux PC.
EOF

read -p "Press enter to continue"

halt
