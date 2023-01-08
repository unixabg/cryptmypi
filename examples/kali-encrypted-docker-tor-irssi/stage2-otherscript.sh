#!/bin/bash

###################################
# Kali encrypted stage2-otherscript.sh
echo 'Disable autoresize'
systemctl disable rpi-resizerootfs.service
systemctl disable rpiwiggle.service

echo 'Adjusting root= in /boot/cmdline.txt'
__OLDROOT=$(awk '{print $3}' /boot/cmdline.txt)
echo Old crypt ROOT is "$__OLDROOT"
__NEWROOT="root=/dev/mapper/crypt"
echo New crypt ROOT is $__NEWROOT
sed -i.bak "s#$__OLDROOT#$__NEWROOT#" /boot/cmdline.txt


echo 'Replacing UUID to encrypted path in /etc/fstab'
__OLDUUID=$(grep UUID /etc/fstab | awk '{print $1}')
echo Old fstab UUID is "$__OLDUUID"
__NEWPATH="/dev/mapper/crypt"
echo New crypt path in fstab is $__NEWPATH
sed -i.bak "s#$__OLDUUID#$__NEWPATH#" /etc/fstab


echo "Set a label for system check on ${_BLKDEV}1 "
dosfslabel "${_BLKDEV}"1 BOOT

