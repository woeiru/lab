### Preparing Network
docker network create -d macvlan --subnet=192.168.178.0/24 --gateway=192.168.178.1 -o parent=wlp3s0 macvlan

### Build Container
docker build . -t iq

### Run Container
docker run -itd \
  --name=cq \
  --network=macvlan \
  --ip=192.168.178.231 \
  --cap-drop=ALL \
  --privileged \
  -v /etc/corosync:/etc/corosync \
  iq


### In case SELinux is blocking container folders
chcon -R -t container_file_t /etc/corosync
sudo chcon -Rt svirt_sandbox_file_t /etc/corosync

### Troubleshooting no Network connection 
ip -a
ip link set enp0s3 promisc on
iptables --list
iptables -I NETAVARK_INPUT -i wlp3s0 -j ACCEPT

