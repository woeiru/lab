### install basics
transactional-update pkg in git tree
transactional-update apply
transactional-update reboot

### install utils
git clone https://github.com/woeiru/lab.git
bash lab/go.sh

### update
tu
tuar

### distro update
tu dup
tuar

### set grub timer
tu run bash
    vim /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
tuar

### install pam snapper
tu run bash
    zypper install pam_snapper
    source /root/lab/dot/bash
    all-rs2 /usr/lib/pam_snapper/ DRYRUN=1 DRYRUN=0
tuar

### create standard user with id 1000
pam.config
pam.useradd <username> <usergroup>
tu
tuar

### installing cockpit
tu pkg in patterns microos-cockpit cockpit-tukit cockpit-ws
tuar
systemctl enable --now cockpit.socket
vim /etc/cockpit/

### in case of snapshot flat restore
osm-sfr /mnt/bak/home_<username>/<sNr>/snapshot /home/<username>

### troubleshooting
### ( some repo assosciated on install media )
tu run bash
	zypper lr
	zypper mr -d <no_or_alias>
tuar

### optional - swap home for homeraid on standalone sub
*delete old fstab entry*
all-fec 1 /home btrfs subvol=home 0 0
tu
tuar

### optional - create mountpoint on readonly part
tu run bash
    mkdir /mnt/bak /mnt/sto
tuar

