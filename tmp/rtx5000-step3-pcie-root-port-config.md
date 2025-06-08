# Step 3: PCIe Root Port Configuration for RTX 5000 Series

## Current Status
- **VM**: 111 (w11-de-242)
- **Current GPU Config**: `hostpci0: 0000:3b:00.0,pcie=1,x-vga=1`
- **Issue**: Missing advanced PCIe root port configuration for RTX 5000 series
- **Required**: Specific QEMU PCIe topology for RTX 5000 series compatibility

## Why This Is Critical
RTX 5000 series GPUs require specific PCIe root port configuration to function properly in VMs. The standard `pcie=1` flag is insufficient - advanced PCIe topology configuration is needed for:
- Proper PCIe bandwidth allocation (x16 speed, x32 width)
- Correct PCIe root port topology
- RTX 5000 series compatibility with VM environment

## Current VM Configuration Analysis

```bash
# Current VM 111 configuration:
hostpci0: 0000:3b:00.0,pcie=1,x-vga=1
hostpci1: 0000:3b:00.1,pcie=1
machine: pc-q35-9.2+pve1
```

## Implementation Steps

### Step 3.1: Backup Current Configuration

```bash
# SSH to x1 as root
ssh root@x1

# Stop VM if running
qm stop 111

# Backup current configuration
cp /etc/pve/qemu-server/111.conf /etc/pve/qemu-server/111.conf.backup

# Show current config
qm config 111
```

### Step 3.2: Method A - Direct QEMU Configuration Edit

```bash
# Edit VM configuration file directly
nano /etc/pve/qemu-server/111.conf

# Add the following PCIe root port configuration
# Find the [global] section or add it if it doesn't exist
# Add these lines after the existing configuration:

cat >> /etc/pve/qemu-server/111.conf << 'EOF'

# RTX 5000 Series PCIe Root Port Configuration
args: -device pcie-root-port,id=ich9-pcie-port-1,x-speed=16,x-width=32,multifunction=on,bus=pcie.0,addr=1c.0,port=1,chassis=1
EOF
```

### Step 3.3: Method B - QEMU Args Configuration

```bash
# Alternative method using qm set command
qm set 111 -args '-device pcie-root-port,id=ich9-pcie-port-1,x-speed=16,x-width=32,multifunction=on,bus=pcie.0,addr=1c.0,port=1,chassis=1'

# Verify the configuration was added
qm config 111 | grep args
```

### Step 3.4: Method C - Advanced QEMU Configuration File

```bash
# Create advanced QEMU configuration file
mkdir -p /etc/pve/qemu-server/

# Create advanced config file for VM 111
cat > /etc/pve/qemu-server/111-advanced.cfg << 'EOF'
# RTX 5000 Series Advanced PCIe Configuration

[device "ich9-pcie-port-1"]
  driver = "pcie-root-port"
  x-speed = "16"
  x-width = "32"
  multifunction = "on"
  bus = "pcie.0"
  addr = "1c.0"
  port = "1"
  chassis = "1"

[device "ich9-pcie-port-2"]
  driver = "pcie-root-port"
  x-speed = "16"
  x-width = "16"
  multifunction = "on"
  bus = "pcie.0"
  addr = "1c.1"
  port = "2"
  chassis = "2"
EOF

# Include this configuration in VM args
qm set 111 -args "-readconfig /etc/pve/qemu-server/111-advanced.cfg"
```

### Step 3.5: Update GPU Device Configuration

```bash
# Update hostpci configuration to use the new PCIe topology
# Remove existing hostpci configs
qm set 111 -delete hostpci0
qm set 111 -delete hostpci1

# Add GPU with advanced PCIe configuration
qm set 111 -hostpci0 0000:3b:00.0,pcie=1,x-vga=1,rombar=1,bus=ich9-pcie-port-1
qm set 111 -hostpci1 0000:3b:00.1,pcie=1,rombar=1,bus=ich9-pcie-port-2
```

### Step 3.6: Alternative Complete VM Configuration

```bash
# Complete VM configuration optimized for RTX 5000 series
qm stop 111

# Update machine type for better PCIe support
qm set 111 -machine pc-q35-9.2+pve1

# Update CPU type for better performance
qm set 111 -cpu host

# Ensure UEFI with proper settings
qm set 111 -bios ovmf

# Disable VGA (using GPU as primary)
qm set 111 -vga none

# Advanced args for RTX 5000 series
qm set 111 -args '-device pcie-root-port,id=rp1,x-speed=16,x-width=32,multifunction=on,bus=pcie.0,addr=1c.0,port=1,chassis=1 -device pcie-root-port,id=rp2,x-speed=16,x-width=16,multifunction=on,bus=pcie.0,addr=1c.1,port=2,chassis=2'
```

### Step 3.7: Verification and Testing

```bash
# Verify configuration
qm config 111

# Check GPU status
source /root/lab/src/mgt/pve && gpu_pts_w

# Ensure GPU is detached
source /root/lab/src/mgt/pve && gpu_ptd_w

# Start VM with new configuration
qm start 111

# Monitor VM startup
qm monitor 111

# Check VM status
qm status 111
```

## Advanced Configuration Options

### Option 1: ResizeableBAR Support
```bash
# Add ResizeableBAR support if available in BIOS
qm set 111 -args '-device pcie-root-port,id=rp1,x-speed=16,x-width=32,multifunction=on,bus=pcie.0,addr=1c.0,port=1,chassis=1,rbar=on'
```

### Option 2: MSI/MSI-X Configuration
```bash
# Enhanced MSI configuration for better interrupt handling
qm set 111 -args '-device pcie-root-port,id=rp1,x-speed=16,x-width=32,multifunction=on,bus=pcie.0,addr=1c.0,port=1,chassis=1 -global ICH9-LPC.disable_s3=1 -global ICH9-LPC.disable_s4=1'
```

### Option 3: VFIO Advanced Options
```bash
# Advanced VFIO options for RTX 5000 series
cat > /etc/modprobe.d/vfio-rtx5000.conf << 'EOF'
options vfio_pci ids=10de:2d04,10de:22eb
options vfio_pci disable_vga=1
options vfio_pci disable_idle_d3=1
EOF

# Update initramfs
update-initramfs -u -k all
```

## Troubleshooting

### Configuration Not Applied
```bash
# If configuration doesn't seem to take effect:
# 1. Stop VM completely
qm stop 111

# 2. Check for syntax errors in config
qm config 111

# 3. Restart pve services
systemctl restart pveproxy
systemctl restart pvedaemon
```

### VM Won't Start
```bash
# If VM fails to start with new config:
# 1. Check VM logs
journalctl -u qemu-server@111

# 2. Restore backup configuration
cp /etc/pve/qemu-server/111.conf.backup /etc/pve/qemu-server/111.conf

# 3. Test step by step
qm start 111
```

### PCIe Errors
```bash
# Check for PCIe topology errors
dmesg | grep -i pcie
dmesg | grep -i vfio

# Check IOMMU groups
find /sys/kernel/iommu_groups/ -type l | sort -V
```

## Verification Steps

### Test 1: VM Startup
```bash
qm start 111
# Should start without PCIe-related errors
```

### Test 2: GPU Recognition
```bash
# In Windows VM, check Device Manager
# GPU should appear without error codes
```

### Test 3: Display Output
```bash
# Connect monitor to GPU
# Should see UEFI screen and Windows desktop
```

### Test 4: Performance Check
```bash
# In Windows VM, run GPU benchmark
# Verify full PCIe bandwidth utilization
```

## Expected Results

After implementing PCIe root port configuration:
- VM starts without PCIe topology errors
- GPU has proper PCIe bandwidth (x16)
- Display output functions correctly
- Improved stability and performance
- UEFI screen visible during boot

## Rollback Plan

If configuration causes issues:
```bash
# Stop VM
qm stop 111

# Restore backup
cp /etc/pve/qemu-server/111.conf.backup /etc/pve/qemu-server/111.conf

# Clear any additional args
qm set 111 -delete args

# Restart with original config
qm start 111
```

## Next Steps

After implementing all three steps:
1. Test VM thoroughly for stability
2. Monitor GPU temperatures and performance
3. Consider implementing dynamic driver management
4. Document working configuration for future use

## Reference Configuration

Final working VM configuration should look like:
```
args: -device pcie-root-port,id=rp1,x-speed=16,x-width=32,multifunction=on,bus=pcie.0,addr=1c.0,port=1,chassis=1
bios: ovmf
cpu: host
hostpci0: 0000:3b:00.0,pcie=1,x-vga=1,rombar=1
hostpci1: 0000:3b:00.1,pcie=1,rombar=1
machine: pc-q35-9.2+pve1
vga: none
```

## Reference Links
- [QEMU PCIe Configuration](https://qemu.readthedocs.io/en/latest/system/pcie.html)
- [Proxmox GPU Passthrough](https://pve.proxmox.com/wiki/PCI_Passthrough)
- [RTX 5000 Series Forum Discussion](https://forum.proxmox.com/threads/nvidia-5000-series-passthrough-failing-miserably.165456/)