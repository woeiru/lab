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
all-fec 1 /home btrfs subvol=home 0 0
