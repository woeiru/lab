### 1 install basics
transactional-update pkg in git tree
transactional-update apply
transactional-update reboot
git clone https://github.com/woeiru/lab.git
bash lab/set/all.sh a

### 2 remove repo assosciated on install media
tu run bash
	zypper lr
	zypper mr -d <no_or_alias>
tuar
reboot

### 3 update
tu
tuar
reboot

### 4 set grub timer
tu run bash
    sed -i 's/^GRUB_TIMEOUT=8/GRUB_TIMEOUT=4/' /etc/default/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
tuar
reboot

### 5 - swap home for homeraid on standalone sub
tu run bash
    mkdir /mnt/das /mnt/nvm /bak
tuar
reboot

mount * /mnt/nvm
bt sub create /mnt/nvm/home

umount /home
*delete old fstab entry*
all-fec 1 /home btrfs subvol=home 0 0

### install pam snapper
tu run bash
    zypper install pam_snapper
    . /root/lab/dot/bashrc
    all-rsf /usr/lib/pam_snapper/ DRYRUN=1 DRYRUN=0
    
    ### test this
    sed -i 's/useradd --no-create-home/useradd --no-create-home --user-group/' pam_snapper_useradd.sh && \
    sed -i 's/if \[ ".${MYGROUP}" == "." \] ; then MYGROUP="users"; fi/if \[ ".${MYGROUP}" == "." \] ; then MYGROUP="${MYUSER}"; fi/' pam_snapper_useradd.sh

tuar
reboot

### create standard user with id 1000
pam.config
pam.useradd <username> <usergroup>
passwd <username>
    ### if test did not work :
    groupadd -g 1000 es
    usermod -g es es
tu
tuar

### installing cockpit
tu pkg in patterns-microos-cockpit cockpit-tukit cockpit-ws
tuar
systemctl enable --now cockpit.socket
vim /etc/cockpit/disallowed-users
tu
tuar

### in case of snapshot flat restore
osm-sfr /mnt/bak/home_<username>/<sNr>/snapshot /home/<username>


