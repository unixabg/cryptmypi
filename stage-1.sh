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


# Install luks
apt-get update
apt-get install cryptsetup lvm2 busybox

# Append /boot/config.txt
cat << EOF >> /boot/config.txt
initramfs initramfs.gz followkernel
EOF

# Update /boot/cmdline.txt to boot crypt
sed -i 's#root=/dev/mmcblk0p2#root=/dev/mapper/crypt cryptdevice=/dev/mmcblk0p2:crypt#g' "/boot/cmdline.txt"

# Update /etc/fstab to mount crypt
sed -i 's#/dev/mmcblk0p2#/dev/mapper/crypt#g' "/etc/fstab"

# Create /etc/crypttab
cat << EOF > /etc/crypttab
crypt /dev/mmcblk0p2 none luks
EOF

# Enable cryptsetup when building initramfs
cat << EOF >> /etc/cryptsetup-initramfs/conf-hook
CRYPTSETUP=y
EOF

# Create a hook to include our crypttab in the initramfs
cat << "EOF" > /usr/share/initramfs-tools/hooks/zz-crypttab
#!/bin/sh

PREREQ=""

prereqs()
{
	echo "$PREREQ"
}

case $1 in
# get pre-requisites
prereqs)
	prereqs
	exit 0
	;;
esac

. /usr/share/initramfs-tools/hook-functions
echo "Running zz-crypttab hook."
set -x
mkdir -p ${DESTDIR}/cryptroot || true
cat /etc/crypttab >> ${DESTDIR}/cryptroot/crypttab
chmod 644 ${DESTDIR}/cryptroot/crypttab
set +x
EOF

# Make the hook executable
chmod 755 /usr/share/initramfs-tools/hooks/zz-crypttab

# Create new initramfs and check inclusion
mkinitramfs -o /boot/initramfs.gz
lsinitramfs /boot/initramfs.gz | grep cryptsetup

# Drop /usr/share/initramfs-tools/hooks/zz-crypttab since only needed for inital stage
rm -f /usr/share/initramfs-tools/hooks/zz-crypttab

# Clean apt
apt clean

# Ready for shutdown and copy of sdcard from another device
cat << EOF
We are ready to shutdown the raspberry pi and FIXME perform stage-2
on the sd card from a linux PC.
EOF

read -p "Press enter to halt the system."

halt
