## as superuser

### lab base config
zypper in git
yast partitioner - subvol @/lab
git clone https://github.com/maxwagne/lab.git /lab

### config
ln -fns /lab/con/bash.bashrc.local /etc/bash.bashrc.local

### bugfixes
sudo bash $HOME/g/suse/acpi/depl.sh

### setup remote
systemctl status sshd
systemctl enable sshd
systemctl start sshd

firewall-cmd --add-service=ssh --permanent
firewall-cmd --reload

### setup samba


vim /etc/samba/smb.conf

[beta]
        comment =
        inherit acls = Yes
        path = /opt/beta
        read only = No
        vfs objects = btrfs                               

firewall-cmd --add-service=samba --permanent
firewall-cmd --reload


### create user home with pam and snapper
zypper in pam_snapper
echo "session optional pam_snapper.so" > /etc/pam.d/common-session
[set DRYRUN=0] /usr/lib/pam_snapper/pam_snapper_useradd.sh
[set password]

### data management
btrfs subvol create /opt/alpha
snapper -c alpha create-config /opt/alpha


## as user

### setup desktop
/etc/sddm.conf.d/autologin.conf
[Autologin]
User=
Session=plasmawayland.desktop

theme
konsole
sddm
energy
lock screen
