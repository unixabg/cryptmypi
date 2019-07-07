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
		for _HOOK in ${_BASEDIR}/hooks/????-${_HOOKOP}*.hook
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
			myhooks encryptpi
			myhooks finalstuff
			break
			;;
		2)	echo "Encrypt pi + dropbear selected!"
			myhooks sanity-dropbear
			myhooks encryptpi
			myhooks dropbearpi
			myhooks finalstuff
			break
			;;
		3)	echo "Encrypt pi + dropbear + iodine selected!"
			myhooks sanity-dropbear
			myhooks encryptpi
			myhooks dropbearpi
			myhooks iodinepi
			myhooks finalstuff
			break
			;;
		4)	break
			;;
		*)	echo -e "Invalid selection error ..." && sleep 2
	esac
done

echo "Goodbye from cryptmypi stage-1 (${_VER})."
exit 0
