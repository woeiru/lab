## Variables
export CT_DIR=/root/lab/con/
export USER_NAME=xo
export USER_PASSWORD=password
export CT_NAME=shxo
export CT_IMAGE=ishxo
export SMB_USER_NAME=xo
export SMB_USER_PASSWORD=password
export NODE_NAME=w0
export SUBFOLDER=dat
export SHARENAME=dat

## Container deployment
podman build -t ${CT_IMAGE} ${CT_DIR}${CT_NAME}

podman run -d \
    --name ${CT_NAME} \
    -p 139:139 -p 445:445 \
    -e USERNAME=${SMB_USER_NAME} \
    -e PASSWORD=${SMB_USER_PASSWORD} \
    -v /home/${USER_NAME}/${SUBFOLDER}:/home/${USER_NAME}/${SUBFOLDER}:z \
    ${CT_IMAGE}

podman start ${CT_NAME}

## iptables setup
iptables -L -v -n
iptables -A INPUT -p tcp --dport 139 -j ACCEPT
iptables -A INPUT -p tcp --dport 445 -j ACCEPT
/sbin/iptables-save > /etc/sysconfig/iptables

iptables-restore < /etc/sysconfig/iptables

## Testing
ls -Z <path>
lsof -i -P -n
ss -tuln
smbclient -L ${NODE_NAME} -U ${SMB_USER_NAME}
smbclient //${NODE_NAME}/${SHARENAME} -U ${SMB_USER_NAME}
pdbedit -L
