<!--
#######################################################################
# PipeWire Audio Issues Fix Guide - Technical Reference
#######################################################################
# File: /home/es/lab/doc/fix/audioroot.md
# Description: Comprehensive troubleshooting guide for resolving common
#              PipeWire audio issues encountered on Fedora systems with
#              detailed diagnostic and resolution procedures.
#
# Document Purpose:
#   Provides systematic troubleshooting procedures for diagnosing
#   and resolving PipeWire audio configuration problems, ensuring
#   functional audio setup in Fedora-based lab environments.
#
# Technical Scope:
#   - PipeWire audio subsystem troubleshooting
#   - Fedora-specific audio configuration procedures
#   - Root privilege operations for system repair
#   - Audio service management and diagnostics
#
# Target Audience:
#   System administrators, desktop support technicians, and users
#   experiencing PipeWire audio issues requiring systematic
#   troubleshooting and configuration repair procedures.
#
# Dependencies:
#   - Fedora operating system
#   - PipeWire audio framework
#   - Root administrative privileges
#######################################################################
-->

# PipeWire Audio Issues Fix Guide

## Problem

This guide addresses common PipeWire audio issues encountered on Fedora systems. It provides a comprehensive set of instructions to diagnose and resolve these problems, ensuring a functional audio setup.

## System Details

-   **Operating System:** Fedora
-   **Required Access:** Root privileges

## Troubleshooting Steps and Solution

The following steps outline the process for fixing PipeWire audio issues:

1.  **Ensure PipeWire and related packages are installed**
    ```bash
    sudo dnf install pipewire pipewire-pulseaudio wireplumber alsa-plugins-pipewire
    ```

2.  **Modify PipeWire PulseAudio service file**
    This step ensures the service runs correctly for the user.
    ```bash
    sudo cp /usr/lib/systemd/user/pipewire-pulse.service /etc/systemd/user/
    sudo sed -i '/ConditionUser/d' /etc/systemd/user/pipewire-pulse.service
    ```

3.  **Reload systemd and restart PipeWire services**
    Apply the changes and restart the necessary audio services.
    ```bash
    systemctl --user daemon-reload
    systemctl --user restart pipewire pipewire-pulse wireplumber
    ```

4.  **Verify service status**
    Check that all services are active and running without errors.
    ```bash
    systemctl --user status pipewire pipewire-pulse wireplumber
    ```

5.  **Check PulseAudio compatibility layer**
    Ensure the PipeWire replacement for PulseAudio is active.
    ```bash
    ps aux | grep pipewire-pulse
    ```

6.  **Verify PulseAudio socket**
    The presence of the `native` socket indicates correct setup.
    ```bash
    ls -l /run/user/$UID/pulse/
    ```

7.  **Verify PulseAudio symlink**
    If the symlink from `pulseaudio` to `pipewire-pulse` doesn't exist, create it.
    ```bash
    ls -l /usr/bin/pulseaudio
    ```
    If needed:
    ```bash
    sudo ln -s /usr/bin/pipewire-pulse /usr/bin/pulseaudio
    ```

8.  **Install ALSA PipeWire plugin (if not already done)**
    This plugin is crucial for ALSA applications to work with PipeWire.
    ```bash
    sudo dnf install alsa-plugins-pipewire
    ```

9.  **Test audio**
    Use a standard sound file to test audio output.
    ```bash
    paplay /usr/share/sounds/alsa/Front_Center.wav
    ```

10. **Check PipeWire configuration**
    Review configuration files for any obvious misconfigurations.
    ```bash
    cat /etc/pipewire/pipewire.conf
    cat /etc/pipewire/pipewire-pulse.conf
    ```

11. **Install additional PipeWire plugins if needed**
    For example, for camera support.
    ```bash
    sudo dnf install pipewire-plugin-libcamera
    ```

12. **Restart PipeWire services after changes**
    Always restart services if configuration files or packages are changed.
    ```bash
    systemctl --user restart pipewire pipewire-pulse wireplumber
    ```

13. **Reboot system if issues persist**
    A full reboot can sometimes resolve lingering issues.
    ```bash
    sudo reboot
    ```

### Further Troubleshooting

If the above steps do not resolve the audio issues, proceed with these additional troubleshooting measures:

1.  **Check PipeWire logs**
    Look for errors or warnings related to PipeWire.
    ```bash
    journalctl --user -xe | grep -i pipewire
    ```

2.  **Verify audio devices are detected**
    List available audio output (sinks) and input (sources).
    ```bash
    pactl list short sinks
    pactl list short sources
    ```

3.  **Check for conflicting services**
    Ensure PulseAudio is not running alongside PipeWire, as this can cause conflicts. Stop and mask the PulseAudio services if they are active.
    ```bash
    systemctl --user stop pulseaudio.socket pulseaudio.service
    systemctl --user mask pulseaudio.socket pulseaudio.service
    ```

4.  **Reinstall PipeWire and related packages**
    This can fix issues caused by corrupted files or improper installation.
    ```bash
    sudo dnf reinstall pipewire pipewire-pulseaudio wireplumber
    ```

5.  **Check SELinux status**
    If SELinux is in "Enforcing" mode, it might interfere with PipeWire.
    ```bash
    getenforce
    ```
    If "Enforcing", consider temporarily setting it to permissive for testing.
    ```bash
    sudo setenforce 0
    ```
    *Note: Remember to revert this change (`sudo setenforce 1`) after testing, as disabling SELinux can have security implications.*

6.  **Verify user permissions**
    Ensure your user is part of the `audio` group.
    ```bash
    groups $USER | grep audio
    ```
    If not, add the user to the `audio` group and then log out and log back in.
    ```bash
    sudo usermod -aG audio $USER
    ```

7.  **Check for conflicting ALSA configurations**
    Custom ALSA configuration files (`~/.asoundrc` or `/etc/asound.conf`) might interfere with PipeWire.
    ```bash
    ls -l ~/.asoundrc /etc/asound.conf
    ```
    If these files exist, consider renaming or removing them for testing purposes.

## Conclusion

By systematically following the installation, configuration, verification, and troubleshooting steps outlined in this guide, most PipeWire audio issues on Fedora can be resolved. The key is to ensure all components are correctly installed, services are running, and there are no conflicts with older audio systems like PulseAudio or custom ALSA configurations. Regular testing after significant changes helps isolate the source of any problems. If issues persist, consulting logs and community forums or filing a bug report are recommended next steps.

## Additional Notes
- Running audio services as root is generally not recommended for security reasons. Consider setting up a regular user account for daily use.
- If problems persist after trying all these steps, consider filing a bug report with your distribution or the PipeWire project.

Remember to test audio functionality after each significant change to isolate the source of any issues.
