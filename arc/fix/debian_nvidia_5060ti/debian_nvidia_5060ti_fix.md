# Fix: KDE Plasma / NVIDIA RTX 5060 Ti on Debian Trixie (13)

**System:** Debian 13 (Trixie) — kernel `6.12.73+deb13-amd64`  
**GPU:** NVIDIA GeForce RTX 5060 Ti (`10de:2d04`, GB206)  
**Problem:** KDE Plasma does not start; NVIDIA 550.163.01 (closed-source) fails with `error -1` in dmesg.

> [!IMPORTANT]
> The RTX 5060 Ti is a Blackwell-generation GPU. The standard closed-source `nvidia-kernel-dkms`
> fails to probe it. The **open-source kernel module** (`nvidia-open-kernel-dkms`) must be used instead.

---

## Action Plan

### Step 1 — Enable non-free repos

The default Debian install only has `main non-free-firmware`. Add `contrib non-free`:

```bash
sudo sed -i -E 's/main.*non-free-firmware/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
sudo apt-get update
```

### Step 2 — Remove the closed-source kernel module (if already installed)

```bash
sudo apt-get purge -y nvidia-kernel-dkms nvidia-kernel-support
sudo apt-get autoremove -y
```

### Step 3 — Install the proprietary userspace + open kernel module

```bash
sudo apt-get install -y linux-headers-amd64 nvidia-driver nvidia-open-kernel-dkms firmware-misc-nonfree
```

This installs:
- `nvidia-driver` — userspace libs, nvidia-smi, Xorg driver  
- `nvidia-open-kernel-dkms` — GPU-side kernel module (open variant, supports Blackwell)  
- `firmware-misc-nonfree` — GSP firmware  

> [!NOTE]
> `nvidia-open-kernel-dkms` will be pulled in automatically as a dependency of `nvidia-driver`
> **only if** `nvidia-kernel-dkms` (closed-source) is not already installed. If both get installed,
> the closed-source module takes priority and fails. That's why Step 2 is critical.

### Step 4 — Enable the open module for newer (unsupported) GPUs

```bash
echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" | sudo tee /etc/modprobe.d/nvidia-open.conf
```

### Step 5 — Rebuild initramfs and reboot

```bash
sudo update-initramfs -u
sudo reboot
```

### Step 6 — Verify

After rebooting:

```bash
nvidia-smi
dmesg | grep -i nvidia | tail -20
systemctl status sddm
```

Expected: `nvidia-smi` shows the GPU table, `dmesg` shows no `error -1`.

---

## What Was Tried and Failed

| Approach | Result |
|---|---|
| Install `nvidia-driver` alone | Closed-source DKMS module installed, `probe error -1` on boot |
| Install `nvidia-open-kernel-dkms` alongside closed-source | Both DKMS loaded; closed-source took priority and still failed |
| `NVreg_OpenRmEnableUnsupportedGpus=1` without purging closed module | No effect, closed module still probed first |

**Lesson:** With both DKMS modules present, `update-alternatives` picks the closed-source one. You **must purge** `nvidia-kernel-dkms` before installing `nvidia-open-kernel-dkms`.

---

## Current State (as of 2026-02-21 ~18:45 CET) — Root Cause Identified

All the right packages are installed, but the loaded driver branch is too old for this GPU. Latest debugging results:

### DKMS status
```
nvidia-current-open/550.163.01, 6.12.73+deb13-amd64, x86_64: installed
```
The open module is built and registered. No closed-source `nvidia-kernel-dkms` present.

### lsmod
```
(empty — no nvidia module loaded at all)
```

### Kernel .ko files present
```
/lib/modules/6.12.73+deb13-amd64/updates/dkms/nvidia-current-open.ko.xz
/lib/modules/6.12.73+deb13-amd64/updates/dkms/nvidia-current-open-drm.ko.xz
/lib/modules/6.12.73+deb13-amd64/updates/dkms/nvidia-current-open-modeset.ko.xz
/lib/modules/6.12.73+deb13-amd64/updates/dkms/nvidia-current-open-uvm.ko.xz
/lib/modules/6.12.73+deb13-amd64/updates/dkms/nvidia-current-open-peermem.ko.xz
```

### dmesg — repeated probe failure on every modprobe attempt
```
[    8.299192] NVRM: The NVIDIA GPU 0000:3c:00.0 (PCI ID: 10de:2d04)
               NVRM: installed in this system is not supported by the
               NVRM: NVIDIA 550.163.01 driver release.
[    8.299233] nvidia 0000:3c:00.0: probe with driver nvidia failed with error -1
[    8.299260] NVRM: The NVIDIA probe routine failed for 1 device(s).
[    8.299262] NVRM: None of the NVIDIA devices were initialized.
```
This repeats ~5 times (modprobe retried by udev/systemd).

### Validated observations
- `/etc/modprobe.d/nvidia.conf` maps `nvidia` -> `nvidia-current`, and `nvidia-current` is not present.
- Direct module load bypassing that alias still fails:
  ```bash
  sudo /sbin/modprobe -v nvidia-current-open NVreg_OpenRmEnableUnsupportedGpus=1
  # -> could not insert 'nvidia_current_open': No such device
  ```
- `dmesg` after direct load confirms the real blocker is support matrix, not aliasing.
- `update-alternatives --display nvidia-kernel` reports no alternatives configured.
- Firmware tree exists (`/lib/firmware/nvidia/550.163.01/...`), so this is not a missing-GSP-blob case.
- Repositories currently enabled on this host only provide 550.163.01:
  - `trixie` / `trixie-updates` / `trixie-security`
  - no backports/experimental/unstable source configured

### sddm status
```
Active: active (running) since Sat 2026-02-21 15:11:01 CET
```
sddm is running but KDE Plasma session fails to start because nvidia module never initialises.

---

## Next Steps (Corrected)

1. **Install a newer NVIDIA branch (570+)** from a repo/source that includes Blackwell support.
   550.163.01 is definitively rejected by the kernel module for PCI ID `10de:2d04`.

2. **Keep open kernel module path**:
   - continue using `nvidia-open-kernel-dkms`
   - ensure closed `nvidia-kernel-dkms` remains purged

3. **(Optional cleanup) fix local modprobe install aliases** so `nvidia` maps to `nvidia-current-open`.
   This avoids a broken auto-load path, but it is secondary to the branch-version support issue.

4. **After upgrading branch**, re-run:
   ```bash
   sudo /sbin/modprobe -v nvidia-current-open
   sudo dmesg | grep -Ei 'nvidia|NVRM' | tail -40
   nvidia-smi
   ```
   Success criterion: no "not supported by the NVIDIA 550.163.01 driver release" style message.

---

## SSH & sudo Notes (for this machine)

- SSH alias: `a0`
- User: `es`  
- SSH login: **password-based** (no key auth set up yet) — password: `REDACTED_PASSWORD`
- sudo password: `REDACTED_PASSWORD`
- SSH ControlMaster trick (avoids re-entering password for subsequent commands):
  ```bash
  ssh -tt -o ControlMaster=yes -o ControlPath=/tmp/ssh_a0_ctl -o ControlPersist=600 a0 'echo ready'
  # then use: ssh -o ControlPath=/tmp/ssh_a0_ctl a0 '...'
  ```
- sudo without tty (via ControlMaster):
  ```bash
  ssh -o ControlPath=/tmp/ssh_a0_ctl a0 'echo "REDACTED_PASSWORD" | sudo -S -p "" bash -c "..."'
  ```
