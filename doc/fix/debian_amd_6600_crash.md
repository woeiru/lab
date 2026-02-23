# AMDGPU Wayland Crash Analysis

## Incident
The system experienced a hard crash / freeze around Friday, Feb 20 at 23:54 which ended abruptly on Saturday, Feb 21 at 00:33.

## Root Cause
The `journalctl` logs just prior to the crash indicated repeated pageflip timeouts from the GPU driver:
```text
kwin_wayland_wrapper[1360]: kwin_wayland_drm: Pageflip timed out! This is a bug in the amdgpu kernel driver
```

This error is a known bug regarding the `amdgpu` kernel driver's interaction with the KDE Plasma Wayland compositor (KWin). It primarily affects AMD graphics cards (such as the Radeon RX 6600 present in this system).

**Cause Details:** A synchronization bug in the `amdgpu` kernel driver when using "Atomic Mode Setting" (AMS) on Wayland compositors like KWin. This prevents the GPU from signaling frame completion, leading to a hang.

## Potential Workarounds
While waiting for a permanent fix in the kernel or Mesa drivers, the following steps can be taken to mitigate the issue:

### 1. Disable Atomic Mode Setting in KWin (Recommended Fix)
This workaround prevents the synchronization bug by disabling AMS in KWin.

**Implementation:**
Create a script at `~/.config/plasma-workspace/env/kwin_fix.sh` with the following content:
```bash
export KWIN_DRM_NO_AMS=1
```

**Verification:**
1. Log out and log back in (or reboot).
2. Check if the environment variable is set:
   ```bash
   echo $KWIN_DRM_NO_AMS
   ```
   Output should be `1`.
3. Monitor logs for recurrence of "Pageflip timed out" errors.

### 2. Disable Variable Refresh Rate (VRR / FreeSync)
This is a frequent trigger on modern AMD GPUs.
* Go to System Settings -> Display & Monitor.
* Set Adaptive Sync or Variable Refresh Rate to **Never**.

### 3. Disable KWin's Hardware Cursor
* Add `KWIN_FORCE_SW_CURSOR=1` to `/etc/environment` and reboot.

### 4. Switch to X11 Session
The bug is specific to Wayland.
* Log out and change the SDDM session type from "Plasma (Wayland)" to "Plasma (X11)".

### 5. Tweak Kernel Boot Parameters
* Add `amdgpu.dcdebugmask=0x10` to the kernel boot parameters via GRUB.

### 6. Lock GPU Power State
* Use a tool like LACT (Linux AMDGPU Controller) to set Performance Level to `Manual` and Power Profile Mode to `3D_FULL_SCREEN` to prevent dynamical low/high power state switches.
