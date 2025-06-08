# Step 1: Kernel Upgrade for RTX 5000 Series Support

## Current Status
- **Current Kernel**: 6.8.12-10-pve
- **Required Kernel**: 6.14.6+ (minimum for RTX 5000 series VFIO patches)
- **Target Kernel**: 6.15+ (recommended stable version)

## Why This Is Critical
RTX 5000 series GPUs require specific VFIO patches that were only included starting from kernel 6.14.6. Earlier kernels (6.8, 6.11, 6.13) have known compatibility issues with RTX 5000 series passthrough.

## Implementation Steps

### Pre-Upgrade Preparation
```bash
# SSH to x1 as root
ssh root@x1

# Check current kernel and available kernels
uname -r
apt list --installed | grep pve-kernel

# Check Proxmox version
pveversion

# Backup current configuration (optional but recommended)
cp /etc/default/grub /etc/default/grub.backup
cp /etc/modules /etc/modules.backup
```

### Method 1: Proxmox Repository Update (Recommended)

```bash
# Update package lists
apt update

# Check available PVE kernels
apt search pve-kernel

# Look for kernel versions 6.14+ or 6.15+
# Install the latest available kernel (example - adjust version)
apt install pve-kernel-6.15.x-x-pve

# Update GRUB to use new kernel
update-grub

# Reboot to new kernel
reboot
```

### Method 2: Enable No-Subscription Repository (If Needed)

If latest kernels aren't available in current repository:

```bash
# Edit sources list
nano /etc/apt/sources.list

# Add/uncomment Proxmox no-subscription repository
# deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription

# Update and search again
apt update
apt search pve-kernel | grep 6.1[4-9]
```

### Method 3: Manual Kernel Compilation (Advanced)

Only if repository method fails:

```bash
# Install build dependencies
apt install build-essential git fakeroot

# Download kernel source
cd /usr/src
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.15.tar.xz
tar -xf linux-6.15.tar.xz
cd linux-6.15

# Copy current config
cp /boot/config-$(uname -r) .config
make oldconfig

# Enable required VFIO options
make menuconfig
# Navigate to: Device Drivers -> VFIO Non-Privileged userspace driver framework
# Ensure all VFIO options are enabled

# Compile and install
make -j$(nproc) deb-pkg
dpkg -i ../linux-*.deb
```

### Post-Upgrade Verification

```bash
# After reboot, verify new kernel
uname -r

# Check if VFIO modules are available
modinfo vfio_pci | grep version

# Verify IOMMU is still enabled
cat /proc/cmdline | grep iommu

# Test GPU detachment with new kernel
source /root/lab/src/mgt/pve && gpu_pts_w
```

### Troubleshooting

**If system doesn't boot after kernel upgrade:**
1. Boot from GRUB recovery mode
2. Select previous kernel version
3. Remove problematic kernel: `apt remove pve-kernel-<version>`
4. Try alternative kernel version

**If NVIDIA drivers fail to load:**
```bash
# Reinstall NVIDIA drivers for new kernel
apt install --reinstall nvidia-driver
dkms autoinstall
```

**If VFIO modules missing:**
```bash
# Ensure VFIO modules are in /etc/modules
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
update-initramfs -u -k all
```

## Expected Results

After successful kernel upgrade:
- Kernel version 6.14.6+ or higher
- VFIO modules load properly
- RTX 5000 series GPU can be bound to vfio-pci without errors
- Improved stability during VM startup/shutdown

## Next Steps

After kernel upgrade is complete and verified:
1. Proceed to Step 2: NVIDIA Firmware Update
2. Test GPU passthrough again
3. If still having issues, implement Step 3: PCIe Root Port Configuration

## Reference Links
- [RTX 5000 Series Known Issues](https://forum.proxmox.com/threads/nvidia-5000-series-passthrough-failing-miserably.165456/)
- [Proxmox Kernel Updates](https://pve.proxmox.com/wiki/Package_Repositories)