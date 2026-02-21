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

## SSH & sudo Notes (for this machine)

- SSH alias: `a0`
- User: `es`
- Password for `sudo -i`: use the second attempt with `[REDACTED]` (trailing comma+period)
