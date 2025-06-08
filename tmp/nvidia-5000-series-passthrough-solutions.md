# NVIDIA 5000 Series GPU Passthrough Solutions

## Overview

The NVIDIA 5000 series GPUs (RTX 5060, 5060Ti, etc.) present significant challenges for GPU passthrough in Proxmox VE compared to previous generations (1000-4000 series). This document summarizes all known solutions and workarounds based on the Proxmox forum thread discussing these issues.

## Known Issues

### Primary Problems
1. **No UEFI BIOS Screen**: Unable to see TianoCore/OVMF BIOS screen during VM boot
2. **Black Screen**: Monitor turns on but displays no image even with NVIDIA drivers loaded
3. **Windows Boot Failure**: NVLDDMKM driver gets stuck in infinite loop at `GetBusData`
4. **Stability Issues**: Random freezes when powering off VMs
5. **Driver Detection**: NVIDIA drivers load but report no monitor detected

## Solutions and Workarounds

### 1. NVIDIA Firmware Update (CRITICAL)

**For RTX 5060 Series**:
- Download and install the [NVIDIA GPU UEFI Firmware Update Tool](https://nvidia.custhelp.com/app/answers/detail/a_id/5665/~/nvidia-gpu-uefi-firmware-update-tool-for-rtx-5060-series)
- This update is essential for proper UEFI boot support
- After firmware update, you should be able to see the TianoCore BIOS screen

### 2. VM Configuration Requirements

#### Essential VM Settings
```bash
# VM must use UEFI boot (not CSM)
# Enable PCI-Express support
# Enable "Primary GPU" option
# Set CPU type to "host"
# Enable Resizable BAR (ReBAR) in both host BIOS and VM
```

#### GPU Device Configuration
- **CRITICAL**: Untick "ROM-Bar" when adding the GPU initially
- **CRITICAL**: After firmware update, enable "ROM-Bar" and "PCI-Express"
- Set as Primary GPU if using single GPU passthrough

#### QEMU Configuration for Advanced Users
For RTX 5000 series, add this PCIe root port configuration:
```qemu
[device "ich9-pcie-port-1"]
  driver = "pcie-root-port"
  x-speed = "16"
  x-width = "32"
  multifunction = "on"
  bus = "pcie.0"
  addr = "1c.0"
  port = "1"
  chassis = "1"
```

### 3. Host Configuration

#### Kernel Requirements
- **Minimum Kernel**: 6.14.6 (contains required VFIO patches for RTX 5000 series)
- Tested working kernels: 6.14.8, 6.15
- Earlier kernels (6.8, 6.11, 6.13) may not work properly

#### NVIDIA Driver Configuration
Create `/etc/modprobe.d/nvidia-options.conf`:
```bash
options nvidia_modeset hdmi_deepcolor=0 conceal_vrr_caps=1
options nvidia_drm modeset=1
```

#### Alternative: Blacklist Nouveau
Add to GRUB configuration:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="module_blacklist=nouveau"
```

### 4. Dynamic Driver Management (Advanced)

#### Hook Script Approach
- Install NVIDIA drivers on Proxmox host with `modeset=1`
- Use hook scripts to dynamically unload NVIDIA drivers when starting VMs
- Automatically reload NVIDIA drivers when VMs shut down
- This allows GPU power management (P8 state) when not in use

#### Hook Script Benefits
- Enables Proxmox CLI recovery after VM shutdown
- Better power management
- More reliable than static VFIO binding

### 5. Guest OS Considerations

#### Linux Guests
- Install NVIDIA drivers with `modeset=1` option
- Add to `/etc/modprobe.d/nvidia.conf`:
```bash
options nvidia_drm modeset=1
```
- Update initramfs: `update-initramfs -u -k all`

#### Windows Guests
- **Issue**: Windows guests experience more problems than Linux
- **Symptom**: NVLDDMKM driver gets stuck in infinite loop
- **Workaround**: May require specific driver versions or additional registry modifications
- **Alternative**: Test with Linux guest first to verify hardware compatibility

### 6. Initial Setup Workaround

#### For No BIOS Screen Issue
1. Initially set up VM with virtual GPU (VirtIO-GPU or similar)
2. Install guest OS and NVIDIA drivers
3. Shut down VM
4. Remove virtual GPU
5. Add physical GPU with proper configuration
6. Boot VM - should now display properly

### 7. BIOS/UEFI Settings

#### Host BIOS Requirements
- Enable IOMMU/VT-d
- Enable Resizable BAR (ReBAR)
- Enable 4G Decoding (may help but not always required)
- Use UEFI boot mode

#### VM BIOS Settings
- Use OVMF (UEFI) instead of SeaBIOS
- Enable Secure Boot if required by guest OS
- Configure proper memory settings

## Step-by-Step Implementation

### Phase 1: Preparation
1. Update to kernel 6.14.6 or newer
2. Download and run NVIDIA firmware update tool
3. Verify BIOS settings (IOMMU, ReBAR, 4G decoding)
4. Install NVIDIA drivers on host with proper modprobe configuration

### Phase 2: VM Configuration
1. Create VM with UEFI boot
2. Add GPU with ROM-Bar disabled initially
3. Install guest OS using virtual GPU
4. Install NVIDIA drivers in guest
5. Shut down and reconfigure with physical GPU

### Phase 3: Optimization
1. Enable ROM-Bar and PCI-Express
2. Set as Primary GPU
3. Implement hook scripts for dynamic driver management
4. Test stability and power management

## Known Limitations

### Reliability Issues
- Setup may not be 100% reliable
- Occasional VM freezes during shutdown
- NVIDIA driver issues may persist with 5000 series

### Windows-Specific Problems
- More problematic than Linux guests
- Driver compatibility issues
- May require specific Windows versions or driver versions

### Hardware Compatibility
- Success may vary between manufacturers (MSI, Gigabyte, ASUS)
- Some cards may work better than others within the same series

## Troubleshooting

### No BIOS Screen
1. Verify firmware update was successful
2. Check ROM-Bar and PCI-Express settings
3. Ensure UEFI boot mode is enabled
4. Try different kernel versions

### Black Screen After Driver Install
1. Verify `modeset=1` configuration
2. Check hook script implementation
3. Test with Linux guest first
4. Verify PCIe root port configuration

### Windows Boot Failure
1. Try different NVIDIA driver versions
2. Consider using Linux guest as alternative
3. Check for Windows-specific registry modifications
4. Verify VM hardware configuration matches requirements

## Success Reports

### Working Configurations
- **Host**: Proxmox VE latest with kernel 6.14.8+
- **Guest**: Linux distributions (CachyOS confirmed working)
- **Hardware**: RTX 5060Ti (MSI and Gigabyte confirmed)
- **Method**: Dynamic driver management with hook scripts

### Key Success Factors
1. NVIDIA firmware update completion
2. Correct kernel version (6.14.6+)
3. Proper modprobe configuration with `modeset=1`
4. UEFI boot configuration
5. Dynamic driver management approach

## Future Considerations

- NVIDIA may release additional firmware updates
- Kernel improvements may address current limitations
- Windows driver updates may resolve compatibility issues
- Community may develop additional workarounds

## References

- [NVIDIA RTX 5060 Series Firmware Update](https://nvidia.custhelp.com/app/answers/detail/a_id/5665/)
- [Proxmox Forum Discussion](https://forum.proxmox.com/threads/nvidia-5000-series-passthrough-failing-miserably.165456/)
- [Proxmox GPU Passthrough Documentation](https://pve.proxmox.com/wiki/PCI_Passthrough)

---

*Last Updated: Based on forum discussion through May 30, 2025*
*Thread Contributors: adolfotregosa, number201724, kenjiro310*
