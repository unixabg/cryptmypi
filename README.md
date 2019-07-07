# cryptmypi 3.x
Project to assist users in building an encrypted raspberry pi and more.

## Generic steps to prep a sdcard for an encrypted raspberry pi setup.
 * Clone repository
 * Change directory to cloned respository
 * Copy cryptmypi.conf to config folder
 * Adjust settings in config/cryptmypi.conf to your needs
 * Run ./stage-1.sh to build encrypted image
 * Insert sdcard and **P L E A S E** ensure the block device matches your sdcard for stage-2.sh
 * Run ./stage-2.sh

### Note: Scripts stage-1.sh and stage-2.sh only tested on kali-rolling host.

### Reference links and other
+ https://github.com/NicoHood/NicoHood.github.io/wiki/Raspberry-Pi-Encrypt-Root-Partition-Tutorial
+ https://www.kali.org/tutorials/secure-kali-pi-2018/
+ https://github.com/tothi/kali-rpi-luks-crypt/blob/master/README.md
+ https://gitlab.com/kalilinux/build-scripts/kali-arm

