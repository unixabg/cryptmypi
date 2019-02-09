# cryptmypi
Project to assist users in building an encrypted raspberry pi

## Stages
**stage-1.sh** - Script to be ran from a pristine install of kali on your raspberry pi. It performs the basic setup
for encrypted boot and gets sdcard ready for **stage-2.sh**.

**stage-2.sh**
 * Stage-2 was designed to be ran from Linux.
 * Stage-2 requires a stage-1 prepared Kali Linux sdcard.
 * Stage-2 attempts to perform the following operations
   on the sdcard:
     1. Backup the root files.
     2. Drop the root files partition.
     3. Create a LUKS encrypted partition.
     4. Format the LUKS encrypted partition to be ext4.
     5. Restore the root files to the the LUKS enctyped partition.

 * **W A R N I N G** This process will damage your local install if the script has
the wrong partition and block device for your system. **P l e a s e** check that the partition and block device match for your sdcard.

**stage-3.sh**
 * Stage-3 was designed to be ran with Kali Linux on a raspberry pi.
 * Stage-3 requires a stage-1 and stage-2 prepared Kali Linux sdcard.
 * Stage-3 attempts to perform the following operations
   on the sdcard:
    1. Install dropbear.
    2. Configure dropbear for remote unlocking with custom key you provide.

 * To undo these changes you will have to reimage the sdcard.

### Reference links
+ https://github.com/NicoHood/NicoHood.github.io/wiki/Raspberry-Pi-Encrypt-Root-Partition-Tutorial
+ https://www.kali.org/tutorials/secure-kali-pi-2018/
+ https://github.com/tothi/kali-rpi-luks-crypt/blob/master/README.md

