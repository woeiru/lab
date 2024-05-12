## On QDEVICE Host

### Preparing Workspace
mkdir -p $HOME/lab/con/qdev2/corosync-data
cd $HOME/lab/con/qdev2

### Preparing Network
podman network create -d macvlan --subnet=192.168.178.0/24 --gateway=192.168.178.1 -o parent=eno1 macvlan

### Build Container
podman build . -t idebqd

### Run Container
podman run -d -it \
--name debqd \
--net=macvlan \
--ip=192.168.178.231 \
-v /var/lib/ca-certificates/pem:/etc/pki/nssdb \
-v $HOME/lab/con/qdev2/corosync-data:/etc/corosync \
-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-v /run:/run \
-v /run/lock:/run/lock \
-v /tmp:/tmp \
--restart=always \
idebqd:latest


### In case SELinux is blocking container folders
chcon -R -t container_file_t $HOME/lab/con/qdev2/corosync-data
chcon -R -t container_file_t /var/lib/ca-certificates/pem
chcon -R -t container_file_t /sys/fs/cgroup

## On Cluster Nodes
### Tunnel to Qdevice and Install
pvecm qdevice setup <QDEVICE-IP>
