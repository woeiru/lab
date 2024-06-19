### install basics
transactional-update pkg in vim tree
transactional-update apply
transactional-update reboot

### install utils
git clone https://github.com/woeiru/lab.git
bash lab/go.sh

### set grub timer
vim /etc/default/grub
tu grub.cfg

### swap home for homeraid on standalone sub
*delete old fstab entry*
all-fec 1 /home btrfs subvol=home 0 0
tua && tur

### create mountpoint on readonly part
tu run bash
    mkdir /mnt/bak /mnt/sto
tua && tur

### install pam snapper
    tu run bash
        zypper install pam_snapper
    all-rs2 /usr/lib/pam_snapper/ DRYRUN=1 DRYRUN=0
    exit
tua && tur

### create standard user with id 1000
pam.config
pam.useradd <username> <usergroup>
tu & tu apply & tu reboot

### in case of snapshot flat restore
osm-sfr /mnt/bak/home_<username>/<sNr>/snapshot /home/<username>

### installing cockpit
tu pkg in patterns-microos-cockpit cockpit-ws cockpit-tukit 
systemctl enable --now cockpit.socket



### troubleshooting
### ( some repo assosciated on install media )
tu run bash
	zypper lr
	zypper mr -d <no_or_alias>
tua && tur
