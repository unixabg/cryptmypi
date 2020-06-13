#!/bin/bash
set -e


echo_debug "Attempting to set the hostname up ..."


if [ -z "${_HOSTNAME}" ]; then
    _HOSTNAME="cryptmypi"
fi


# Overwrites /etc/hostname
echo "${_HOSTNAME}" > "${CHROOTDIR}/etc/hostname"


# Updates /etc/hosts
sed -i "s#^127.0.1.1\s*.*\$#127.0.1.1       ${_HOSTNAME}#" "${CHROOTDIR}/etc/hosts"


echo_debug "   ... hostname was set up!"
