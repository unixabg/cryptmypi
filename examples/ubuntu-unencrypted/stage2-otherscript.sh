#!/bin/bash

###################################
# Ubuntu stage2-otherscript.sh


# At the time of testing the Ubuntu for RPi works on labels, so we attempt to match.
echo 'Setting up partition labels for Ubuntu.'
dosfslabel ${_BLKDEV}1 system-boot
e2label ${_BLKDEV}2 writable


# Move our kernel in place of the targets default kernel
__UBUNTU_KERNEL="initrd.img-5.19.0-1004-raspi"
echo "Moving our /boot/initramfs.gz to /boot/${__UBUNTU_KERNEL}."
mv "/boot/${__UBUNTU_KERNEL}" "/boot/${__UBUNTU_KERNEL}-oos"
cp /boot/initramfs.gz /boot/initrd.img
mv /boot/initramfs.gz "/boot/${__UBUNTU_KERNEL}"
