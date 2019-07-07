#!/bin/bash

## cryptmypi
## Copyright (C) 2018-2019 Richard Nelson <unixabg@gmail.com>
##
## This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING.
## This is free software, and you are welcome to redistribute it
## under certain conditions; see COPYING for details.

############################
# Functions
############################
finalstuff(){
	echo "Starting finalstuff ..."

	# Call for hook finalstuff
	myhooks finalstuff

	# Finally, Create the initramfs
	chroot ${_BUILDDIR}/root mkinitramfs -o /boot/initramfs.gz -v $(ls ${_BUILDDIR}/root/lib/modules/ | grep 'v8+' | head -n 1)

	echo "... finalstuff call completed!"
}

iodinepi(){
	##########
	# Begin Iodine
	echo "Attempting iodinepi ..."

	# Call for hook iodinepi
	myhooks iodinepi

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
	echo Try $counter: $(date)
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

	echo "... iodinepi call completed!"
}

myhooks(){
	##########
	# Hook operations
	#
	## Operational hooks:
	## .hook - file to manipulate build operations
	##
	### encryptpi.hook  - early chroot and other calls before any other chroot calls as soon chroot ready in encryptpi
	### dropbearpi.hook - early chroot and other calls in dropbearpi
	### finalstuff.hook - early chroot and other calls in finalstuff
	### iodinepi.hook   - early chroot and other calls in iodinepi
	###
	if [ ! -z "${1}" ]; then
		_HOOKOP="${1}"
		echo "Attempting to run ${_HOOKOP} hooks ..."
		for _HOOK in ${_BASEDIR}/hooks/????-${_HOOKOP}-*.hook
		do
			if [ -e ${_HOOK} ]; then
				echo "Calling $(basename ${_HOOK}) ..."
				${_HOOK}
			fi
		done
	else
		echo "Hook operations not specified! Stopping here."
		exit 1
	fi
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

############################
# Dependencies
############################
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

if [ ! -e /usr/bin/rsync ]; then
	echo "No /usr/bin/rsync file found!"
	echo "Exiting ..."
	echo "On Debian based systems, rsync can be installed with:"
	echo "  apt install rsync"
	exit 1
fi


# Source in config
if [ ! -f config/cryptmypi.conf ]; then
	echo "No cryptmypi.conf file found in the config folder!"
	echo "Exiting ..."
	echo "You might try copying the default ./cryptmypi.conf file to the config/ directory, then attempt to run again."
	echo "Remember to edit the config/cryptmypi.conf with your desired settings."
	exit 1
fi
. config/cryptmypi.conf

# Setup build structure before anything that follows
if [ -d ${_BUILDDIR} ]; then
	echo "Working directory already exists: ${_BUILDDIR}"
	echo "Exiting ..."
	exit 1
fi
mkdir -p ${_BUILDDIR}
cd ${_BUILDDIR}

############################
# Main logic - infinite loop
############################
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
		*)	echo -e "Invalid selection error ..." && sleep 2
	esac
done

echo "Goodbye from cryptmypi stage-1 (${_VER})."
exit 0
