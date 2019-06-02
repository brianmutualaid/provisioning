# provisioning

## Overview

A collection of shell scripts and configuration files used to provision new systems.

## Directories

`files` holds configuration files. Subdirectories match the name of the role script and the `common` subdirectory holds files used by more than one role.

`roles` holds wrapper scripts that can be run to set up a server with a particular role. These wrapper scripts collect and set variables and pass them to scripts in the `scripts` directory.

`scripts` holds shell scripts that are run from scripts in the `roles` directory. There is a `common` subdirectory for scripts that are used by multiple roles, and subdirectories for each role like `web` and `kvm`.

## Usage

```
# git clone https://github.com/brianreumere/provisioning.git
# cd provisioning/roles
# ./<role>.sh <flags>
```

For example:

```
# ./web.sh -d example.com
```

Run any script in `roles` with the `-h` flag to print usage information.

## Usage with kvm-install-vm

These scripts can also be used in conjunction with kvm-install-vm to quickly set up guest VMs with particular roles. For example, to launch an Ubuntu 18.04 VM with a 20 GB disk 2 GB of RAM, and autostart enabled, and set up CodiMD on it:

```
kvm-install-vm create -a -d 20 -m 2048 -s bootstrap.sh
```
