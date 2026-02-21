# Debian KDE Plasma + NVIDIA RTX 5060 Ti Fix

When installing Debian with a newer NVIDIA GPU (like the RTX 5060 Ti), the default `nouveau` open-source driver may not fully support the card yet, resulting in a black screen or KDE Plasma failing to start.

To fix this, you must install the proprietary NVIDIA drivers from the `non-free` repository. 

Here are the step-by-step instructions to apply the fix:

1. **Add `contrib` and `non-free` to your APT sources**:
   Edit `/etc/apt/sources.list` and append `contrib non-free` to the end of the `deb` and `deb-src` lines. E.g.,
   ```bash
   sudo sed -i -E 's/main.*non-free-firmware/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
   ```

2. **Update the package list**:
   ```bash
   sudo apt-get update
   ```

3. **Install the NVIDIA Driver and required firmware**:
   ```bash
   sudo apt-get install -y linux-headers-amd64 nvidia-driver firmware-misc-nonfree
   ```
   *Note: This will automatically blacklist the `nouveau` driver and rebuild the Initramfs.*

4. **Reboot the system**:
   ```bash
   sudo reboot
   ```

After rebooting, KDE Plasma will start correctly using the proprietary NVIDIA drivers.
