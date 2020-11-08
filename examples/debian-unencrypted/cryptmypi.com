###############################################################################
## cryptmypi profile ##########################################################


# EXAMPLE OF A SIMPLE UNENCRYPTED Debian OS CONFIGURATION for rpi
#   Will create a no-encrypted Debian system, acessible locally through ssh
#   An optinal hook on stage2 will configure the system root user password


# General settings ------------------------------------------------------------
# You need to choose a kernel compatible with your RPi version.
#   - Re4son+ is for armv6 devices (ie. RPi1, RPi0, and RPi0w)
#   - v7+ and v8+ sufixes are for the 32bit and 64bit armv7 devices (ie. RPi 3)
#   - l+ sufix in the name means they will be ready for the RPi4.
export _KERNEL_VERSION_FILTER="v7+"

# HOSTNAME
#   Each element of the hostname must be from 1 to 63 characters long and
#   the entire hostname, including the dots, can be at most 253
#   characters long.  Valid characters for hostnames are ASCII(7) letters
#   from a to z, the digits from 0 to 9, and the hyphen (-)
export _HOSTNAME="debian-unencrypted"

# BLOCK DEVICE
#   The SD card or USD SD card reader block device
#   - USB drives will show up as the normal /dev/sdb, /dev/sdc, etc.
#   - MMC/SDcards may show up the same way if the card reader is USB-connected.
#   - Internal card readers normally show up as /dev/mmcblk0, /dev/mmcblk1, ...
#   You can use the lsblk command to get an easy quick view of all block
#   devices on your system at a given moment.
export _BLKDEV="/dev/sdb"


# LINUX IMAGE FILE ------------------------------------------------------------
export _IMAGEURL=https://raspi.debian.net/verified/20200909_raspi_4.img.xz
export _IMAGESHA="d8588b8428687b2556b476d9afed8d11a5a2c0eaacdfc1ad814f8de4bd4394fc"

# MINIMAL SSH CONFIG ----------------------------------------------------------
#   Keyfile to be used to access the system remotelly through ssh.
#   Its public key will be added to the system's root .ssh/autorized_keys
export _SSH_LOCAL_KEYFILE="$_USER_HOME/.ssh/id_rsa"


###############################################################################
## Stage 1 Settings ###########################################################

# Custom Stage1 Profile
#   Check functions/stage1profiles.fns for reference. You may instruct hooks
#   here or you may call one predefined stage1profile functions.
#   Optional function:
#   - if stage1_hooks is not defined, you will be prompted
#   - declare it if you want to skip script prompt predefining it
stage1_hooks(){
    stage1profile_noencryption
}

###############################################################################
## Stage-2 Settings ###########################################################

# Optional stage 2 hooks
#   If declared, this function is called during stage2 build by the
#   stage2-runoptional hook.
#
#   Optional function: can be ommited.
stage2_optional_hooks(){
    myhooks "optional-sys-rootpassword"
}


###############################################################################
##Optional Hook Settings #####################################################


# ROOT PASSWORD CHANGER settings ----------------------------------------------
# Hooks
#   optional-sys-rootpassword
#       Changes the system root password

## The new root password
export _ROOTPASSWD="root_password"
