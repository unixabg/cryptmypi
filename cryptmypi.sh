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
# Displays help
display_help(){
    cat << EOF

Usage: $0 [OPTIONS] configuration_dir
Assists in the full setup of [encrypted] Raspberry Pis.

OPTIONS:

    -d, --device <device>       Block device to use on stage 2
                                (overrides _BLKDEV configuration)

    --force-stage1, --rebuild   Overrides previous builds without confirmation
    --force-stage2              Writes to block device without confirmation
    --force-both-stages         Executes stage 1 and 2 without confirmation
    --skip-stage1, --no-rebuild Skips stage 1 (if a previous build exists)

    -s, --simulate              Simulate execution flow (does not call hooks)
    --keep_build_dir            When rebuilding stage 1, use last build as base
                                (default cleans up removing old build)

    --options                   Display execution options
    -h, --help                  Display this help and exit
    -o,--output <file>          Redirects stdout and stderr to <file>

Examples:
    $0 examples/kali-unencrypted
    Executes script using examples/kali-unencrypted/cryptmypi.conf definitions

    $0 --device /dev/sdb /examples/kali-complete
    Executes script using examples/kali-complete/cryptmypi.conf
    using /dev/sdb as destination block device

    $0 -o execution.log my/config/path
    Executes script using my/config/path/cryptmypi.conf
    outputing stdout and stderr to execution.log

EOF
}


_REDIRECTING=false

# Redirects output to file if output filename given
redirect_output(){
    [ -z "${_OUTPUT_TO_FILE}" ] || {
        # Alternative 1: Redirects to file
        #exec 3>&1 4>&2 >>"${_OUTPUT_TO_FILE}" 2>&1

        # Alternative 2: Redirects copy of stdout and stderr to file
        $_REDIRECTING || {
                exec > >(sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | tee -i "${_OUTPUT_TO_FILE}")
                exec 2>&1
        }

        _REDIRECTING=true
    }
}

# Restores output to stdout and stderr
restore_output(){
    [ -z "${_OUTPUT_TO_FILE}" ] || {
        # Alternative 1: Needs deactivation for interactions
        #exec 1>&3 2>&4
        #_REDIRECTING=false
        echo
    }
}


############################
# Verifying input parameters
############################
# Default input variable value
_OUTPUT_TO_FILE=""
_STAGE1_CONFIRM=true
_STAGE2_CONFIRM=true
_BLKDEV_OVERRIDE=""
_SHOW_OPTIONS=false
_SIMULATE=false
_STAGE1_REBUILD=""
_RMBUILD_ONREBUILD=true

# Parsing input parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -h|--help)
            display_help
            exit 0
            ;;
        -s|--simulate)
            _SIMULATE=true
            shift
            ;;
        --options)
            _SHOW_OPTIONS=true
            shift
            ;;
        -o|--output)
            _OUTPUT_TO_FILE="$2"
            shift
            shift
            ;;
        --force-stage1|--rebuild)
            _STAGE1_CONFIRM=false
            _STAGE1_REBUILD=true
            shift
            ;;
        --keep_build_dir)
            _RMBUILD_ONREBUILD=false
            shift
            ;;
        --skip-stage1|--no-rebuild)
            _STAGE1_CONFIRM=false
            _STAGE1_REBUILD=false
            shift
            ;;
        --force-stage2)
            _STAGE2_CONFIRM=false
            shift
            ;;
        --force-both-stages)
            _STAGE1_CONFIRM=false
            _STAGE2_CONFIRM=false
            _STAGE1_REBUILD=true
            shift
            ;;
        -d|--device)
            _BLKDEV_OVERRIDE="$2"
            shift
            shift
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Check if configuration name was provided
if [ -z "$1" ]; then
    echo "ERROR: Configuration directory was not supplied. "
    display_help
    echo "Exiting..."
    exit 1
else
    _CONFDIRNAME=$1
fi

# Display options
$_SHOW_OPTIONS && {
cat << EOF
-- OPTIONS --------------------------------------------------------------------
   - SIMULATE               = ${_SIMULATE}
   - OUTPUT FILE            = ${_OUTPUT_TO_FILE:-"none (using stdout and stderr)"}
   - CONFIRM STAGE 1        = ${_STAGE1_CONFIRM}
   - STAGE 1 REBUILD        = ${_STAGE1_REBUILD}
   - CONFIRM STAGE 2        = ${_STAGE2_CONFIRM}
   - DEVICE OVERRIDE        = ${_BLKDEV_OVERRIDE:-"none (using _BLKDEV on cryptmypi.conf)"}
   - CONFIGURATION          = ${_CONFDIRNAME}
   - RM BUILD ON REBUILD    = ${_RMBUILD_ONREBUILD}
-------------------------------------------------------------------------------
EOF
}

# Parameter/Option Variables
############################ Output stdout and stderr to file
[ -z "${_OUTPUT_TO_FILE}" ] || {
    echo "Redirecting output (stdout and stderr) to file '${_OUTPUT_TO_FILE}' ..."
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
export _VER="4.5-next"
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
    cat << EOF
ERROR: No 'cryptmypi.conf' file found in the config folder!

    You might try copying the default ./cryptmypi.conf file to the ${_CONFDIRNAME}/ directory, then attempt to run again.
    Remember to edit the ${_CONFDIRNAME}/cryptmypi.conf with your desired settings.

Exiting ...
EOF
    exit 1
fi


# Load configuration file
. ${_CONFDIR}/cryptmypi.conf


# Overriding _BLKDEV if _BLKDEV_OVERRIDE set
[ -z "${_BLKDEV_OVERRIDE}" ] || _BLKDEV=${_BLKDEV_OVERRIDE}


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
cleanup(){
    chroot_umount || true
    umount ${_BLKDEV}* || true
    umount /mnt/cryptmypi || {
        umount -l /mnt/cryptmypi || true
        umount -f /dev/mapper/crypt || true
    }
    [ -d /mnt/cryptmypi ] && rm -r /mnt/cryptmypi || true
    cryptsetup luksClose crypt || true
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
        while true
        do
            $_STAGE1_CONFIRM && {
                echo "Rebuild? (y/N)"
                read _CONTINUE
                _CONTINUE=`echo "${_CONTINUE}" | sed -e 's/\(.*\)/\L\1/'`
            } || {
                echo "STAGE1 confirmation set to FALSE: skipping confirmation"
                $_STAGE1_REBUILD && {
                    echo "Default set as REBUILD. STAGE1 will be rebuilt ..."
                    _CONTINUE='y'
                } || {
                    echo "Default set as SKIP REBUILD. Skipping STAGE1 ..."
                    _CONTINUE='n'
                }
            }

            redirect_output
            echo ""
            case "${_CONTINUE}" in
                'y')
                    $_RMBUILD_ONREBUILD && {
                        echo "Removing current build files..."
                        $_SIMULATE || rm -Rf ${_BUILDDIR}
                    } || echo_warn "--keep_build_dir set: Not cleaning old build."
                    execute "both"
                    break;
                    ;;
                'n')
                    execute "stage2"
                    break;
                    ;;
                *)
                    echo "Invalid input."
                    ;;
            esac
        done
    fi
}
main


echo "Goodbye from cryptmypi (${_VER})."
exit 0
