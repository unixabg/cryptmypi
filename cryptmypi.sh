#!/bin/bash
set -e


cat << EOF

###############################################################################
                               C R Y P T M Y P I
###############################################################################

EOF


############################
# Parameter helper functions
############################
# Redirects output to file if output filename given
redirect_output(){
    [ -z "${_OUTPUT_TO_FILE}" ] || {
        exec 3>&1 4>&2 >>"${_OUTPUT_TO_FILE}" 2>&1
    }
}

# Restores output to stdin and stdout
restore_output(){
    [ -z "${_OUTPUT_TO_FILE}" ] || exec 1>&3 2>&4
}



############################
# Verifying input parameters
############################
# Check if configuration name was provided
if [ -z "$1" ]; then
    echo "No argument supplied. Desired configuration folder should be supplied."
fi
_OUTPUT_TO_FILE=""
_STAGE1_CONFIRM=false
_STAGE2_CONFIRM=false


# Parameter/Option Variables
############################ Output stdin and stdout to file
[ -z "${_OUTPUT_TO_FILE}" ] || {
    echo "Redirecting output (stdin and stdout) to file '${_OUTPUT_TO_FILE}' ..."
    echo
    redirect_output
    echo "\$ $0 ${@} " > "${_OUTPUT_TO_FILE}"
    echo
}


# Determining script directory (absolute path resolving symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
_SCRIPT_DIRECTORY="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"


# Variables
export _USER_HOME=$(eval echo ~${SUDO_USER})
export _CONFDIRNAME=$1
export _VER="4.0-beta"
export _BASEDIR="${_SCRIPT_DIRECTORY}"
export _CURRDIR=$(pwd)
export _CONFDIR=${_CURRDIR}/${_CONFDIRNAME}
export _BUILDDIR=${_CONFDIR}/build
export _FILESDIR=${_BASEDIR}/files
export _IMAGEDIR=${_FILESDIR}/images
export _CACHEDIR=${_FILESDIR}/cache


# Creating Directories
mkdir -p "${_IMAGEDIR}"
mkdir -p "${_FILESDIR}"


# Check if configuration file is present
if [ ! -f ${_CONFDIR}/cryptmypi.conf ]; then
    echo "No cryptmypi.conf file found in the config folder!"
    echo "Exiting ..."
    echo "You might try copying the default ./cryptmypi.conf file to the ${_CONFDIRNAME}/ directory, then attempt to run again."
    echo "Remember to edit the ${_CONFDIRNAME}/cryptmypi.conf with your desired settings."
    exit 1
fi


# Load configuration file
. ${_CONFDIR}/cryptmypi.conf


# Configuration dependent variables
export _IMAGENAME=$(basename ${_IMAGEURL})


############################
# Load Script Base Functions
############################
echo "Loading functions..."
for _FN in ${_BASEDIR}/functions/*.fns
do
    if [ -e ${_FN} ]; then
        echo "- Loading $(basename ${_FN}) ..."
        source ${_FN}
        echo "  ... $(basename ${_FN}) loaded!"
    fi
done


############################
# Validate All Preconditions
############################
myhooks preconditions


############################
# STAGE 1 Image Preparation
############################
stage1(){
    cat << EOF
###############################################################################
                               C R Y P T M Y P I
                               ---- Stage 1 ----
v${_VER}
###############################################################################
EOF
    function_exists "stage1_hooks" && {
        echo ""
        echo "--- Custom STAGE1 SELECTED"
        function_summary stage1_hooks
        echo ""
        echo "--- Executing:"
        stage1_hooks
        echo ""
    } || {
        restore_output
        while true
        do
            cat << EOF

    1. Basic          (No encryption)
    2. Encryption     (No remote unlock)
    3. Complete       (Encryption + Dropbear)
    4. Exit

EOF

            read -p "Enter choice [1 - 4] " _SELECTION
            redirect_output
            echo
            case $_SELECTION in
                1)  echo "--- Basic SELECTED: No encryption"
                    stage1profile_noencryption
                    break
                    ;;
                2)  echo "--- Encryption SELECTED"
                    stage1profile_encryption
                    break
                    ;;
                3)  echo "--- Complete SELECTED"
                    stage1profile_complete
                    break
                    ;;
                4)  break
                    ;;
                *)    echo -e "Invalid selection error ..." && sleep 2
            esac
        done


    }
}


############################
# STAGE 2 Encrypt & Write SD
############################
stage2(){
    # Simple check for type of sdcard block device
    if echo ${_BLKDEV} | grep -qs "mmcblk"
    then
        __PARTITIONPREFIX=p
    else
        __PARTITIONPREFIX=""
    fi

    # Show Stage2 menu
    cat << EOF

###############################################################################
                               C R Y P T M Y P I
                               ---- Stage 2 ----
v${_VER}
###############################################################################
EOF

    restore_output
    cat << EOF

Cryptmypi will attempt to perform the following operations on the sdcard:
    1. Partition and format the sdcard.
    2. Create bootable sdcard with LUKS encrypted root partition.

EOF

    local _CONTINUE
    $_STAGE2_CONFIRM && {
        read -p "Press enter to continue."

        cat << EOF

##################### W A R N I N G #####################
This process can damage your local install if the script
has the wrong block device for your system.

******************** P l e a s e ************************
Double check and know you have the correct block device
that matches your sdcard.

##################### W A R N I N G #####################
  ** ** ** There is no undoing these actions! ** ** **
  ** ** **  If you are unsure DO NOT proceed. ** ** **

-------------------Sanity Check Prompt ------------------
This is a listing of your system block devices:

$(lsblk)

And below is the block device to be used with the script:

block device:  ${_BLKDEV}

If the block device is wrong DO NOT continue. Adjust the
block device in the cryptmypi.conf file located in the
config directory.

To continue type in the phrase 'Yes, do as I say!'
EOF

        echo -n ": "
        read _CONTINUE
    } || {
        echo "STAGE2 confirmation set to FALSE: skipping confirmation"
        echo "STAGE2 will execute (assuming 'Yes, do as I say!' input) ..."
        _CONTINUE='Yes, do as I say!'
    }

    redirect_output
    case "${_CONTINUE}" in
        'Yes, do as I say!')
            function_exists "stage2_hooks" && {
                echo ""
                echo "--- Custom STAGE2 SELECTED"
                function_summary stage2_hooks
                echo ""
                echo "--- Executing:"
                stage2_hooks
                echo ""
            } || myhooks "stage2"
            ;;
        *)
            restore_output
            echo "Abort."
            exit 1
            ;;
    esac
}


############################
# EXECUTION LOGIC FLOW
############################
# Logic execution routine
execute(){
    mkdir -p ${_BUILDDIR}
    cd ${_BUILDDIR}
    case "$1" in
        'both')
            echo "# Executing both stages #######################################################"
            stage1
            stage2
            ;;
        'stage2')
            echo "# Executing stage2 only #######################################################"
            stage2
            ;;
        *)
            ;;
    esac
}


# Cleanup EXIT Trap
cleanup() {
    chroot_umount || true
    umount ${_BLKDEV}* || true
    umount /mnt/cryptmypi || {
        umount -l /mnt/cryptmypi || true
        umount -f /dev/mapper/cryptmypi_root || true
    }
    [ -d /mnt/cryptmypi ] && rm -r /mnt/cryptmypi || true
    cryptsetup luksClose cryptmypi_root || true
}
trap cleanup EXIT


# Main logic routine
main(){
    if [ ! -d ${_BUILDDIR} ]; then
        execute "both"
    else
        restore_output
        echo "Build directory already exists: ${_BUILDDIR}"

        local _CONTINUE
        $_STAGE1_CONFIRM && {
            echo "Rebuild? (y/N)"
            read _CONTINUE
            _CONTINUE=`echo "${_CONTINUE}" | sed -e 's/\(.*\)/\L\1/'`
        } || {
            echo "STAGE1 confirmation set to FALSE: skipping confirmation"
            echo "STAGE1 will be rebuilt ..."
            _CONTINUE='y'
        }

        redirect_output
        echo ""
        case "${_CONTINUE}" in
            'y')
                echo "Removing current build files..."
                rm -Rf ${_BUILDDIR}
                execute "both"
                ;;
            *)
                execute "stage2"
                ;;
        esac
    fi
}
main


echo "Goodbye from cryptmypi (${_VER})."
exit 0
