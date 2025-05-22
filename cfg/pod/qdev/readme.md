# Qdevice setup

<!-- 
This guide details the configuration of a Qdevice (quorum device) host using Podman containers. 
It covers initial setup, container creation, cluster integration, and troubleshooting steps for SSH connectivity issues 
that might arise when connecting Proxmox VE nodes to the Qdevice.
-->

## On qdevice host

### Disable ssh to liberate the port 22
<!-- 
The Qdevice container will initially require SSH access for setup. 
This command stops the SSH daemon on the host machine to free up port 22, 
allowing the container to use it for initial communication with the Proxmox VE nodes.
-->
systemctl stop sshd

### Build container
<!-- 
This command builds a Podman container image named 'iq' using a Dockerfile format (specified by --format docker) 
located in the current directory (.). This image will contain the necessary software for the Qdevice.
-->
podman build . -t iq --format docker

### Create corosync folder if it not exists and set permissions
<!-- 
Corosync is a critical component for cluster communication. 
This step ensures the '/etc/corosync' directory exists on the host and sets its ownership. 
The user ID 701 and group ID 701 are often associated with the 'corosync' user/group, 
which might be the user running corosync inside the container. 
This directory will be volume-mounted into the container.
-->
mkdir /etc/corosync
chown 701:701 /etc/corosync

### In case SELinux is blocking container folders  
<!-- 
If SELinux (Security-Enhanced Linux) is enabled and enforcing, it might prevent the container 
from accessing the host's '/etc/corosync' directory. These commands change the SELinux security context 
of the directory to 'container_file_t' or 'svirt_sandbox_file_t', which are standard labels 
allowing container runtimes to access host files/directories.
-->
chcon -Rt container_file_t /etc/corosync  
chcon -Rt svirt_sandbox_file_t /etc/corosync  

### Run container
<!-- 
This command starts the Qdevice container:
- '-d': Runs the container in detached mode (in the background).
- '--name=qd': Assigns the name 'qd' to the container.
- '--cap-drop=ALL': Drops all Linux capabilities for enhanced security.
- '--privileged': Runs the container in privileged mode. This is often required for services like Qdevice that need low-level system access, though it reduces container isolation.
- '-p 22:22': Maps port 22 of the host to port 22 of the container (for SSH).
- '-p 5403:5403': Maps port 5403 of the host to port 5403 of the container (for Corosync communication).
- '-v /etc/corosync:/etc/corosync': Mounts the host's '/etc/corosync' directory into the container at the same path, allowing persistent storage for Corosync configuration.
- 'iq': Specifies the image to use for the container.
-->
podman run -d --name=qd --cap-drop=ALL --privileged -p 22:22 -p 5403:5403 -v /etc/corosync:/etc/corosync iq

### Enable sshd as Su inside container
<!-- 
These commands are executed inside the running 'qd' container:
- 'podman exec -ti qd bash': Opens an interactive bash shell inside the 'qd' container.
- 'su': Switches to the superuser (root) within the container.
- 'service ssh start': Starts the SSH daemon inside the container. This is necessary for the Proxmox VE nodes to connect to the Qdevice for the initial setup.
-->
podman exec -ti qd bash  
su  
service ssh start

## On Nodes 
<!-- 
This command is run on each Proxmox VE node to configure them to use the Qdevice.
- '<IP QDEVICE HOST>': Replace this with the actual IP address of the host running the Qdevice container.
- '-f': Forces the operation, potentially overwriting existing configurations.
-->
pvecm qdevice setup <IP QDEVICE HOST> -f

## On Qdevice Host
### Save Container to new image after setting up cluster qdevice
<!-- 
After the Proxmox VE nodes have successfully connected and configured the Qdevice (which involves writing configuration to /etc/corosync inside the container), 
this command commits the current state of the 'qd' container to a new image named 'iqdx'. 
This new image now includes the cluster-specific Corosync configuration.
-->
podman commit qd iqdx

### Run container this time without port forwarding the ssh port
<!-- 
This command stops and removes the old 'qd' container (implicitly, as a new one 'qdx' is started with the same name if not removed prior) 
and starts a new container named 'qdx' from the 'iqdx' image. 
Crucially, port 22 (SSH) is no longer forwarded from the host. 
SSH was only needed for the initial setup by 'pvecm qdevice setup'. 
The Qdevice now communicates primarily over port 5403 for Corosync.
-->
podman run -d --name=qdx --cap-drop=ALL --privileged -p 5403:5403 -v /etc/corosync:/etc/corosync iqdx

### Re-enable sshd on the host
<!-- 
Now that the container no longer needs port 22 on the host, the host's SSH daemon can be restarted, 
restoring normal SSH access to the Qdevice host machine.
-->
systemctl start sshd

## On Node 1 - In case pvecm qdevice setup don't work  
<!-- 
This section provides troubleshooting steps if the 'pvecm qdevice setup' command fails on Node 1, 
often due to SSH host key mismatches or missing keys. 
The variables 'node2_ip' and 'qdevice_ip' should be set to the correct IP addresses.
-->
node2_ip="192.168.178.220"  
qdevice_ip="192.168.178.230"  

### Step 1: Remove existing host keys  
<!-- 
These commands remove any existing SSH host keys for Node 2 and the Qdevice host from Node 1's 'known_hosts' file. 
This is useful if the host keys have changed (e.g., due to OS reinstall or IP address reuse) and are causing SSH connection errors.
-->
ssh-keygen -R "$node2_ip"  
ssh-keygen -R "$qdevice_ip"  

### Step 2: Re-scan and add current host keys  
<!-- 
These commands scan Node 2 and the Qdevice host for their current SSH host keys and append them to Node 1's 'known_hosts' file. 
This ensures Node 1 has the correct keys for future SSH connections.
-->
ssh-keyscan -H "$node2_ip" >> ~/.ssh/known_hosts  
ssh-keyscan -H "$qdevice_ip" >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access  
<!-- 
These commands test SSH connectivity from Node 1 to Node 2 and the Qdevice host as the root user. 
The 'exit' command closes each SSH session. This helps confirm that the host keys are correct and passwordless SSH (if set up) is working.
-->
ssh root@"$node2_ip"  
exit  
ssh root@"$qdevice_ip"  
exit  

### Step 4: Copy SSH key
<!-- 
These commands copy Node 1's public SSH key to Node 2 and the Qdevice host for the root user. 
This enables passwordless SSH authentication from Node 1 to these machines, which is often required or beneficial for cluster operations.
-->
ssh-copy-id root@"$node2_ip"  
ssh-copy-id root@"$qdevice_ip"  

## On Node 2 - In case pvecm qdevice setup don't work  
<!-- 
This section mirrors the troubleshooting steps for Node 1, but performed on Node 2, targeting Node 1 and the Qdevice host.
The variables 'node1_ip' and 'qdevice_ip' should be set to the correct IP addresses.
-->
node1_ip="192.168.178.210"  
qdevice_ip="192.168.178.230"  

### Step 1: Remove existing host keys  
<!-- 
Removes existing SSH host keys for Node 1 and the Qdevice host from Node 2's 'known_hosts' file.
-->
ssh-keygen -R "$node1_ip"  
ssh-keygen -R "$qdevice_ip"  

### Step 2: Re-scan and add current host keys   
<!-- 
Scans Node 1 and the Qdevice host for their current SSH host keys and appends them to Node 2's 'known_hosts' file.
-->
ssh-keyscan -H "$node1_ip" >> ~/.ssh/known_hosts  
ssh-keyscan -H "$qdevice_ip" >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access  
<!-- 
Tests SSH connectivity from Node 2 to Node 1 and the Qdevice host as the root user.
-->
ssh root@"$node1_ip"  
exit  
ssh root@"$qdevice_ip"  
exit  

### Step 4: Copy SSH key  
<!-- 
Copies Node 2's public SSH key to Node 1 and the Qdevice host for the root user, enabling passwordless SSH.
-->
ssh-copy-id root@"$node1_ip"  
ssh-copy-id root@"$qdevice_ip"  

## On both nodes after Step 4 is completed on each of them
<!-- 
After ensuring SSH connectivity and key exchange are correctly set up between all nodes and the Qdevice host, 
this command should be run again on both Proxmox VE nodes to attempt the Qdevice setup. 
The '$qdevice_ip' variable should be the IP address of the Qdevice host.
-->
pvecm qdevice setup "$qdevice_ip" -f
