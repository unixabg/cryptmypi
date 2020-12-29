#!/bin/bash

###################################
# Ubuntu encrypted stage1-otherscript.sh


echo "Dropping .old file symlinks in /boot .."
rm -f /boot/*.old
