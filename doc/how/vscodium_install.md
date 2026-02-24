# VSCodium Installation on Debian

This document outlines the steps to install VSCodium (the community-driven, telemetry-free distribution of VS Code) on Debian using the official VSCodium repository.

## Steps Taken

1. **Add GPG Key**: Download and add the official VSCodium GPG key to ensure package authenticity.
   ```bash
   curl -fsSL https://repo.vscodium.dev/vscodium.gpg \
     | gpg --dearmor \
     | sudo dd of=/usr/share/keyrings/vscodium.gpg
   ```

2. **Add Repository**: Add the VSCodium APT repository to the system sources.

   - Debian 13 / Ubuntu 24.04 or newer (DEB822 `.sources`):
     ```bash
     sudo curl --output-dir /etc/apt/sources.list.d -LO https://repo.vscodium.dev/vscodium.sources
     ```

   - Debian 12 / Ubuntu 23.10 or older (classic `.list`):
     ```bash
     sudo curl --output-dir /etc/apt/sources.list.d -LO https://repo.vscodium.dev/vscodium.list
     ```

3. **Update and Install**: Update package lists and install the `codium` package.
   ```bash
   sudo apt update
   sudo apt install codium
   ```

## Usage
- Launch via terminal: `codium`
- Updates are handled automatically via `sudo apt upgrade`.
