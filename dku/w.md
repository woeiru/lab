# install basics
tu pkg in vim tree
*reboot*
# install utils
git clone https://github.com/woeiru/lab.git
bash lab/go.sh
# swap home for homeraid on standalone sub
*delete old fstab entry*
all-fec 1 /home btrfs subvol=home 0 0
*reboot*
# create mountpoint on readonly part
tu run bash
    mkdir /mnt/bak /mnt/sto
tu apply && tu reboot
# install pam snapper
tu run bash
    zypper install pam_snapper
    all-rs2 /usr/lib/pam_snapper/ DRYRUN=1 DRYRUN=0
    exit
tu apply && tu reboot
# create standard user with id 1000
pam.config
pam.useradd <username> <usergroup>
tu & tu apply & tu reboot
# in case of snapshot flat restore
osm-sfr /mnt/bak/home_<username>/<sNr>/snapshot /home/<username>
# container shrh
podman build -t custom-samba /root/lab/con/shrh

podman run -d \
    --name shrhxo \
    -p 139:139 -p 445:445 \
    -v /home/xo:/mount \
    custom-samba

# iptables setup
iptables -L -v -n
iptables -A INPUT -p tcp --dport 139 -j ACCEPT
iptables -A INPUT -p tcp --dport 445 -j ACCEPT
/sbin/iptables-save > /etc/sysconfig/iptables
iptables -L -v -n

# selinux setup
:
