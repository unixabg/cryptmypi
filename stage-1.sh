#!/bin/bash

## cryptmypi
## Copyright (C) 2018-2019 Richard Nelson <unixabg@gmail.com>
##
## This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING.
## This is free software, and you are welcome to redistribute it
## under certain conditions; see COPYING for details.

#FIXME: Change default root:toor password

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

_VER="2.0-beta"

dropbearpi_check(){
	# Test for authorized_keys file
	if [ ! -f ${_BASEDIR}/authorized_keys ]; then
		echo "Dropbear authorized_keys file missing. Exiting..."
		exit 1
	fi
}

dropbearpi(){
	##########
	# Begin Dropbear
	# Put authorized keys where they go
	echo "Attempting dropbearpi..."

	chroot ${_BUILDDIR}/root apt-get -y install dropbear

	mkdir -p ${_BUILDDIR}/root/root/.ssh/
	cat ${_BASEDIR}/authorized_keys > ${_BUILDDIR}/root/etc/dropbear-initramfs/authorized_keys
	cat ${_BASEDIR}/authorized_keys > ${_BUILDDIR}/root/root/.ssh/authorized_keys
	# Update dropbear for some sleep in initramfs
	sed -i 's/run_dropbear &/sleep 5\nrun_dropbear &/g' ${_BUILDDIR}/root/usr/share/initramfs-tools/scripts/init-premount/dropbear
	# Change the port that dropbear runs on to make our lives easier
	sed -i 's/#DROPBEAR_OPTIONS=/DROPBEAR_OPTIONS="-p 2222"/g' ${_BUILDDIR}/root/etc/dropbear-initramfs/config

	echo "...dropbearpi call completed!"
}

encryptpi(){
	##########
	# Setup working area
	echo "Attempting encryptpi..."

	# Test for qemu
	if [ ! -f "/usr/bin/qemu-aarch64-static" ]; then
		echo "Can't find arm emulator. Attempting Install"
		apt-get -y install qemu-user-static binfmt-support
		if [ ! -f "/usr/bin/qemu-aarch64-static" ]; then
			echo "Still can't find arm emulator. Exiting ..."
			exit 1
		fi
	fi

	# Download arm image if we don't already have it
	_IMAGE=https://images.offensive-security.com/arm-images/kali-linux-2019.1-rpi3-nexmon-64.img.xz
	_IMAGENAME=`basename ${_IMAGE}`
	if [ -f ${_BASEDIR}/${_IMAGENAME} ]; then
		echo "Awesome, ARM image ${_IMAGENAME} already exists. Skipping Download"
	else
		echo "Downloading ARM image from $image"
		wget ${_IMAGE} -O ${_BASEDIR}/${_IMAGENAME}
	fi

	# Extract files from image
	mkdir ${_BUILDDIR}/root
	mkdir ${_BUILDDIR}/mount
	echo "Extracting image: ${_IMAGENAME}"
	xz --decompress --stdout${_BASEDIR}/${_IMAGENAME} > ${_BUILDDIR}/kali.img
	echo "Mounting loopback"
	loopdev=`losetup -f --show ${_BUILDDIR}/kali.img`
	partprobe ${loopdev}
	# Extract root partition
	mount ${loopdev}p2 ${_BUILDDIR}/mount
	echo "Syncing /root"
	rsync -HPavz -q ${_BUILDDIR}/mount/ ${_BUILDDIR}/root/
	umount ${_BUILDDIR}/mount
	# Extract boot partition
	mount ${loopdev}p1 ${_BUILDDIR}/mount/
	echo "Syncing /root/boot"
	rsync -HPavz -q ${_BUILDDIR}/mount/ ${_BUILDDIR}/root/boot/
	umount ${_BUILDDIR}/mount
	# Clear loopback
	rmdir ${_BUILDDIR}/mount
	echo "Cleaning loopback"
	losetup -d ${loopdev}
	rm ${_BUILDDIR}/kali.img

	# Setup qemu emulator for aarch64
	echo "Copying qemu emulator to chroot"
	cp /usr/bin/qemu-aarch64-static ${_BUILDDIR}/root/usr/bin/

	# Install some extra stuff
	chroot ${_BUILDDIR}/root apt-get update
	chroot ${_BUILDDIR}/root apt-get -y install cryptsetup busybox

	# Tell pi to use initramfs
	echo "initramfs initramfs.gz followkernel" >> ${_BUILDDIR}/root/boot/config.txt

	##########
	# Begin cryptsetup
	echo "The encryptpi stage completed!"
	# Update /boot/cmdline.txt to boot crypt
	sed -i 's#root=/dev/mmcblk0p2#root=/dev/mapper/crypt cryptdevice=/dev/mmcblk0p2:crypt#g' ${_BUILDDIR}/root/boot/cmdline.txt
	# Enable cryptsetup when building initramfs
	echo "CRYPTSETUP=y" >> ${_BUILDDIR}/root/etc/cryptsetup-initramfs/conf-hook
	# Update /etc/fstab
	sed -i 's#/dev/mmcblk0p2#/dev/mapper/crypt#g' ${_BUILDDIR}/root/etc/fstab
	# Update /etc/crypttab
	echo "crypt /dev/mmcblk0p2 none luks" >> ${_BUILDDIR}/root/etc/crypttab
	# Create a hook to include our crypttab in the initramfs
	cat << "EOF" > ${_BUILDDIR}/root/etc/initramfs-tools/hooks/zz-cryptsetup
#!/bin/sh
if [ "$1" = "prereqs" ]; then exit 0; fi
. /usr/share/initramfs-tools/hook-functions
mkdir -p ${DESTDIR}/cryptroot || true
cat /etc/crypttab >> ${DESTDIR}/cryptroot/crypttab
EOF
	chmod 755 ${_BUILDDIR}/root/etc/initramfs-tools/hooks/zz-cryptsetup
	# Disable autoresize
	chroot ${_BUILDDIR}/root systemctl disable rpiwiggle
	rm ${_BUILDDIR}/root/root/scripts/rpi-wiggle.sh

	echo "...encryptpi call completed!"
}

finalstuff(){
	echo "Starting finalstuff..."

	# Disable lightdm
	chroot ${_BUILDDIR}/root systemctl disable lightdm

	# Install other handy tools
	chroot ${_BUILDDIR}/root apt-get -y install telnet dsniff bettercap

	# Clean apt
	#chroot ${_BUILDDIR}/root apt-get -y purge manpages man-db
	chroot ${_BUILDDIR}/root apt-get clean

	# Finally, Create the initramfs
	chroot ${_BUILDDIR}/root mkinitramfs -o /boot/initramfs.gz -v `ls ${_BUILDDIR}/root/lib/modules/ | grep 'v8+' | head -n 1`

	echo "...finalstuff call completed!"
}

iodinepi(){
	##########
	# Begin Iodine
	echo "Attempting iodinepi..."

	chroot ${_BUILDDIR}/root apt-get -y install iodine

	# Create initramfs hook file for iodine
	cat << 'EOF2' > ${_BUILDDIR}/root/etc/initramfs-tools/hooks/zz-iodine
#!/bin/sh
if [ "$1" = "prereqs" ]; then exit 0; fi
. /usr/share/initramfs-tools/hook-functions
copy_exec "/usr/sbin/iodine"
#we need a tun device for iodine
manual_add_modules tun
#Generate Script that runs in initramfs
cat > ${DESTDIR}/start_iodine << 'EOF'
#!/bin/sh
echo "Starting Iodine"
busybox modprobe tun
counter=1
while true; do
	echo Try $counter: `date`
	#exit if we are no longer in the initramfs
	[ ! -f /start_iodine ] && exit
	#put this here in case it dies, it will restart. If it is running it will just fail
	/usr/sbin/iodine -d dns0 -r -I1 -L0 -P IODINE_PASSWORD $(grep IPV4DNS0 /run/net-eth0.conf | cut -d"'" -f 2) IODINE_DOMAIN
	[ $counter -gt 10 ] && reboot -f
	counter=$((counter+1))
	sleep 60
done;
EOF
chmod 755 ${DESTDIR}/start_iodine
exit 0
EOF2
	chmod 755 ${_BUILDDIR}/root/etc/initramfs-tools/hooks/zz-iodine
	# Replace variables in iodine hook file
	sed -i "s#IODINE_PASSWORD#${_IODINE_PASSWORD}#g" ${_BUILDDIR}/root/etc/initramfs-tools/hooks/zz-iodine
	sed -i "s#IODINE_DOMAIN#${_IODINE_DOMAIN}#g" ${_BUILDDIR}/root/etc/initramfs-tools/hooks/zz-iodine

	# Create initramfs script file for iodine
	cat << 'EOF' > ${_BUILDDIR}/root/etc/initramfs-tools/scripts/init-premount/iodine
#!/bin/sh
if [ "$1" = "prereqs" ]; then exit 0; fi
startIodine(){
    exec /start_iodine
}
startIodine &
exit 0
EOF
	chmod 755 ${_BUILDDIR}/root/etc/initramfs-tools/scripts/init-premount/iodine

	# Create iodine startup script (not initramfs)
	cat << EOF > ${_BUILDDIR}/root/opt/iodine
#!/bin/bash
while true;do
	iodine -f -r -I1 -L0 -P IODINE_PASSWORD IODINE_DOMAIN
	sleep 60
done
EOF
	chmod 755 ${_BUILDDIR}/root/opt/iodine
	sed -i "s#IODINE_PASSWORD#${_IODINE_PASSWORD}#g" ${_BUILDDIR}/root/opt/iodine
	sed -i "s#IODINE_DOMAIN#${_IODINE_DOMAIN}#g" ${_BUILDDIR}/root/opt/iodine
	cat << EOF > ${_BUILDDIR}/root/crontab_setup
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
@reboot /opt/iodine
EOF
	chroot ${_BUILDDIR}/root crontab /crontab_setup
	rm ${_BUILDDIR}/root/crontab_setup

	echo "...iodinepi call completed!"
}

show_menus() {
	clear
	echo "#################################"
	echo "         C R Y P T M Y P I"
	echo ""
	echo "        Stage-1   (${_VER})"
	echo "#################################"
	echo "1. Encrypt pi"
	echo "2. Encrypt pi + dropbear"
	echo "3. Encrypt pi + dropbear + iodine"
	echo "4. Exit"
}

# Trap CTRL+C, CTRL+Z and quit singles
trap '' SIGINT SIGQUIT SIGTSTP

# Source in config
. cryptmypi.conf

#we need this to exist before anything that follows
_BASEDIR=`pwd`
_BUILDDIR=${_BASEDIR}/cryptmypi-build
if [ -d ${_BUILDDIR} ];then
	echo "Working directory already exists: ${_BUILDDIR}"
	echo "Exiting ..."
	exit 1
fi
mkdir -p ${_BUILDDIR}
cd ${_BUILDDIR}

# Main logic - infinite loop
while true
do
	show_menus
	read -p "Enter choice [1 - 4] " _SELECTION
	case $_SELECTION in
		1)	echo "Encrypt pi selected!"
			encryptpi
			finalstuff
			break
			;;
		2)	echo "Encrypt pi + dropbear selected!"
			dropbearpi_check
			encryptpi
			dropbearpi
			finalstuff
			break
			;;
		3)	echo "Encrypt pi + dropbear + iodine selected!"
			dropbearpi_check
			encryptpi
			dropbearpi
			iodinepi
			finalstuff
			break
			;;
		4)	break
			;;
		*)	echo -e "Invalid selection error..." && sleep 2
	esac
done

echo "Goodbye from cryptmypi stage-1 (${_VER})."
exit 0
