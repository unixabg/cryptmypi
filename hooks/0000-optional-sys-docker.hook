#!/bin/bash
set -e


# REFERENCES
#   https://www.docker.com/blog/happy-pi-day-docker-raspberry-pi/
#   https://github.com/docker/docker.github.io/blob/595616145a53d68fb5be1d603e97666cefcb5293/install/linux/docker-ce/debian.md
#   https://docs.docker.com/engine/install/debian/
#   https://gist.github.com/decidedlygray/1288c0265457e5f2426d4c3b768dfcef


echo_debug "Attempting to install docker ..."
echo_warn "### Docker service may experience conflicts VPN services/connections ###"


echo_debug "    Updating /boot/cmdline.txt to enable cgroup ..."
# Needed to avoid "cgroups: memory cgroup not supported on this system"
#   see https://github.com/moby/moby/issues/35587
#       cgroup_enable works on kernel 4.9 upwards
#       cgroup_memory will be dropped in 4.14, but works on < 4.9
#       keeping both for now
sed -i "s#rootwait#cgroup_enable=memory cgroup_memory=1 rootwait#g" ${CHROOTDIR}/boot/cmdline.txt


echo_debug "    Updating iptables ... (issue: default kali iptables was stalling)"
# systemctl start and stop commands would hang/stall due to pristine iptables on kali-linux-2020.1a-rpi3-nexmon-64.img.xz
chroot_pkginstall iptables
chroot_execute update-alternatives --set iptables /usr/sbin/iptables-legacy
chroot_execute update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy


echo_debug "    Installing docker ..."
chroot_pkginstall docker.io


### ALTERNATIVE INSTALLATION PROCESS
#   # May assure an up-to-date docker, but more prone to breaking the system.
#   # Adding another distro's packages should be avoided.
#   # A variable to detect arch may be needed (or a variable stablishing RPi version).
#
# chroot_pkgpurge docker docker-engine docker.io containerd runc
# chroot_pkginstall apt-transport-https ca-certificates curl gnupg-agent software-properties-common
# curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
#
# # For Raspberry Pi 32-bit — use the following command instead:
# # echo 'deb [arch=armhf] https://download.docker.com/linux/debian buster stable' | sudo tee /etc/apt/sources.list.d/docker.list
#
# # For Raspberry Pi 64-bit — use the following command instead:
# echo 'deb [arch=arm64] https://download.docker.com/linux/debian buster stable' | sudo tee /etc/apt/sources.list.d/docker.list
#
# chroot_execute apt-get update
# chroot_pkginstall --no-install-recommends docker-ce


echo_debug "    Enabling service ..."
chroot_execute systemctl enable docker
# chroot_execute systemctl start docker


echo_debug "... docker hook call completed!"
