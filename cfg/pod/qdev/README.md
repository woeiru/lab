# Qdevice Setup

## Navigation
- [Repository Root](../../../README.md)
- [Documentation Hub](../../../doc/README.md)

## Purpose
This directory contains Podman-based setup material for a Proxmox qdevice/qnetd host used to stabilize cluster quorum.

## Quick Start
# 1) Build qdevice image from this directory
cd "$LAB_DIR/cfg/pod/qdev"
sudo podman build . -t iq --format docker

# 2) Prepare persistent config mount
sudo mkdir -p /etc/corosync
sudo chown 701:701 /etc/corosync

# 3) Run qdevice container
sudo podman run -d --name=qd --cap-drop=ALL --privileged \
  -p 22:22 -p 5403:5403 \
  -v /etc/corosync:/etc/corosync localhost/iq

## Structure
- `Containerfile` and local assets: image/runtime definition.
- `README.md`: operational entrypoint for qdevice deployment.

## Common Tasks
- Prepare static IP and networking before deployment.
- Build and run qdevice container, then integrate with Proxmox cluster nodes.
- Use reinstall/cleanup flow when stale qdevice state blocks reconfiguration.

## Troubleshooting
- Validate port availability (`22`, `5403`) and host firewall/SELinux behavior.
- Ensure `corosync-qdevice` is installed on all Proxmox nodes.
- If setup becomes inconsistent, follow the cleanup/reinstall sequence from the full runbook.

## Related Docs
- [Qdevice Runbook Deep Dive (full procedure)](../../../doc/iac/qdevice-runbook-deep-dive.md)
- [Infrastructure as Code Docs](../../../doc/iac/README.md)
- [Repository Root](../../../README.md)
