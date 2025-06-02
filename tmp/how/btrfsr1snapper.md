<!--
#######################################################################
# Btrfs RAID 1 with Snapper Setup Guide - Technical Reference
#######################################################################
# File: doc/how/btrfsr1snapper.md
# Description: Comprehensive step-by-step guide for setting up Btrfs
#              RAID 1 configuration with Snapper snapshot management
#              on openSUSE-based systems.
#
# Document Purpose:
#   Provides detailed procedural instructions for implementing
#   Btrfs RAID 1 storage configuration with automated snapshot
#   management through Snapper integration.
#
# Technical Scope:
#   - Btrfs filesystem RAID 1 configuration
#   - Snapper snapshot management setup
#   - openSUSE transactional-update integration
#   - Storage repository configuration procedures
#
# Target Audience:
#   Storage administrators, system engineers, and infrastructure
#   specialists implementing advanced filesystem configurations
#   with automated backup and snapshot capabilities.
#
# Dependencies:
#   - openSUSE operating system
#   - Btrfs filesystem utilities
#   - Snapper snapshot management tools
#   - Lab environment repository access
#######################################################################
-->

# Btrfs RAID 1 with Snapper Setup Guide

### 1 - install basics
transactional-update pkg in git tree
git clone https://github.com/woeiru/lab.git
bash lab/set/all.sh a
reboot

### 2 - remove repo assosciated on install media
zypper lr
tu run zypper mr -d <no_or_alias>
reboot

### 3 - update
tu
reboot

### 4 - set grub timer
tu run bash -c '
  sed -i '\''s/^GRUB_TIMEOUT=8/GRUB_TIMEOUT=4/'\'' /etc/default/grub
  grub2-mkconfig -o /boot/grub2/grub.cfg
'
reboot

### 5 - create mountpoints
tu run mkdir /mnt/das /bak
reboot

### - storage ( optional )
mount *device* /mnt/nvm
bt sub create /mnt/nvm/home
*delete old fstab entry*
sto_fec 1 /home btrfs subvol=home 0 0
tu pkg in htop
reboot

### 6 - install pam snapper
tu run bash
    zypper install pam_snapper
    . /root/lab/dot/bashrc
    all-rsf /usr/lib/pam_snapper/ DRYRUN=1 DRYRUN=0
    sed -i 's/useradd --no-create-home/useradd --no-create-home --user-group/' /usr/lib/pam_snapper/pam_snapper_useradd.sh
    sed -i 's/if \[ ".${MYGROUP}" == "." \] ; then MYGROUP="users"; fi/if \[ ".${MYGROUP}" == "." \] ; then MYGROUP="${MYUSER}"; fi/' /usr/lib/pam_snapper/pam_snapper_useradd.sh
    exit
reboot

### 7 - create standard user with id 1000

export USERNAME=es 
export USERGRP=es

pam.config
pam.useradd ${USERNAME} ${USERGRP}
passwd ${USERNAME}
mkdir /home/${USERNAME}/.ssh
cp /root/.ssh/authorized_keys /home/${USERNAME}/.ssh/authorized_keys
find /home/${USERNAME} -path /home/${USERNAME}/.snapshots -prune -o -exec chown ${USERNAME}: {} +
tu pkg in btop
reboot

### 8 - installing cockpit
tu pkg in patterns-microos-cockpit cockpit-tukit cockpit-ws
reboot

### 9 - configuring cockpit
systemctl enable --now cockpit.socket
sed -i '/root/s/^/# /' /etc/cockpit/disallowed-users
tu pkg in atop
reboot

### 10 - current
m.sub.sda.bak
sto-bfs-sfr

### sysstat troubleshoot
ls -ld /var/lib/pcp/config/derived
sudo mkdir -p /var/lib/pcp/config/derived
sudo chmod 755 /var/lib/pcp/config/derived
sudo chown root: /var/lib/pcp/config/derived

### in case of snapshot flat restore
sto-bfs-sfr /mnt/bak/home_<username>/<sNr>/snapshot /home/<username>

### Resync User Home Snapshot to Live Directory

Use `sto-bfs-sfr` to resync a Btrfs snapshot of a user's home directory to their live home directory. This is useful for rolling back changes or restoring data from a snapshot.

**Command:**

```bash
sto-bfs-sfr /mnt/bak/home_<username>/<sNr>/snapshot /home/<username>
```

### fix user alternative instead of the sed command for the pam_snapper config
    groupadd -sudo chmod 755 /var/lib/pcp/config/derived
g 1000 es
    usermod -g es es
