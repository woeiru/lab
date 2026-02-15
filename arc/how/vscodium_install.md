# VSCodium Installation on Debian

This document outlines the steps taken to install VSCodium (the community-driven, telemetry-free distribution of VS Code) on this Debian system.

## Steps Taken

1.  **Add GPG Key**: Downloaded and added the official VSCodium GPG key to ensure package authenticity.
    ```bash
    wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
    ```

2.  **Add Repository**: Added the VSCodium APT repository to the system sources.
    ```bash
    echo 'deb [ arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
    ```

3.  **Update and Install**: Updated the package lists and installed the `codium` package.
    ```bash
    sudo apt update
    sudo apt install codium
    ```

## Usage
- Launch via terminal: `codium`
- Updates are handled automatically via `sudo apt upgrade`.
