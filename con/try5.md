# Qdevice setup

## On qdevice host
### Disable ssh to liberate the port 22
systemctl stop sshd

### Build container
podman build . -t iq --format docker

### Run container
podman run -d \  
  --name=qd \  
  --cap-drop=ALL \ 
  --privileged \  
  -p 22:22 \  
  -p 5403:5403 \  
  -v /etc/corosync:/etc/corosync \  
  iqd

### Enable sshd as Su inside container
podman exec -ti qd bash  
su  
service ssh start

## On Nodes 
pvecm qdevice setup <IP QDEVICE HOST> -f

## On Qdevice Host
### Save Container to new image after setting up cluster qdevice
podman commit qd iqdx

### Run container this time without ssh the port 22
podman run -d \  
  --name=qdx \  
  --cap-drop=ALL \  
  --privileged \  
  -p 5403:5403 \  
  -v /etc/corosync:/etc/corosync \  
  iqdx

### Re-enable sshd on the host
systemctl start sshd

# Troubleshooting

#!/bin/bash  


# Troubleshooting  

## On qdevice host - In case SELinux is blocking container folders  
chcon -R -t container_file_t /etc/corosync  
sudo chcon -Rt svirt_sandbox_file_t /etc/corosync  

## On Node 1 - In case pvecm qdevice setup don't work  
qdevice_ip="192.168.178.230"  
node1_ip="192.168.178.210"  

### Step 1: Remove existing host keys for Node 2 and QDevice IPs  
ssh-keygen -R "$node1_ip"  
ssh-keygen -R "$qdevice_ip"  

### Step 2: Re-scan and add current host keys for Node 2 and QDevice  
ssh-keyscan -H "$node1_ip" >> ~/.ssh/known_hosts  
ssh-keyscan -H "$qdevice_ip" >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access to Node 2 and QDevice  
ssh root@"$node1_ip"  
exit  
ssh root@"$qdevice_ip"  
exit  

### Step 4: Copy SSH key to Node 2 and QDevice  
ssh-copy-id root@"$node1_ip"  
ssh-copy-id root@"$qdevice_ip"  

### Step 5: Set up QDevice  
pvecm qdevice setup "$qdevice_ip" -f  

## On Node 2 - In case pvecm qdevice setup don't work  
qdevice_ip="192.168.178.230"  
node2_ip="192.168.178.220"  

### Step 1: Remove existing host keys for Node 1 and QDevice IPs  
ssh-keygen -R "$node2_ip"  
ssh-keygen -R "$qdevice_ip"  

### Step 2: Re-scan and add current host keys for Node 1 and QDevice  
ssh-keyscan -H "$node2_ip" >> ~/.ssh/known_hosts  
ssh-keyscan -H "$qdevice_ip" >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access to Node 1 and QDevice  
ssh root@"$node2_ip"  
exit  
ssh root@"$qdevice_ip"  
exit  

### Step 4: Copy SSH key to Node 1 and QDevice  
ssh-copy-id root@"$node2_ip"  
ssh-copy-id root@"$qdevice_ip"  

### Step 5: Set up QDevice  
pvecm qdevice setup "$qdevice_ip" -f  

