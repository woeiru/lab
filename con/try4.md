### Preparing Network
podman network create -d macvlan --subnet=192.168.178.0/24 --gateway=192.168.178.1 -o parent=wlp3s0 macvlan

### Build Container
podman build . -t iq

### Run Container
podman run -d \
  --name=qnetd \
  --network=macvlan \
  --ip=192.168.178.231 \
  --cap-drop=ALL \
  --privileged \
  -v /etc/corosync:/etc/corosync \
  localhost/iq


### In case SELinux is blocking container folders
chcon -R -t container_file_t /etc/corosync
sudo chcon -Rt svirt_sandbox_file_t /etc/corosync
