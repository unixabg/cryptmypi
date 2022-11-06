#!/bin/bash

###################################
# Raspbian Pi OS encrypted stage1-otherscript.sh


echo 'Modifying /boot/cmdline.txt for encrypted boot.'
sed -i.bak -e "s#quiet init=/usr/lib/raspberrypi-sys-mods/firstboot##g" -e "s#root=PARTUUID=.*-02#root=/dev/mapper/crypt#g" /boot/cmdline.txt

echo 'Updating partition information in /etc/fstab for enctyped boot.'
sed -i.bak "s#PARTUUID=.*-0#/dev/mmcblk0p#g" /etc/fstab
sed -i 's#/dev/mmcblk0p2#/dev/mapper/crypt#g' /etc/fstab


echo 'Delete PiOS userconfig on first boot.'
rm -f /usr/lib/systemd/system/userconfig.service


echo 'Enabling ssh on boot'
touch /boot/ssh


# Disable user creation prompt
systemctl disable userconfig > /dev/null 2&>1
