## On QDEVICE Host

### Preparing Workspace
mkdir -p $HOME/lab/con/qdev3/corosync-data
cd $HOME/lab/con/qdev3

### Preparing Network
podman network create -d macvlan --subnet=192.168.178.0/24 --gateway=192.168.178.1 -o parent=eno1 macvlan

### Build Container
podman build . -t idebqd

### Run Container
docker run -d -it \
--name=debqd \
--net=macvlan \
--ip=192.168.178.231 \
-p 5403:5403 \
-p 22:22 \
--cap-drop=ALL \
-v /etc/corosync:/etc/corosync \
--restart=always \
modelrockettier/corosync-qnetd
