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
all-fec 1 /home btrfs subvol=home 0 0
tu pkg in sysstat
tuar
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

export USER_NAME=es 
export USER_GROUP=es

pam.config
pam.useradd ${USER_NAME} ${USER_GROUP}
passwd ${USER_NAME}
cp /root/.ssh/authorized_keys /home/es/.ssh/authorized_keys
find /home/${USER_NAME}/ -path ./snapshot -prune -o -exec chown ${USERNAME}: {} +
tu pkg in htop
reboot

### 10 - installing cockpit
tu pkg in patterns-microos-cockpit cockpit-tukit cockpit-ws
tuar
reboot

### 11 - configuring cockpit
systemctl enable --now cockpit.socket
sed -i '/root/s/^/# /' /etc/cockpit/disallowed-users

tu pkg in
reboot

### 12 -- 
### troubleshoot - Failed to start Create missing directories from rpmdb
ls -ld /var/lib/pcp/config/derived
sudo mkdir -p /var/lib/pcp/config/derived
sudo chmod 755 /var/lib/pcp/config/derived
sudo chown root: /var/lib/pcp/config/derived

tu pkg in htop
tuar
reboot

### in case of snapshot flat restore
osm-sfr /mnt/bak/home_<username>/<sNr>/snapshot /home/<username>


### fix user alternative instead of the sed command for the pam_snapper config
    groupadd -g 1000 es
    usermod -g es es


