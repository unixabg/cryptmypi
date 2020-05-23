#!/bin/bash
set -e

# Precondition check for DNS variables
if [ -z "${_DNS1}" ]; then
    _DNS1='1.1.1.1'
        echo_warn "Primary DNS server _DNS1 is not set on config: Setting default value ${_DNS1}"
fi

if [ -z "${_DNS2}" ]; then
    _DNS2='8.8.8.8'
        echo_warn "Secondary DNS server _DNS2 is not set on config: Setting default value ${_DNS2}"
fi
