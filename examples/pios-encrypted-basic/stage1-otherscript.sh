#! /bin/bash

###################################
# Raspbian Pi OS stage1-otherscript.sh


echo 'Modifying /boot/cmdline.txt for encrypted boot.'
sed -i.bak "s#quiet init=/usr/lib/raspi-config/init_resize.sh##g" /boot/cmdline.txt
sed -i.bak "s#root=PARTUUID=2fed7fee-02#root=/dev/mapper/crypt cryptdevice=/dev/mmcblk0p2:crypt#g" /boot/cmdline.txt

echo 'Appendgin initramfs information to /boot/cmdline.txt.'
echo 'initramfs initramfs.gz followkernel' >>  /boot/config.txt


echo 'Updating partition information in /etc/fstab for enctyped boot.'
sed -i.bak "s#PARTUUID=2fed7fee-0#/dev/mmcblk0p#g" /etc/fstab
sed -i 's#/dev/mmcblk0p2#/dev/mapper/crypt#g' /etc/fstab

echo 'Enabling ssh on boot'
touch /boot/ssh
