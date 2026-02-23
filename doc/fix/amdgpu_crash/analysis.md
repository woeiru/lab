# AMDGPU Wayland Crash Analysis

## Incident
The system experienced a hard crash / freeze around Friday, Feb 20 at 23:54 which ended abruptly on Saturday, Feb 21 at 00:33.

## Root Cause
The `journalctl` logs just prior to the crash indicated repeated pageflip timeouts from the GPU driver:
```text
kwin_wayland_wrapper[1360]: kwin_wayland_drm: Pageflip timed out! This is a bug in the amdgpu kernel driver
```

This error is a known bug regarding the `amdgpu` kernel driver's interaction with the KDE Plasma Wayland compositor (KWin). It primarily affects AMD graphics cards (such as the Radeon RX 6600 present in this system).

## Potential Workarounds
While waiting for a permanent fix in the kernel or Mesa drivers, the following steps can be taken to mitigate the issue:

### 1. Disable Variable Refresh Rate (VRR / FreeSync)
This is a frequent trigger on modern AMD GPUs.
* Go to System Settings -> Display & Monitor.
* Set Adaptive Sync or Variable Refresh Rate to **Never**.

### 2. Disable KWin's Hardware Cursor
* Add `KWIN_FORCE_SW_CURSOR=1` to `/etc/environment` and reboot.

### 3. Switch to X11 Session
The bug is specific to Wayland.
* Log out and change the SDDM session type from "Plasma (Wayland)" to "Plasma (X11)".

### 4. Tweak Kernel Boot Parameters
* Add `amdgpu.dcdebugmask=0x10` to the kernel boot parameters via GRUB.

### 5. Lock GPU Power State
* Use a tool like LACT (Linux AMDGPU Controller) to set Performance Level to `Manual` and Power Profile Mode to `3D_FULL_SCREEN` to prevent dynamical low/high power state switches.
