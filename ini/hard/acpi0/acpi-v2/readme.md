# Custom RPM for Wakeup Fix on Immutable Systems

This project demonstrates how to create a custom RPM package to add files and services to an immutable filesystem, such as those used in Fedora Silverblue/Kinoite, to fix wakeup issues.

## Prerequisites

- An immutable system (e.g., Fedora Silverblue, CoreOS)
- Root access to your system
- `toolbox` installed
- `rpm-build` and `rpmdevtools` (will be installed in the toolbox)
- `selinux-policy-devel` (will be installed in the toolbox)

## Repository Contents

- `depl.sh`: Deployment script that generates necessary files
- `disable-devices-as-wakeup.sh`: Script to disable wakeup devices

## Getting Started

1. Clone this repository:

```bash
git clone https://github.com/yourusername/wakeup-fix.git
cd wakeup-fix
```

2. Run the deployment script:

```bash
bash depl.sh
```

This script will create the following files:
- `my-wakeup-fix.spec`: RPM specification file
- `disable_wakeup.te`: SELinux policy file

## Building the RPM

1. Create and enter a toolbox for building the RPM:

```bash
toolbox create -c rpm-build-box
toolbox enter -c rpm-build-box
```

2. Inside the toolbox, mount the host's root directory:

```bash
sudo mkdir /mnt/host-root
sudo mount -o bind /var/roothome /mnt/host-root
```

3. Navigate to your project directory:

```bash
cd /mnt/host-root/path/to/wakeup-fix
```

4. Install necessary tools:

```bash
sudo dnf install rpm-build rpmdevtools selinux-policy-devel
```

5. Set up the RPM build directory structure:

```bash
rpmdev-setuptree
```

6. Copy your spec file and source files:

```bash
cp my-wakeup-fix.spec ~/rpmbuild/SPECS/
cp disable-devices-as-wakeup.sh disable_wakeup.te ~/rpmbuild/SOURCES/
```

7. Build the RPM:

```bash
rpmbuild -ba ~/rpmbuild/SPECS/my-wakeup-fix.spec
```

8. Copy the built RPM to the host system:

```bash
cp ~/rpmbuild/RPMS/x86_64/my-wakeup-fix-1.0-1.fc*.x86_64.rpm /mnt/host-root/path/to/wakeup-fix
```

9. Exit the toolbox:

```bash
exit
```

## Installing the RPM

On the host system:

1. Install the RPM:

```bash
sudo rpm-ostree install ~/path/to/wakeup-fix/my-wakeup-fix-1.0-1.fc*.x86_64.rpm
```

2. Reboot the system:

```bash
sudo systemctl reboot
```

## Verification

After rebooting, verify that the wakeup fix is applied:

```bash
cat /sys/devices/**/power/wakeup
```

Most devices should show as "disabled".

## Troubleshooting

- If the RPM build fails, check the spec file and ensure all paths are correct.
- If SELinux issues occur, review the `disable_wakeup.te` file and ensure it's correctly packaged in the RPM.
- If devices are still waking up the system, check the contents and permissions of the `disable-devices-as-wakeup.sh` script.
