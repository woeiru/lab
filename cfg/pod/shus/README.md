# SHUS Pod Setup

## Navigation
- [Repository Root](../../../README.md)
- [Documentation Hub](../../../doc/README.md)

## Purpose
`cfg/pod/shus/` provides runbook commands to build and run the SHUS SMB container in either rootful or rootless Podman mode.

## Prerequisites
- Podman installed and usable on the target host.
- `iptables` tooling available when applying firewall/NAT rules.
- Correct container source path (`CT_DIR`) for your host.
- SELinux policy behavior understood on your host before changing enforcement state.

## Security Notes
- Do not commit real credentials in command history or shell init files.
- Replace placeholder values below with environment-specific secrets.
- Prefer using an env file or exported secure session variables instead of hardcoded passwords.

## Quick Start
Choose one mode and run the corresponding section:
- `ROOTFUL SETUP`: direct SMB ports (`139`, `445`) in the container mapping.
- `ROOTLESS SETUP`: high host ports (`1139`, `1445`) plus NAT/forwarding rules.

## ROOTFUL SETUP
### Variables

```bash
export CT_NAME=shus
export CT_IMAGE=ishus
export CT_DIR=/root/lab/con/
export USER_NAME=<local_user>
export SMB_USER_NAME=<smb_user>
export SMB_USER_PASSWORD=<smb_password>
export NODE_NAME=<node_name>
export SUBFOLDER=dat
export SHARENAME=dat
```

### Container deployment

```bash
podman build -t ${CT_IMAGE} ${CT_DIR}${CT_NAME}

mkdir -p /home/${USER_NAME}/${SUBFOLDER}

podman run -d \
  --name ${CT_NAME} \
  -p 139:139 \
  -p 445:445 \
  -e UID=1000 \
  -e GID=1000 \
  -e USERNAME=${SMB_USER_NAME} \
  -e PASSWORD=${SMB_USER_PASSWORD} \
  -v /home/${USER_NAME}/${SUBFOLDER}:/home/${USER_NAME}/${SUBFOLDER}:z \
  ${CT_IMAGE}

podman start ${CT_NAME}
```

### Firewall persistence

```bash
sudo iptables -L -v -n

iptables -A INPUT -p tcp --dport 1139 -j ACCEPT
iptables -A INPUT -p tcp --dport 1445 -j ACCEPT

/sbin/iptables-save > /etc/sysconfig/iptables

reboot

iptables-restore < /etc/sysconfig/iptables
```

## ROOTLESS SETUP
### Variables

```bash
export CT_NAME=shus
export CT_IMAGE=ishus
export CT_DIR=/home/es/lab/con/
export USER_NAME=<local_user>
export SMB_USER_NAME=<smb_user>
export SMB_USER_PASSWORD=<smb_password>
export NODE_NAME=<node_name>
export SUBFOLDER=dat
export SHARENAME=dat
```

### Container deployment

```bash
sudo setenforce 0
podman build -t ${CT_IMAGE} ${CT_DIR}${CT_NAME}
sudo setenforce 1

mkdir -p /home/${USER_NAME}/${SUBFOLDER}

podman run -d \
  --name ${CT_NAME} \
  -p 1139:139 \
  -p 1445:445 \
  -e UID=1000 \
  -e GID=1000 \
  -e USERNAME=${SMB_USER_NAME} \
  -e PASSWORD=${SMB_USER_PASSWORD} \
  -v /home/${USER_NAME}/${SUBFOLDER}:/home/${USER_NAME}/${SUBFOLDER}:z \
  ${CT_IMAGE}

podman start ${CT_NAME}
```

### NAT and firewall setup

```bash
sudo iptables -L -v -n

sudo iptables -t nat -A PREROUTING -p tcp --dport 139 -j DNAT --to-destination 192.168.178.110:1139
sudo iptables -t nat -A PREROUTING -p tcp --dport 445 -j DNAT --to-destination 192.168.178.110:1445
sudo iptables -t nat -A POSTROUTING -p tcp -d 192.168.178.110 --dport 1139 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -p tcp -d 192.168.178.110 --dport 1445 -j MASQUERADE

sudo iptables -A INPUT -p tcp --dport 1139 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 1445 -j ACCEPT

sudo /sbin/iptables-save > /etc/sysconfig/iptables

reboot

iptables-restore < /etc/sysconfig/iptables
```

### systemd service setup

```bash
podman generate systemd --new --files --name ${CT_NAME}
sudo mv container-${CT_NAME}.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable container-${CT_NAME}.service
```

### Testing

```bash
ls -Z <path>
lsof -i -P -n
ss -tuln
smbclient -L ${NODE_NAME} -U ${SMB_USER_NAME}
smbclient //${NODE_NAME}/${SHARENAME} -U ${SMB_USER_NAME}
pdbedit -L
sudo tcpdump -i any port 139 or port 445
```

## Common Tasks
- Set mode-specific variables for the target host and security context.
- Build and start the container, then validate ports and SMB connectivity.
- Persist firewall/NAT rules if your host resets them on reboot.

## Troubleshooting
- If SMB is unreachable, verify host port mappings and NAT rules match your chosen mode.
- If SELinux blocks access, inspect labels and re-check any temporary enforcement changes.
- If service does not auto-start, verify generated unit file location and `systemctl` enablement.

## Related Docs
- [Configuration Root](../../README.md)
- [Qdevice Pod Setup](../qdev/README.md)
- [Repository Root](../../../README.md)
- [Documentation Hub](../../../doc/README.md)
