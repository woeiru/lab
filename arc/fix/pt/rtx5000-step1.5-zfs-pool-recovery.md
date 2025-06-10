# RTX 5000 Series - Step 1.5: ZFS Pool Recovery After Kernel Update

## Issue Description
After updating to kernel 6.15.0, the ZFS pool became unavailable on Proxmox node x1. The system was unable to load ZFS modules due to kernel compatibility issues.

## Root Cause
- System booted into custom kernel 6.15.0 instead of Proxmox kernel
- ZFS DKMS package (version 2.1.11) only supports kernels up to 6.2
- Kernel 6.15.0 was incompatible with available ZFS modules

## Diagnosis Steps

### 1. Initial Assessment
```bash
ssh root@x1
zpool status
# Result: "The ZFS modules cannot be auto-loaded"
```

### 2. Module Loading Attempt
```bash
modprobe zfs
# Result: "FATAL: Module zfs not found in directory /lib/modules/6.15.0"
```

### 3. Package Investigation
```bash
dpkg -l | grep zfs
dkms status
# Found: ZFS packages installed but no DKMS modules for current kernel
```

### 4. Kernel Version Check
```bash
uname -r
# Result: 6.15.0 (custom kernel, not Proxmox)
```

## Resolution Steps

### 1. Remove Incompatible ZFS DKMS
```bash
apt remove --purge -y zfs-dkms
```

### 2. Set Proxmox Kernel as Default
```bash
proxmox-boot-tool kernel pin 6.8.12-10-pve
```

### 3. Reboot to Compatible Kernel
```bash
reboot
```

### 4. Verify Recovery
```bash
uname -r
# Result: 6.8.12-10-pve

zpool status
# Result: pool: local-zfs, state: ONLINE

zfs list
# All datasets accessible
```

## Final Status
- **Kernel**: 6.8.12-10-pve (Proxmox kernel with built-in ZFS support)
- **ZFS Pool**: ONLINE and fully functional
- **Datasets**: All VM disks accessible
- **ZFS Modules**: Loaded automatically with compatible kernel

## Key Learnings
1. Always use Proxmox kernels on Proxmox systems for ZFS compatibility
2. ZFS DKMS has kernel version limitations - check compatibility before kernel updates
3. Proxmox kernels include built-in ZFS support, eliminating DKMS dependency
4. Use `proxmox-boot-tool kernel pin` to set default boot kernel

## Prevention
- Stick to Proxmox-provided kernels for production systems
- Test kernel updates in non-production environments first
- Monitor kernel compatibility with ZFS before system updates