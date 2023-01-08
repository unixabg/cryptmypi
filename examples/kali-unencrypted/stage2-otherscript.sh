#!/bin/bash

###################################
# Kali encrypted stage2-otherscript.sh


echo 'Disable autoresize'
systemctl disable rpi-resizerootfs.service
systemctl disable rpiwiggle.service


echo 'Adjusting rootfstype=ext4 in /boot/cmdline.txt'
sed -i.bak "s#rootfstype=ext3#rootfstype=ext4#g" /boot/cmdline.txt


echo 'Adjusting PARTUUID in /boot/cmdline.txt'
__OLDPARTUUID=$(awk '{print $3}' /boot/cmdline.txt | awk -F= '{print $3}')
echo Old PARTUUID is "$__OLDPARTUUID"
__NEWPARTUUID=$(blkid | grep "${_BLKDEV}"2 | awk '{print $5}' | awk -F\" '{print $2}')
echo New PARTUUID is "$__NEWPARTUUID"
sed -i.bak "s/$__OLDPARTUUID/$__NEWPARTUUID/" /boot/cmdline.txt


echo 'Adjusting UUID in /etc/fstab'
__OLDUUID=$(grep UUID /etc/fstab | awk '{print $1}' | awk -F= '{print $2}')
echo Old UUID is "$__OLDUUID"
__NEWUUID=$(blkid | grep "${_BLKDEV}"2 | awk '{print $2}' | awk -F\" '{print $2}')
echo New UUID is "$__NEWUUID"
sed -i.bak "s/$__OLDUUID/$__NEWUUID/" /etc/fstab


echo "Set a label for system check on ${_BLKDEV}1 "
dosfslabel "${_BLKDEV}"1 BOOT


