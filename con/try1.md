## On QDEVICE Host

### Disable SSH on Host, check, start new container with ssh port
systemctl stop sshd
lsof -i -P -n
podman run -dit --name debq1 -p 22:22 debian

## In QDEVICE Container
podman exec -it debq1 bash 
apt-get update && apt-get upgrade
apt-get install -y vm openssh-server corosync-qnetd

## On QDEVICE Host
### (Later take this idebq1 image , service ssh start , and go to next step)
exit
podman stop debq1
podman commit debq1 idebq1
podman container rm debq1

## In QDEVICE Container
podman run -dit --name debq2 -p 22:22 idebq1
podman exec -it debq2 bash 
vim /etc/ssh/sshd_config
service ssh start
service ssh status
passwd

## On Cluster Nodes
### Tunnel to Qdevice and Install
pvecm qdevice setup <QDEVICE-IP>

## On QDEVICEHost
### Save Image, (re)start SSH, start new container with qnet port
podman stop debq2
podman commit debq2 idebq2
podman container rm debq2
systemctl start sshd
podman run -dit --name debq3 -p 5403:5403 idebq2
podman exec -it debq3 bash 

## In QDEVICE Container
service corosync-qnetd start
service corosync-qnetd status
