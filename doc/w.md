# -------
tu pkg in vim tree
# -------
bash lab/set/all.sh a
# -------
tu run bash
    zypper install pam_snapper
    all-rs2 /usr/lib/pam_snapper/ DRYRUN=1 DRYRUN=0
    exit
# -------
tu run bash
    mkdir /mnt/bak /mnt/sto
# -------
*delete old entry*
all-fec 1 /home btrfs subvol=home 0 0
*reboot*
# -------
pam.config
pam.useradd <username> <usergroup>
# -------
osm-sfr /path/to/snapshot /home/<username>
# -------
# -------
