# cryptmypi
Project to assist users in building an encrypted raspberry pi

## Stages
**stage-1.sh** - Script to be ran from a pristine install of kali on your raspberry pi. It performs the basic setup
for encrypted boot and gets sdcard ready for **stage-2.sh**.

**stage-2.sh** - Script to be ran from a Linux OS to perform:
1. The backup of data from the unencrypted sdcard.
2. The creation of the encrypted partition on the sdcard.
3. The restore of data to the encrypted partition on the sdcard.

### Reference links
+ https://github.com/NicoHood/NicoHood.github.io/wiki/Raspberry-Pi-Encrypt-Root-Partition-Tutorial
+ https://www.kali.org/tutorials/secure-kali-pi-2018/
+ https://github.com/tothi/kali-rpi-luks-crypt/blob/master/README.md

