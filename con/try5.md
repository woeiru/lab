# Qdevice setup

## On qdevice host
### Disable ssh to liberate the port 22
systemctl stop sshd

### Build container
podman build . -t iq --format docker

### Run Container
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

## On qdevice host - In case SELinux is blocking container folders
chcon -R -t container_file_t /etc/corosync

sudo chcon -Rt svirt_sandbox_file_t /etc/corosync

## On Nodes -  In case pvecm qdevice setup dont work 
### Step 1: Remove existing host keys for Node 2 and QDevice IPs
ssh-keygen -R 192.168.178.210  
ssh-keygen -R 192.168.178.230  

### Step 2: Re-scan and add current host keys for Node 2 and QDevice
ssh-keyscan -H 192.168.178.210 >> ~/.ssh/known_hosts  
ssh-keyscan -H 192.168.178.230 >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access to Node 2 and QDevice
ssh root@192.168.178.210  
exit  
ssh root@192.168.178.230  
exit  

### Step 4: Copy SSH key to Node 2 and QDevice
ssh-copy-id root@192.168.178.210  
ssh-copy-id root@192.168.178.230

### Step 5: Set up QDevice
pvecm qdevice setup 192.168.178.230 -f

## Node 2 Commands

### Step 1: Remove existing host keys for Node 1 and QDevice IPs
ssh-keygen -R 192.168.178.220  
ssh-keygen -R 192.168.178.230 

### Step 2: Re-scan and add current host keys for Node 1 and QDevice
ssh-keyscan -H 192.168.178.220 >> ~/.ssh/known_hosts  
ssh-keyscan -H 192.168.178.230 >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access to Node 1 and QDevice
ssh root@192.168.178.220  
exit  
ssh root@192.168.178.230  
exit

### Step 4: Copy SSH key to Node 1 and QDevice
ssh-copy-id root@192.168.178.220  
ssh-copy-id root@192.168.178.230  

### Step 5: Set up QDevice
pvecm qdevice setup 192.168.178.230 -f



