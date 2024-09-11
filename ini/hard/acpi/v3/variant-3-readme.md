# Variant 3: Custom Overlay for Immutable Filesystems

This method demonstrates how to create a custom overlay to add files and services to an immutable filesystem, such as those used in Fedora Silverblue/Kinoite, without using RPM packages.

## Prerequisites

- Root access to your system
- SELinux tools installed (`checkmodule`, `semodule_package`)
- `rpm-ostree` installed

## Files

Ensure you have the following files in your working directory:

- `disable-devices-as-wakeup.sh`
- `disable-devices-as-wakeup.service`
- `disable_wakeup.te`

## Steps

1. Create the directory structure for the overlay:

```bash
sudo mkdir -p /etc/rpm-ostree/state/my-wakeup-fix/usr/local/bin
sudo mkdir -p /etc/rpm-ostree/state/my-wakeup-fix/usr/share/selinux/packages
sudo mkdir -p /etc/rpm-ostree/state/my-wakeup-fix/etc/systemd/system
```

2. Copy the files to the overlay structure:

```bash
sudo cp disable-devices-as-wakeup.sh /etc/rpm-ostree/state/my-wakeup-fix/usr/local/bin/
sudo cp disable_wakeup.te /etc/rpm-ostree/state/my-wakeup-fix/usr/share/selinux/packages/
sudo cp disable-devices-as-wakeup.service /etc/rpm-ostree/state/my-wakeup-fix/etc/systemd/system/
```

3. Compile and package the SELinux policy:

```bash
sudo checkmodule -M -m -o /etc/rpm-ostree/state/my-wakeup-fix/usr/share/selinux/packages/disable_wakeup.mod /etc/rpm-ostree/state/my-wakeup-fix/usr/share/selinux/packages/disable_wakeup.te
sudo semodule_package -o /etc/rpm-ostree/state/my-wakeup-fix/usr/share/selinux/packages/disable_wakeup.pp -m /etc/rpm-ostree/state/my-wakeup-fix/usr/share/selinux/packages/disable_wakeup.mod
```

4. Create a script to load the SELinux policy:

```bash
sudo tee /etc/rpm-ostree/state/my-wakeup-fix/usr/local/bin/load-selinux-policy.sh << EOF
#!/bin/bash
semodule -i /usr/share/selinux/packages/disable_wakeup.pp
EOF

sudo chmod +x /etc/rpm-ostree/state/my-wakeup-fix/usr/local/bin/load-selinux-policy.sh
```

5. Create a systemd service to load the SELinux policy:

```bash
sudo tee /etc/rpm-ostree/state/my-wakeup-fix/etc/systemd/system/load-selinux-policy.service << EOF
[Unit]
Description=Load custom SELinux policy
Before=disable-devices-as-wakeup.service

[Service]
ExecStart=/usr/local/bin/load-selinux-policy.sh
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF
```

6. Track the changes using `rpm-ostree`:

```bash
sudo rpm-ostree initramfs-etc --track=/etc/rpm-ostree/state/my-wakeup-fix
```

7. Reboot the system:

```bash
sudo systemctl reboot
```

## Verification

After rebooting, verify the status of the services:

```bash
systemctl status disable-devices-as-wakeup.service
systemctl status load-selinux-policy.service
```

This method allows you to add custom files and services to an immutable filesystem without using RPM packages, maintaining the benefits of an immutable system architecture while allowing for necessary customizations.
