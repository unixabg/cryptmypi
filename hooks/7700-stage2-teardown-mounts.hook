#!/bin/bash
set -e


# Unmount boot partition
echo_debug "Attempting to unmount ${_BLKDEV}${__PARTITIONPREFIX}1 ..."
if umount ${_BLKDEV}${__PARTITIONPREFIX}1
then
    echo_debug "- Unmounted ${_BLKDEV}${__PARTITIONPREFIX}1"
else
    echo_error "- Aborting since we failed to unmount ${_BLKDEV}${__PARTITIONPREFIX}1"
    exit 1
fi
echo

# Unmount root partition
echo_debug "Attempting to unmount /mnt/cryptmypi ..."
if umount /mnt/cryptmypi
then
    echo_debug "- Unmounted /mnt/cryptmypi"
else
    echo_error "- Aborting since we failed to unmount /mnt/cryptmypi"
    exit 1
fi
echo
