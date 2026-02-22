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

## Current State (as of 2026-02-21 ~19:25 CET) — Debian Packages Still Too Old

All the right packages are installed, but the available Debian branches on this host are still too old for this GPU.
Both tested branches (`550.163.01` and `555.58.02`) reject PCI ID `10de:2d04`.

### DKMS status
```
nvidia-current-open/555.58.02, 6.12.73+deb13-amd64, x86_64: installed
```
The open module is built and registered. No closed-source `nvidia-kernel-dkms` present.

### lsmod
```
nouveau loaded; no nvidia module loaded
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
               NVRM: NVIDIA 555.58.02 driver release.
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
- Firmware tree exists (`/lib/firmware/nvidia/555.58.02/...`), so this is not a missing-GSP-blob case.
- Current installed versions on host:
  - `nvidia-driver`: `555.58.02-2`
  - `nvidia-open-kernel-dkms`: `555.58.02-2`
  - `firmware-nvidia-gsp`: `555.58.02-2`

### sddm status
```
Active: active (running) since Sat 2026-02-21 15:11:01 CET
```
sddm is running but KDE Plasma session fails to start because nvidia module never initialises.

---

## Next Steps (Corrected)

1. **Install a newer NVIDIA branch (570+)** from a source not currently in Debian repos configured on this host.
   `555.58.02` is still rejected for PCI ID `10de:2d04`.

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
   Success criterion: no "not supported by the NVIDIA ... driver release" message.

---

## Resolution: NVIDIA 580.126.09 Upstream Installer

**Confirmed:** NVIDIA `580.126.09` (current upstream latest) explicitly lists `GeForce RTX 5060 Ti` (PCI ID `2D04`) in its supported chips.
Source: `https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt` → `580.126.09`

### Pre-flight (from workstation or via SSH to `a0`)

```bash
# 1. Purge ALL Debian-packaged NVIDIA drivers to avoid conflicts
sudo apt-get purge -y 'nvidia-*' 'libnvidia-*' 'xserver-xorg-video-nvidia'
sudo apt-get autoremove -y

# 2. Remove the experimental/sid APT sources we added previously (no longer needed)
sudo rm -f /etc/apt/sources.list.d/nvidia-next.list
sudo rm -f /etc/apt/preferences.d/99-nvidia-experimental.pref
sudo apt-get update

# 3. Install build dependencies for the .run installer
sudo apt-get install -y linux-headers-$(uname -r) build-essential pkg-config libglvnd-dev
```

### Download and install

```bash
# 4. Download the upstream driver
cd /tmp
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/580.126.09/NVIDIA-Linux-x86_64-580.126.09.run

# 5. Stop the display manager so X/Wayland releases the GPU
sudo systemctl stop sddm

# 6. Unload nouveau if still loaded
sudo modprobe -r nouveau

# 7. Run the installer
#    -M open  : build the open-source kernel module (required for Blackwell)
#    --dkms   : register with DKMS for automatic rebuild on kernel updates
#    --silent : non-interactive (remove for interactive prompts)
sudo bash NVIDIA-Linux-x86_64-580.126.09.run -M open --dkms --silent
```

> [!NOTE]
> If Secure Boot is enabled, the installer will prompt for module signing keys.
> Either enroll a MOK beforehand or pass `--module-signing-secret-key` / `--module-signing-public-key`.
> Alternatively, if Secure Boot is not required, disable it in UEFI firmware.

### Post-install verification

```bash
# 8. Verify the module loads
sudo modprobe nvidia
dmesg | grep -Ei 'nvidia|NVRM' | tail -20

# 9. Check nvidia-smi
nvidia-smi

# 10. Restart the display manager
sudo systemctl start sddm
```

**Success criteria:**
- `dmesg` shows no "not supported" messages
- `nvidia-smi` shows the RTX 5060 Ti with driver `580.126.09`
- `sddm` starts and KDE Plasma session loads

### Rollback (if needed)

```bash
# The upstream installer includes its own uninstaller:
sudo nvidia-uninstall
# Then reinstall Debian-packaged nouveau:
sudo apt-get install -y xserver-xorg-video-nouveau
sudo systemctl start sddm
```

---

## Execution Log (2026-02-21, performed)

### Goal
Upgrade only the NVIDIA stack using Debian package management (pinned), avoiding full-system sid/experimental upgrades.

### 1) Added temporary extra APT sources
Created `/etc/apt/sources.list.d/nvidia-next.list` on `a0` with:
```bash
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
deb http://deb.debian.org/debian experimental main contrib non-free non-free-firmware
```

### 2) Added pinning so only NVIDIA packages can come from experimental
Created `/etc/apt/preferences.d/99-nvidia-experimental.pref`:
```bash
Package: *
Pin: release a=experimental
Pin-Priority: 1

Package: *nvidia*
Pin: release a=experimental
Pin-Priority: 990
```

### 3) Validated availability
`apt-cache madison` showed:
- `sid`: `550.163.01-4`
- `experimental`: `555.58.02-2`

No `570+` package available from currently queried Debian repos.

### 4) Ran upgrade
Executed:
```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install nvidia-driver nvidia-open-kernel-dkms firmware-nvidia-gsp
```

During the first attempt, package install was interrupted and left `nvidia-legacy-check` half-installed (`iHR`), causing dependency breakage.
Recovery steps:
```bash
sudo dpkg --configure -a
sudo DEBIAN_FRONTEND=noninteractive apt-get -y --reinstall install nvidia-legacy-check
sudo dpkg --configure -a
```

DKMS then built and installed:
```text
nvidia-current-open/555.58.02, 6.12.73+deb13-amd64, x86_64: installed
```

### 5) Verification after upgrade
Direct probe still fails:
```bash
sudo /sbin/modprobe -v nvidia-current-open NVreg_OpenRmEnableUnsupportedGpus=1
# modprobe: ERROR: could not insert 'nvidia_current_open': No such device
```

Kernel log still reports unsupported device on 555:
```text
NVRM: The NVIDIA GPU 0000:3c:00.0 (PCI ID: 10de:2d04)
NVRM: installed in this system is not supported by the
NVRM: NVIDIA 555.58.02 driver release.
```

`nvidia-smi`:
```text
NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver.
```

### Conclusion
Pinned Debian package path was executed successfully and upgraded the full NVIDIA stack to `555.58.02-2`, but this branch still does not support this RTX 5060 Ti PCI ID on this system.
Next required step is a newer branch (`570+`), likely via NVIDIA upstream installer or a newer packaging source.

---

## Execution Log (2026-02-22, performed) — RESOLVED

### Goal
Install NVIDIA upstream driver `580.126.09` via `.run` installer, replacing the Debian-packaged `555.58.02` that rejected PCI ID `10de:2d04`.

### 1) Configured NOPASSWD sudo for remote scripting
```bash
su -c 'echo "es ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/es && chmod 440 /etc/sudoers.d/es'
```

### 2) Purged all Debian-packaged NVIDIA drivers
```bash
sudo apt-get purge -y 'nvidia-*' 'libnvidia-*' 'xserver-xorg-video-nvidia'
sudo apt-get autoremove -y
```

### 3) Removed stale experimental/sid APT sources
```bash
sudo rm -f /etc/apt/sources.list.d/nvidia-next.list
sudo rm -f /etc/apt/preferences.d/99-nvidia-experimental.pref
sudo apt-get update
```

### 4) Installed build dependencies
```bash
sudo apt-get install -y linux-headers-$(uname -r) build-essential pkg-config libglvnd-dev dkms
```

### 5) Downloaded upstream driver
```bash
wget -q https://us.download.nvidia.com/XFree86/Linux-x86_64/580.126.09/NVIDIA-Linux-x86_64-580.126.09.run
# 379MB downloaded to /tmp/
```

### 6) Stopped display manager and ran installer
```bash
sudo systemctl stop sddm
sudo modprobe -r nouveau
sudo bash /tmp/NVIDIA-Linux-x86_64-580.126.09.run -M open --dkms --silent
```
- Installer completed successfully.
- Warning about 32-bit compat libs not installed (harmless — no `lib32` destination configured).
- Note: initial attempt with `--open-kernel-module` flag failed; correct flag is `-M open` (or `--kernel-module-type=open`).

### 7) Verification — all pass
```
$ sudo modprobe nvidia   # OK — no errors

$ nvidia-smi
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.126.09             Driver Version: 580.126.09     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
|   0  NVIDIA GeForce RTX 5060 Ti     Off |   00000000:3C:00.0 Off |                  N/A |
| 39%   30C    P0             20W /  180W |       0MiB /  16311MiB |      2%      Default |
+-----------------------------------------+------------------------+----------------------+

$ sudo dmesg | grep NVRM
NVRM: loading NVIDIA UNIX Open Kernel Module for x86_64  580.126.09  Release Build

$ systemctl is-active sddm
active
```

### Conclusion
**FIXED.** The RTX 5060 Ti (`10de:2d04`, GB206 Blackwell) is fully operational with NVIDIA `580.126.09` open kernel module on Debian 13 Trixie (kernel `6.12.73+deb13-amd64`). KDE Plasma / sddm starts correctly.

The root cause was that no Debian-packaged NVIDIA driver branch (up to `555.58.02`) included this PCI ID in its support matrix. The upstream `580.126.09` `.run` installer was required.

---

## SSH & sudo Notes (for this machine)

- SSH alias: `a0`
- User: `es`
- SSH login: **key-based** — use `ssh-copy-id a0` to install your public key; never store passwords in files or git
- SSH ControlMaster trick (avoids repeated handshakes for scripted commands):
  ```bash
  ssh -o ControlMaster=auto -o ControlPath=/tmp/ssh_a0_ctl -o ControlPersist=600 a0 'echo ready'
  # subsequent commands reuse the socket:
  ssh -o ControlPath=/tmp/ssh_a0_ctl a0 '...'
  ```
- Non-interactive sudo via ControlMaster:
  ```bash
  # With NOPASSWD sudo configured on a0 (preferred):
  ssh -o ControlPath=/tmp/ssh_a0_ctl a0 'sudo bash -c "..."'
  ```
