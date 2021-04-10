#!/bin/bash

###################################
# Debian encrypted stage2-otherscript.sh


# At the time of testing the Debian OS for rpi works on labels, so we attempt to match.
echo 'Setting up partition labels for Debian OS.'
dosfslabel /dev/sdb1 RASPIFIRM


# https://cryptsetup-team.pages.debian.net/cryptsetup/README.initramfs.html#cryptopts-boot-argument
echo 'Setting up /boot/cmdline.txt for encrypted boot with Debian.'
sed -i.bak "s#root=LABEL=RASPIROOT#root=/dev/mapper/crypt rootfstype=ext4#g" /boot/cmdline.txt


#echo 'Drop the initramfs entry we made in /boot/config.txt'
sed -i.bak "s#initramfs initramfs.gz followkernel##g" /boot/config.txt


## Move our kernel in place of the targets default kernel
__DEBIAN_KERNEL="initrd.img-5.10.0-5-arm64"
echo "Movinng our /boot/initramfs.gz to /boot/${__DEBIAN_KERNEL}."
mv "/boot/${__DEBIAN_KERNEL}" "/boot/${__DEBIAN_KERNEL}-oos"
mv /boot/initramfs.gz "/boot/${__DEBIAN_KERNEL}"
