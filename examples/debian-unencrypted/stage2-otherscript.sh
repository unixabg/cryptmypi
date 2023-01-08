#!/bin/bash

###################################
# Debian stage2-otherscript.sh


# At the time of testing the Debian for RPi works on labels, so we attempt to match.
echo 'Setting up partition labels for Debian.'
dosfslabel ${_BLKDEV}1 RASPIFIRM
e2label ${_BLKDEV}2 RASPIROOT


# Move our kernel in place of the targets default kernel
__DEBIAN_KERNEL="initrd.img-5.18.0-3-arm64"
echo "Moving our /boot/initramfs.gz to /boot/${__DEBIAN_KERNEL}."
mv "/boot/${__DEBIAN_KERNEL}" "/boot/${__DEBIAN_KERNEL}-oos"
mv /boot/initramfs.gz "/boot/${__DEBIAN_KERNEL}"
