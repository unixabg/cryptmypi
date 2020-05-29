#!/bin/bash
set -e


# Compose package actions
echo_debug "Starting compose package actions ..."
chroot_pkgpurge "${_PKGSPURGE}"
chroot_pkginstall "${_PKGSINSTALL}"
