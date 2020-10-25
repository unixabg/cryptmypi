#!/bin/bash

###################################
# Raspbian Pi OS stage1-otherscript.sh


echo 'Modifying /boot/cmdline.txt.'
sed -i.bak "s#quiet init=/usr/lib/raspi-config/init_resize.sh##g" /boot/cmdline.txt
sed -i.bak "s#PARTUUID=.*-0#/dev/mmcblk0p#g" /boot/cmdline.txt


#echo 'Appending initramfs information to /boot/cmdline.txt.'
#echo 'initramfs initramfs.gz followkernel' >>  /boot/config.txt


echo 'Updating partition information in /etc/fstab'
sed -i.bak "s#PARTUUID=.*-0#/dev/mmcblk0p#g" /etc/fstab


echo 'Enabling ssh on boot'
touch /boot/ssh
