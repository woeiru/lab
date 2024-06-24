## As User
### Variables

export CT_IMAGE=isfus
export CT_NAME=sfus
export CT_DIR=/home/es/lab/con/
export USER_NAME=es
export USER_PASSWORD=lernt
export SMB_USER_NAME=es
export SMB_USER_PASSWORD=lernt
export NODE_NAME=w
export SUBFOLDER=dat
export SHARENAME=dat

### Container deployment

podman build -t ${CT_IMAGE} ${CT_DIR}${CT_NAME}

mkdir /home/es/dat

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

### iptables setup

sudo iptables -L -v -n

iptables -A INPUT -p tcp --dport 1139 -j ACCEPT
iptables -A INPUT -p tcp --dport 1445 -j ACCEPT

/sbin/iptables-save > /etc/sysconfig/iptables

reboot

iptables-restore < /etc/sysconfig/iptables

### systemctl setup

podman generate systemd --new --files --name ${CT_NAME}
mv container-${CT_NAME}.service /etc/systemd/system/
systemctl daemon-reload
tu run bash
	systemctl enable container-${CT_NAME}.service
	exit
tuar

### Testing

ls -Z <path>
lsof -i -P -n
ss -tuln
smbclient -L ${NODE_NAME} -U ${SMB_USER_NAME}
smbclient //${NODE_NAME}/${SHARENAME} -U ${SMB_USER_NAME}
pdbedit -L
sudo tcpdump -i any port 139 or port 445
