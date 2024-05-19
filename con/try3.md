## On QDEVICE Host

### Installation
tu pkg in corosync-qnetd

### Preparing Network
podman network create -d macvlan --subnet=192.168.178.0/24 --gateway=192.168.178.1 -o parent=wlp3s0 macvlan

### Setup SELinux
chcon -R -t container_file_t /etc/corosync
or
chcon -Rt svirt_sandbox_file_t /etc/corosync

troubleshooting:
ausearch -m avc -ts recent

### Run Container
podman run -d -it \
--name=debqd \
--net=macvlan \
--ip=192.168.178.231 \
-p 5403:5403 \
-p 22:22 \
--cap-drop=ALL \
-v /etc/corosync:/etc/corosync \
modelrockettier/corosync-qnetd
