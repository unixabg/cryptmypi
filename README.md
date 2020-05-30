# cryptmypi 4.x

Assists in the full setup of [encrypted] Raspberry Pis. Able to maintain multiple setup configurations, for multiple usages, ofers a multitude of modular configurations hooks providing out-of-the-box optinal features for initramfs (while the system in encrypted) and the actual system (after boot).

**Note:** Only tested on:
- Kali host
- Kali guest/target
- RaspberryPi 2 and 3 64 bit image.

## How it works

A configuration profile defines 2 stages:

1. A base OS image is extracted.
2. The build is written to an SD card.

Optional configuration hooks can be set in any of the stages:
- Configurations applyed on stage 1 will be avaiable to the stage 2. Each time the script runs it will check if a stage 1 build is already present, and will ask if it should be used or if it should be rebuilt.
- Stage 2 can be executed as many times as wanted without affecting stage's 1 build. Every configuration applyed in stage 2 will be applyed directly to the SD card.

## Capabilities

1. **FULL DISK ENCRYPTION**: Although the project can be used to setup an unencrypted RPi box, it is currently capable to setup a fully encrypted kali linux.

- unlockable remotely through dropbear's ssh;
- served through ethernet or wifi;
- exposed to the internet using reverse forwarding: sshhub.de as a jumphost;
- bypass firewalls using IODINE;
- and a nuke password can be set;

2. **OPERATIONAL**: System optional hooks can assis in many commonly configurations.

- setting ondemand cpu governor to reduce battery usage;
- wireless network / adaptors can be pre-configured;
- system DNS server configuration;
- changing the root password;
- openVPN client configuration;
- ssh service, with authorized_keys;
- ssh exposure to the internet through reverse forwarding: sshhub.de as a jumphost;

## Scenarios

Multiple example configurations can be found in the system, each on its own directory `example-...`.

Each example outlines a possible configurations scenario, from building an standart kali to building an encrypted drop box RPi for remote control.

## Installation

Clone this git repo.

## Usage

Simply:

$ `./cryptmypi.sh configuration_profile_directory`

`configuration_profile_directory` should be an existing configuration directory. Use one of the provided examples or create your own.

## Explore stage2
You can decrypt, mount and chroot an SD card by using the `explore` pre-configuration:

$ `./cryptmypi.sh examples/explore configuration_profile_directory`

There is an actual `explore` directory that contains an customized configuration profile. This profile overwrites the default stage1 and stage2 hooks so that no formatting, partitioning, etc is done. It reads another configuration profile and mounts an block device accordingly.

Aditionally, you can use this "hack" configuration for more than chrooting to bash. You may update existing systems by copying the `examples/explore` directory and changing `stage2_optional_hooks` to execute optional hooks or other commands.
