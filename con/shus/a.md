### Variables

export CT_IMAGE=ishus
export CT_NAME=shus

export CT_DIR=/root/lab/con/

export USER_NAME=
export USER_PASSWORD=
export SMB_USER_NAME=
export SMB_USER_PASSWORD=

export NODE_NAME=w

export SUBFOLDER=dat
export SHARENAME=dat

### Container deployment

podman build -t ${CT_IMAGE} ${CT_DIR}${CT_NAME}

podman run -d \
    --name ${CT_NAME} \
    -p 1139:1139 -p 1445:1445 \
    -e UID=1000 \
    -e GID=1000 \
    -e USERNAME=${SMB_USER_NAME} \
    -e PASSWORD=${SMB_USER_PASSWORD} \
    -v /home/${USER_NAME}/${SUBFOLDER}:/home/${USER_NAME}/${SUBFOLDER}:z \
    ${CT_IMAGE}

podman start ${CT_NAME}

### systemctl setup

podman generate systemd --new --files --name ${CT_NAME}
mv container-${CT_NAME}.service /etc/systemd/system/
systemctl daemon-reload
tu run bash
	systemctl enable container-${CT_NAME}.service
	exit
tuar

### iptables setup

iptables -L -v -n

iptables -A INPUT -p tcp --dport 139 -j ACCEPT
iptables -A INPUT -p tcp --dport 445 -j ACCEPT
/sbin/iptables-save > /etc/sysconfig/iptables

iptables-restore < /etc/sysconfig/iptables


### for rootless mode

# Redirect incoming traffic from port 139 to the container's port 1139
sudo iptables -t nat -A PREROUTING -p tcp --dport 139 -j DNAT --to-destination 192.168.178.110:1139

# Redirect incoming traffic from port 445 to the container's port 1445
sudo iptables -t nat -A PREROUTING -p tcp --dport 445 -j DNAT --to-destination 192.168.178.110:1445

# Perform source NAT (MASQUERADE) for outgoing traffic from the container
sudo iptables -t nat -A POSTROUTING -p tcp -d 192.168.178.110 --dport 1139 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -p tcp -d 192.168.178.110 --dport 1445 -j MASQUERADE


### Testing

ls -Z <path>
lsof -i -P -n
ss -tuln
smbclient -L ${NODE_NAME} -U ${SMB_USER_NAME}
smbclient //${NODE_NAME}/${SHARENAME} -U ${SMB_USER_NAME}
pdbedit -L

