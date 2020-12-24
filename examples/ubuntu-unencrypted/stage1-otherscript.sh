#!/bin/bash

###################################
# Ubuntu stage1-otherscript.sh


echo "Dropping .old file symlinks in /boot .."
rm -f /boot/*.old
