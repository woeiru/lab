## Variables
export USER_NAME=xo
export USER_PASSWORD=<INSERT_PASSWORD>

export CT_NAME=shxo
export CT_IMAGE=ishxo

export SMB_USER_NAME=smb_user
export SMB_USER_PASSWORD=<INSERT_PASSWORD>

export NODE_NAME=w0
export SUBFOLDER=dat
export SHARENAME=dat

## iptables setup
iptables -L -v -n
iptables -A INPUT -p tcp --dport 139 -j ACCEPT
iptables -A INPUT -p tcp --dport 445 -j ACCEPT
/sbin/iptables-save > /etc/sysconfig/iptables

iptables-restore < /etc/sysconfig/iptables

## Container deployment
podman build -t custom-samba /root/lab/con/${CT_NAME}
podman run -d \
    --name ${CT_NAME} \
    -p 139:139 -p 445:445 \
    -v /home/${USER_NAME}/dat:/home/${USER_NAME}:z \
    ${CT_IMAGE}

## Container setup
podman exec -it ${CT_NAME} bash -c 'echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd'
podman exec -it ${CT_NAME} bash -c 'useradd -s /sbin/nologin ${SMB_USER_NAME}'
podman exec -it ${CT_NAME} bash -c 'echo -e "${SMB_USER_PASSWORD}\n${SMB_USER_PASSWORD}" | smbpasswd -a -s ${SMB_USER_NAME}'
podman exec -it ${CT_NAME} service smbd restart

## Container running
podman start ${CT_NAME}

## testing
ls -Z <path>
lsof -i -P -n
ss -tuln
smbclient -L ${NODE_NAME} -U ${SMB_USER_NAME}
smbclient //${NODE_NAME}/${SHARENAME} -U ${SMB_USER_NAME}
