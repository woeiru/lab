# Step 2: NVIDIA Firmware Update for RTX 5000 Series

## Current Status
- **GPU Detected**: NVIDIA Device [10de:2d04] (RTX 5000 Series)
- **Issue**: Black screen during UEFI boot / VM startup
- **Root Cause**: RTX 5000 series requires specific UEFI firmware for proper passthrough

## Why This Is Critical
RTX 5000 series GPUs ship with firmware that lacks proper UEFI boot support for virtualization. NVIDIA released a specific firmware update tool to address passthrough issues, including:
- No UEFI BIOS screen during VM boot
- Black screen issues in VMs
- Driver detection problems

## Implementation Steps

### Step 2.1: Download NVIDIA Firmware Update Tool

```bash
# Download the official NVIDIA GPU UEFI Firmware Update Tool
# This needs to be done on a Windows system or Windows VM with the GPU

# Official NVIDIA Support Link:
# https://nvidia.custhelp.com/app/answers/detail/a_id/5665/

# Alternative: Use temporary Windows VM setup if needed
```

### Step 2.2: Prepare for Firmware Update

```bash
# SSH to x1 as root
ssh root@x1

# Stop VM 111 if running
qm stop 111

# Attach GPU back to host for firmware update
source /root/lab/src/mgt/pve && gpu_pta_w

# Verify GPU is attached to host
source /root/lab/src/mgt/pve && gpu_pts_w | grep "Overall GPU State"
```

### Step 2.3: Firmware Update Process

**Option A: Windows Host with GPU**
1. Download NVIDIA GPU UEFI Firmware Update Tool from official link
2. Install and run the tool
3. Follow the tool's instructions to update GPU firmware
4. Reboot Windows system
5. Verify firmware update completed successfully

**Option B: Temporary Windows VM (Current Setup)**
```bash
# If using current VM 111 for firmware update:

# 1. Ensure VM 111 has Windows installed and running
qm start 111

# 2. Inside Windows VM:
#    - Download NVIDIA firmware update tool
#    - Install latest NVIDIA drivers
#    - Run firmware update tool
#    - Follow all prompts and reboot as requested

# 3. After firmware update in VM:
qm shutdown 111
```

**Option C: Alternative Firmware Check**
```bash
# Check current GPU firmware version (if available)
ssh root@x1

# Use nvidia-smi to check current firmware
nvidia-smi -q | grep -i firmware

# Check GPU BIOS version
lspci -vv -s 3b:00.0 | grep -i rom
```

### Step 2.4: Post-Firmware Update Verification

```bash
# After firmware update is complete:

# 1. Detach GPU for passthrough again
source /root/lab/src/mgt/pve && gpu_ptd_w

# 2. Update VM configuration to enable ROM-Bar
qm set 111 -hostpci0 0000:3b:00.0,pcie=1,x-vga=1,rombar=1

# 3. Test VM startup
qm start 111

# 4. Check if UEFI screen is now visible during boot
# (Connect monitor to GPU output during VM startup)
```

### Step 2.5: VM Configuration Updates Post-Firmware

```bash
# After successful firmware update, update VM config:

# Enable ROM-Bar and ensure PCI-Express is enabled
qm set 111 -hostpci0 0000:3b:00.0,pcie=1,x-vga=1,rombar=1
qm set 111 -hostpci1 0000:3b:00.1,pcie=1,rombar=1

# Ensure UEFI boot is configured properly
qm set 111 -bios ovmf

# Set as primary GPU (if not already set)
qm set 111 -vga none
```

### Step 2.6: Advanced Configuration (If Needed)

```bash
# Add NVIDIA driver modprobe options for host
cat > /etc/modprobe.d/nvidia-options.conf << EOF
options nvidia_modeset hdmi_deepcolor=0 conceal_vrr_caps=1
options nvidia_drm modeset=1
EOF

# Update initramfs
update-initramfs -u -k all
```

## Verification Steps

### Test 1: UEFI Screen Visibility
```bash
# Start VM and check if TianoCore UEFI screen appears
qm start 111

# Connect monitor to GPU output
# You should now see the UEFI boot screen
```

### Test 2: Windows Boot Success
```bash
# Check if Windows boots without NVLDDMKM driver issues
# Monitor VM console for any driver-related errors
qm monitor 111
```

### Test 3: Display Output
```bash
# Verify display output works in Windows
# Check if NVIDIA drivers detect the GPU properly
```

## Troubleshooting

### Firmware Update Fails
```bash
# If firmware update tool fails:
# 1. Ensure GPU is properly attached to host
# 2. Install latest NVIDIA drivers first
# 3. Run Windows update
# 4. Try firmware update again
```

### Still No UEFI Screen
```bash
# If UEFI screen still doesn't appear:
# 1. Verify ROM-Bar is enabled
# 2. Check UEFI boot settings
# 3. Try different monitor/cable
# 4. Proceed to Step 3 (PCIe Root Port configuration)
```

### Driver Issues After Update
```bash
# If drivers fail after firmware update:
# 1. Reinstall NVIDIA drivers in guest
# 2. Check for Windows driver updates
# 3. Try different driver versions
```

## Expected Results

After successful firmware update:
- TianoCore UEFI screen visible during VM boot
- Windows boots without driver loop issues
- NVIDIA drivers properly detect GPU in VM
- Display output works correctly

## Next Steps

After firmware update is complete:
1. Test VM thoroughly for stability
2. If issues persist, proceed to Step 3: PCIe Root Port Configuration
3. Consider implementing dynamic driver management scripts

## Important Notes

- Firmware update is **irreversible** - ensure you have working backup plan
- Update may take several minutes - do not interrupt the process
- Some RTX 5000 series cards may not have firmware updates available yet
- Contact NVIDIA support if firmware update tool is not available for your specific model

## Reference Links
- [NVIDIA RTX 5000 Series Firmware Update](https://nvidia.custhelp.com/app/answers/detail/a_id/5665/)
- [Proxmox GPU Passthrough Wiki](https://pve.proxmox.com/wiki/PCI_Passthrough)