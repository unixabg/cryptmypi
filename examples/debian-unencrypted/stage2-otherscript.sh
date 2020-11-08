#!/bin/bash

###################################
# Debian OS stage2-otherscript.sh


# At the time of testing the Debian OS for rpi works on labels, so we attempt to match.
echo 'Setting up partition labels for Debian OS.'
dosfslabel /dev/sdb1 RASPIFIRM
e2label /dev/sdb2 RASPIROOT

