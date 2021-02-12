#!/bin/bash

###################################
# Debian encrypted stage1-otherscript.sh


echo 'Updating partition information in /etc/crypttab for enctyped boot.'
sed -i 's#/dev/mmcblk0p2#/dev/mmcblk1p2#g' /etc/crypttab


echo 'Updating partition information in /etc/crypttab for enctyped boot.'
sed -i 's#/dev/mmcblk0p2#/dev/mmcblk1p2#g' /etc/initramfs-tools/hooks/zz-cryptsetup


echo 'Updating partition information in /etc/fstab for enctyped boot.'
sed -i 's#LABEL=RASPIROOT#/dev/mapper/crypt#g' /etc/fstab
