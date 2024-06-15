# 1
tu pkg in vim tree
# 2
bash lab/set/all.sh a
# 3
tu run bash
    zypper install pam_snapper
    all-rs2 /usr/lib/pam_snapper/ DRYRUN=1 DRYRUN=0
    exit
# 15
tu run bash
    mkdir /mnt/bak /mnt/sto
# 16
all-fec 1 /home btrfs subvol=home 0 0
