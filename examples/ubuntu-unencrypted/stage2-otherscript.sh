#!/bin/bash

###################################
# Ubuntu stage2-otherscript.sh


# At the time of testing the Ubuntu for rpi works on labels, so we attempt to match.
echo 'Setting up partition labels for Ubuntu.'
dosfslabel /dev/sdb1 system-boot
e2label /dev/sdb2 writable


echo "Movinng our /boot/initramfs.gz to /boot/initrd.img"
mv /boot/initrd.img /boot/initrd.img-oos
mv /boot/initramfs.gz /boot/initrd.img


echo "Updating our /boot/initrd.img to /boot/initrd.img-5.8.0-1006-raspi"
mv /boot/initrd.img-5.8.0-1006-raspi /boot/initrd.img-5.8.0-1006-raspi-oos
cp /boot/initramfs.gz /boot/initrd.img-5.8.0-1006-raspi
