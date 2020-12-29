#!/bin/bash

###################################
# Ubuntu encrypted stage2-otherscript.sh


# At the time of testing the Ubuntu for rpi works on labels, so we attempt to match.
echo 'Setting up partition labels for Ubuntu.'
dosfslabel /dev/sdb1 system-boot


# https://cryptsetup-team.pages.debian.net/cryptsetup/README.initramfs.html#cryptopts-boot-argument
echo 'Setting up /boot/cmdline.txt for encrypted boot with Ubuntu.'
sed -i.bak "s#root=LABEL=writable#root=/dev/mapper/crypt cryptopts=target=crypt,source=/dev/mmcblk0p2#g" /boot/cmdline.txt


echo 'Drop the initramfs entry we made in /boot/config.txt'
sed -i.bak "s#initramfs initramfs.gz followkernel##g" /boot/config.txt


echo 'Updating partition information in /etc/fstab for enctyped boot.'
sed -i 's#LABEL=writable#/dev/mapper/crypt#g' /etc/fstab


# Move our kernel in place of the targets default kernel
__UBUNTU_KERNEL="initrd.img-5.8.0-1006-raspi"
echo "Movinng our /boot/initramfs.gz to /boot/${__UBUNTU_KERNEL}."
mv "/boot/${__UBUNTU_KERNEL}" "/boot/${__UBUNTU_KERNEL}-oos"
cp /boot/initramfs.gz /boot/initrd.img
mv /boot/initramfs.gz "/boot/${__UBUNTU_KERNEL}"
