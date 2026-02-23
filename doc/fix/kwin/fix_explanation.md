# KWin AMDGPU "Pageflip timed out" Fix

## Issue
**Symptom:** System freezes or crashes with `kwin_wayland_drm: Pageflip timed out!` errors in `dmesg` or `journalctl`.
**Cause:** A synchronization bug in the `amdgpu` kernel driver when using "Atomic Mode Setting" (AMS) on Wayland compositors like KWin. This prevents the GPU from signaling frame completion, leading to a hang.

## Fix
**Workaround:** Disable Atomic Mode Setting in KWin.

### Implementation
File: `~/.config/plasma-workspace/env/kwin_fix.sh`
Content:
```bash
export KWIN_DRM_NO_AMS=1
```

### Verification
1.  Log out and log back in (or reboot).
2.  Check if the environment variable is set:
    ```bash
    echo $KWIN_DRM_NO_AMS
    ```
    Output should be `1`.
3.  Monitor logs for recurrence of "Pageflip timed out" errors.
