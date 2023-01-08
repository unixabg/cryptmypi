#!/bin/bash

###################################
# Raspbian Pi OS stage1-otherscript.sh


echo 'Modifying /boot/cmdline.txt.'
sed -i.bak -e "s#quiet init=/usr/lib/raspberrypi-sys-mods/firstboot##g" -e "s#PARTUUID=.*-0#/dev/mmcblk0p#g" /boot/cmdline.txt

#echo 'Appending initramfs information to /boot/cmdline.txt.'
#echo 'initramfs initramfs.gz followkernel' >>  /boot/config.txt


echo 'Updating partition information in /etc/fstab'
sed -i.bak "s#PARTUUID=.*-0#/dev/mmcblk0p#g" /etc/fstab


echo 'Enabling ssh on boot'
touch /boot/ssh


# Disable user creation prompt
systemctl disable userconfig > /dev/null 2>&1
