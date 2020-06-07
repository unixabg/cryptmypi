#! /bin/bash

###################################
# Raspbian Pi OS setup.sh


echo 'Modifying /boot/cmdline.txt.'
sed -i.bak "s#quiet init=/usr/lib/raspi-config/init_resize.sh##g" /boot/cmdline.txt
sed -i.bak "s#PARTUUID=2fed7fee-02#/dev/mmcblk0p2#g" /boot/cmdline.txt


echo 'Appendgin initramfs information to /boot/cmdline.txt.'
echo 'initramfs initramfs.gz followkernel' >>  /boot/config.txt


echo 'Updating partition information in /etc/fstab'
sed -i.bak "s#PARTUUID=2fed7fee-0#/dev/mmcblk0p#g" /etc/fstab


echo 'Enabling ssh on boot'
touch /boot/ssh
