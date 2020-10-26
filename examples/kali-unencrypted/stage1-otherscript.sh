#!/bin/bash

###################################
# Kali stage1-otherscript.sh

echo 'Modifying /boot/cmdline.txt for rootfstype=ext4'
sed -i.bak "s#rootfstype=ext3#rootfstype=ext4#g" /boot/cmdline.txt

