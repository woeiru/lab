# Qdevice setup

<!-- 
This guide details the configuration of a Qdevice (quorum device) host using Podman containers. 
It covers initial setup, container creation, cluster integration, and troubleshooting steps for SSH connectivity issues 
that might arise when connecting Proxmox VE nodes to the Qdevice.
-->

## Prerequisites

No Corosync packages needed on the host OS; the container provides everything required.

**Static IP Address for Qdevice Host:** The host machine for the Qdevice *must* have a static IP address or a DHCP reservation to ensure its IP address does not change. This is critical for stable communication with the Proxmox VE cluster.

**Setting a Static IP on SUSE Linux with NetworkManager (e.g., for interface `enp3s0` to `192.168.178.223`):**

If your SUSE Linux system uses NetworkManager, you can configure a static IP address using `nmtui` (a text-based user interface) or `nmcli` (the command-line interface).

1.  **Ensure NetworkManager is Active:**
    Verify NetworkManager is running and managing your network interfaces:
    ```bash
    sudo systemctl status NetworkManager
    # Check if NetworkManager is managing the specific interface (e.g., enp3s0)
    nmcli dev status
    ```
    If it's not active, enable and start it:
    ```bash
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
    ```

2.1  **Configure Static IP using `nmtui` (Recommended for ease of use):**
    *   Open the text-based network configuration tool:
        ```bash
        sudo nmtui
        ```
    *   Navigate to "Edit a connection".
    *   Select your network interface (e.g., `enp3s0`) and choose "Edit...".
    *   Change "IPv4 CONFIGURATION" from `<Automatic>` (DHCP) to `<Manual>`.
    *   Select "Show" next to IPv4 CONFIGURATION to expand the options.
    *   In "Addresses", select "Add..." and enter the IP address and prefix (e.g., `192.168.178.223/24`).
    *   Enter your "Gateway" (e.g., `192.168.178.1`).
    *   In "DNS servers", select "Add..." and enter your DNS server(s) (e.g., `192.168.178.1`, `8.8.8.8`).
    *   Ensure "Automatically connect" is checked.
    *   Select "OK" to save, then "Back", and "Quit" `nmtui`.
    *   NetworkManager should automatically apply the changes. You might need to disconnect and reconnect the interface or restart NetworkManager if the changes don't take effect immediately:
        ```bash
        sudo nmcli connection down <connection_name> && sudo nmcli connection up <connection_name>
        # or
        # sudo systemctl restart NetworkManager
        ```
        (Replace `<connection_name>` with the name of your connection, often the same as the interface name like `enp3s0`).

2.2  **Configure Static IP using `nmcli` (Command-line alternative):**
    Replace `enp3s0` with your actual interface name and `192.168.178.1` with your actual gateway and DNS server(s) if different.
    ```bash
    # Set the static IP address, prefix, and gateway
    sudo nmcli con mod enp3s0 ipv4.addresses 192.168.178.223/24
    sudo nmcli con mod enp3s0 ipv4.gateway 192.168.178.1
    
    # Set DNS servers (this will overwrite existing DNS servers)
    # To add multiple, separate them with a space: "192.168.178.1 8.8.8.8"
    sudo nmcli con mod enp3s0 ipv4.dns "192.168.178.1 8.8.8.8"
    
    # Change the method to manual (from DHCP)
    sudo nmcli con mod enp3s0 ipv4.method manual
    
    # Apply the changes by taking the connection down and then up
    sudo nmcli con down enp3s0 && sudo nmcli con up enp3s0
    # Alternatively, restart NetworkManager (this will affect all connections)
    # sudo systemctl restart NetworkManager
    ```

3.  **Set Default Route (if not automatically configured by NetworkManager):**
    In most cases, NetworkManager should set the default route based on the `ipv4.gateway` setting. However, if you find that the default route is missing after applying the changes in step 3, you can add it manually.
    Replace `192.168.178.1` with your actual gateway IP and `enp3s0` with your actual interface name (e.g., `wlp4s0` from your example).
    ```bash
    # Check current routes
    ip route
    # Look for a line like: "default via 192.168.178.1 dev enp3s0" - if missing, add it manually
    # Add default route (if missing)
    sudo ip route add default via 192.168.178.1 dev enp3s0 
    # Verify route is added
    ip route
    ```
    **Note:** Manually adding a route with `ip route add` might not persist across reboots. The preferred method is to ensure NetworkManager configures the gateway correctly. This step is primarily for troubleshooting or temporary setups if NetworkManager fails to set the route. If the gateway was correctly specified in `nmcli con mod enp3s0 ipv4.gateway <gateway_ip>`, NetworkManager should handle this.

4.  **Verify Configuration:**
    After applying the changes, verify the new settings:
    ```bash
    ip addr show enp3s0
    ip route
    cat /etc/resolv.conf # Check if DNS servers are correctly listed (NetworkManager might manage this directly or via netconfig)
    ping -c 3 192.168.178.1 # Ping your gateway (use the actual gateway IP)
    ping -c 3 google.com    # Ping an external host to test DNS and internet connectivity
    ```
    Ensure `enp3s0` shows the IP `192.168.178.223/24`, the default route points to your gateway via `enp3s0`, and that DNS resolution works.

---

**Proxmox VE Nodes:**
Ensure the `corosync-qdevice` package is installed on all Proxmox VE nodes in the cluster. This package allows the nodes to communicate with the QNetd server. You can typically install it using:
```bash
sudo apt update
sudo apt install corosync-qdevice
```

## On qdevice host

### Disable ssh to liberate the port 22
<!-- 
The Qdevice container will initially require SSH access for setup. 
This command stops the SSH daemon on the host machine to free up port 22, 
allowing the container to use it for initial communication with the Proxmox VE nodes.
-->
sudo systemctl stop sshd

### Navigate to the Qdevice configuration directory
<!--
It's important to be in the directory containing the Containerfile and other necessary build context
before running the podman build command. This ensures that Podman can find all the required files.
The $LAB_DIR environment variable should be set to your lab's base directory.
-->
cd $LAB_DIR/cfg/pod/qdev

### Build container
<!-- 
This command builds a Podman container image named 'iq' using a Dockerfile format (specified by --format docker) 
located in the current directory (.). This image will contain the necessary software for the Qdevice.

**Note:** The `sudo` prefix is required because mapping privileged ports (such as port 22 for SSH) to the container 
requires elevated permissions. Without `sudo`, Podman cannot bind to ports below 1024, which are reserved for the root user.
-->
sudo podman build . -t iq --format docker

### Create corosync folder if it not exists and set permissions
<!-- 
Corosync is a critical component for cluster communication. 
This step ensures the '/etc/corosync' directory exists on the host and sets its ownership. 
The user ID 701 and group ID 701 are often associated with the 'corosync' user/group, 
which might be the user running corosync inside the container. 
This directory will be volume-mounted into the container.
-->
sudo mkdir /etc/corosync
sudo chown 701:701 /etc/corosync

### In case SELinux is blocking container folders  
<!-- 
If SELinux (Security-Enhanced Linux) is enabled and enforcing, it might prevent the container 
from accessing the host's '/etc/corosync' directory. These commands change the SELinux security context 
of the directory to 'container_file_t' or 'svirt_sandbox_file_t', which are standard labels 
allowing container runtimes to access host files/directories.
To check the current SELinux context of the directory, you can use: `ls -Zd /etc/corosync`
# Alternative context sudo chcon -Rt svirt_sandbox_file_t /etc/corosync - may not work on all systems (e.g., openSUSE)
-->
sudo chcon -Rt container_file_t /etc/corosync  

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
- 'localhost/iq': Specifies the locally built image to use for the container.
-->
sudo podman run -d --name=qd --cap-drop=ALL --privileged -p 22:22 -p 5403:5403 -v /etc/corosync:/etc/corosync localhost/iq

### Enable sshd as Su inside container
<!-- 
These commands are executed inside the running 'qd' container:
- 'sudo podman exec -ti qd bash': Opens an interactive bash shell inside the 'qd' container.
  The following commands are then run *inside this shell*.
- 'su': Switches to the superuser (root) within the container. You might be prompted for the root password (which is 'password' as set in the Containerfile).
- 'service ssh start': Starts the SSH daemon inside the container. This is necessary for the Proxmox VE nodes to connect to the Qdevice for the initial setup.
-->

sudo podman exec -ti qd bash  

### Inside the container's shell, type the following:

su
<!-- The root password required after running `su` is set in the Containerfile (default: `password`). -->

service ssh start
<!--  If sshd fails to start due to /run/sshd permissions, run as root:
# mkdir -p /run/sshd
# chown root:root /run/sshd
# chmod 0755 /run/sshd
 -->

exit

## On Cluster Nodes 
<!-- 
This command is run on each Proxmox VE node to configure them to use the Qdevice.
- '<IP QDEVICE HOST>': Replace this with the actual IP address of the host running the Qdevice container.
- '-f': Forces the operation, potentially overwriting existing configurations.
-->
QDEVICE_IP="<IP QDEVICE HOST>"
pvecm qdevice setup "$QDEVICE_IP" -f 

## On Qdevice Host

### Save Container to new image after setting up cluster qdevice
<!-- 
After the Proxmox VE nodes have successfully connected and configured the Qdevice (which involves writing configuration to /etc/corosync inside the container), 
this command commits the current state of the 'qd' container to a new image named 'iqdx'. 
This new image now includes the cluster-specific Corosync configuration.
-->
sudo podman commit qd iqdx

### Run container this time without port forwarding the ssh port
<!-- 
This command stops and removes the old 'qd' container (implicitly, as a new one 'qdx' is started with the same name if not removed prior) 
and starts a new container named 'qdx' from the 'iqdx' image. 
Crucially, port 22 (SSH) is no longer forwarded from the host. 
SSH was only needed for the initial setup by 'pvecm qdevice setup'. 
The Qdevice now communicates primarily over port 5403 for Corosync.
-->
sudo podman run -d --name=qdx --cap-drop=ALL --privileged -p 5403:5403 -v /etc/corosync:/etc/corosync iqdx

### Re-enable sshd on the host
<!-- 
Now that the container no longer needs port 22 on the host, the host's SSH daemon can be restarted, 
restoring normal SSH access to the Qdevice host machine.
-->
sudo systemctl start sshd

## On Node 1 - In case pvecm qdevice setup don't work  
<!-- 
This section provides troubleshooting steps if the 'pvecm qdevice setup' command fails on Node 1, 
often due to SSH host key mismatches or missing keys. 
The variables 'NODE2_IP' and 'QDEVICE_IP' should be set to the correct IP addresses.
The following commands assume you are operating as the root user on the Proxmox VE node.
-->

NODE2_IP="<IP CLUSTER NODE 2>"  

### On Node 1 - Step 1: Remove existing host keys  
<!-- 
These commands remove any existing SSH host keys for Node 2 and the Qdevice host from Node 1's 'known_hosts' file. 
This is useful if the host keys have changed (e.g., due to OS reinstall or IP address reuse) and are causing SSH connection errors.
-->
ssh-keygen -R "$QDEVICE_IP"
ssh-keygen -R "$NODE2_IP"  

### Step 2: Re-scan and add current host keys  
<!-- 
These commands scan Node 2 and the Qdevice host for their current SSH host keys and append them to Node 1's 'known_hosts' file. 
This ensures Node 1 has the correct keys for future SSH connections.
-->
ssh-keyscan -H "$QDEVICE_IP" >> ~/.ssh/known_hosts
ssh-keyscan -H "$NODE2_IP" >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access  
<!-- 
These commands test SSH connectivity from Node 1 to Node 2 and the Qdevice host as the root user. 
The 'exit' command closes each SSH session. This helps confirm that the host keys are correct and passwordless SSH (if set up) is working.
-->
ssh root@"$NODE2_IP"  
exit  
ssh root@"$QDEVICE_IP"  
exit  

### Step 4: Copy SSH key
<!-- 
These commands copy Node 1's public SSH key to Node 2 and the Qdevice host for the root user. 
This enables passwordless SSH authentication from Node 1 to these machines, which is often required or beneficial for cluster operations.
-->
ssh-copy-id root@"$QDEVICE_IP"  
ssh-copy-id root@"$NODE2_IP"  

### Step 5: Retry Qdevice Setup on Node 1
<!--
After completing the above troubleshooting steps for Node 1, attempt the Qdevice setup command again on Node 1
to verify if the issue is resolved. Ensure the 'QDEVICE_IP' variable is correctly set to your Qdevice's IP address.
-->
pvecm qdevice setup "$QDEVICE_IP" -f

<!--
- If this command succeeds on Node 1: Great! You will then need to ensure the same setup command is run on Node 2. If Node 2 also failed previously or you anticipate issues, proceed to the "On Node 2 - In case pvecm qdevice setup don't work" section for Node 2 before running the setup command there.
- If this command still fails on Node 1: Review the output carefully. You may need to re-check the previous troubleshooting steps or investigate new error messages.
-->

## On Node 2 - In case pvecm qdevice setup don't work  
<!-- 
This section mirrors the troubleshooting steps for Node 1, but performed on Node 2, targeting Node 1 and the Qdevice host.
The variables 'NODE1_IP' and 'QDEVICE_IP' should be set to the correct IP addresses.
The following commands assume you are operating as the root user on the Proxmox VE node.
-->
QDEVICE_IP="<IP QDEVICE HOST>" 
NODE1_IP="<IP CLUSTER NODE 1>"   

### Step 1: Remove existing host keys  
<!-- 
Removes existing SSH host keys for Node 1 and the Qdevice host from Node 2's 'known_hosts' file.
-->
ssh-keygen -R "$QDEVICE_IP"  
ssh-keygen -R "$NODE1_IP"  

### Step 2: Re-scan and add current host keys   
<!-- 
Scans Node 1 and the Qdevice host for their current SSH host keys and appends them to Node 2's 'known_hosts' file.
-->
ssh-keyscan -H "$QDEVICE_IP" >> ~/.ssh/known_hosts  
ssh-keyscan -H "$NODE1_IP" >> ~/.ssh/known_hosts  

### Step 3: Verify SSH access  
<!-- 
Tests SSH connectivity from Node 2 to Node 1 and the Qdevice host as the root user.
-->
ssh root@"$QDEVICE_IP"  
exit  
ssh root@"$NODE1_IP"  
exit  

### Step 4: Copy SSH key  
<!-- 
Copies Node 2's public SSH key to Node 1 and the Qdevice host for the root user, enabling passwordless SSH.
-->
ssh-copy-id root@"$QDEVICE_IP" 
ssh-copy-id root@"$NODE1_IP"  

### Step 5: Retry Qdevice Setup on Node 2
<!--
After completing the above troubleshooting steps for Node 2, attempt the Qdevice setup command again on Node 2
to verify if the issue is resolved. Ensure the 'QDEVICE_IP' variable is correctly set to your Qdevice's IP address.
-->
pvecm qdevice setup "$QDEVICE_IP" -f
<!--
- If this command succeeds (or reports the Qdevice is already configured): The Qdevice setup should now be complete for the cluster.
- If this command still fails : Review the output carefully. You may need to re-check the previous troubleshooting steps or investigate new error messages.
-->

---

## Qdevice Reinstall/Cleanup Procedure

<!-- 
This section covers the proper cleanup procedure when you need to reinstall the Qdevice 
(e.g., after a fresh OS install on the Qdevice host). The order of operations is important 
to avoid certificate conflicts and ensure a clean setup.
-->

### When to use this procedure:
- After reinstalling the OS on the Qdevice host
- When switching to a new Qdevice host
- When experiencing persistent certificate or connection issues

### Step 1: Remove Qdevice from cluster configuration (on any cluster node)
<!-- 
Remove the Qdevice from the cluster configuration first. This cleans up the cluster's 
expectation of the Qdevice and allows for a fresh setup.
-->
```bash
pvecm qdevice remove
```

### Step 2: Clean up certificates on ALL cluster nodes
<!-- 
After removing the Qdevice from the cluster configuration, clean up the old certificates 
on each node. This prevents certificate conflicts during the new setup.
Run these commands on EACH Proxmox VE node in the cluster.
-->
```bash
# Remove old Qdevice certificates
rm -rf /etc/corosync/qdevice/net/nssdb

# Remove old SSH host keys for the Qdevice host
ssh-keygen -f "/root/.ssh/known_hosts" -R "192.168.178.223"
# Replace 192.168.178.223 with your actual Qdevice host IP
```

### Step 3: Verify cluster status
<!-- 
Check that the Qdevice has been completely removed from the cluster configuration.
-->
```bash
pvecm status
```
You should see no mention of "Qdevice" in the output, and "Expected votes" should equal the number of cluster nodes.

### Step 4: Proceed with fresh Qdevice setup
<!-- 
Now you can proceed with the normal Qdevice setup procedure from the beginning, 
starting with building/running the container and then running the setup commands.
-->
Follow the standard setup procedure from the "On qdevice host" section.

## Handling Inconsistent Qdevice State During Setup

<!-- 
This section covers a specific scenario that can occur during the Qdevice setup process 
when the certificate distribution succeeds but the final cluster configuration step fails.
This results in an inconsistent state where pvecm status shows a Qdevice but 
pvecm qdevice remove says "No QDevice configured!"
-->

### When this happens:
- `pvecm qdevice setup` completes certificate distribution but fails at "add QDevice to cluster configuration"
- `pvecm status` shows "Qdevice (votes 0)" 
- `pvecm qdevice remove` reports "No QDevice configured!"
- This commonly occurs after a fresh OS install on the Qdevice host

### Resolution:
1. **Clean up the inconsistent state on ALL cluster nodes**:
   ```bash
   # Stop corosync-qdevice service on all nodes
   systemctl stop corosync-qdevice
   
   # Remove certificates on ALL cluster nodes
   rm -rf /etc/corosync/qdevice/net/nssdb
   
   # Clean up SSH known_hosts on ALL cluster nodes
   ssh-keygen -f "/root/.ssh/known_hosts" -R "192.168.178.223"
   # Replace with your actual Qdevice IP
   ```

2. **Restart corosync on all nodes to clear cached state**:
   ```bash
   systemctl restart corosync
   ```

3. **Verify clean state**:
   ```bash
   pvecm status
   ```
   Should show no mention of Qdevice and Expected votes = number of nodes.

4. **Add Qdevice host keys and retry the setup**:
   ```bash
   # Add SSH host keys for the Qdevice on all nodes
   ssh-keyscan -H "192.168.178.223" >> ~/.ssh/known_hosts
   
   # Retry the setup
   QDEVICE_IP="192.168.178.223"
   pvecm qdevice setup "$QDEVICE_IP" -f
   ```

5. **Verify successful configuration**:
   ```bash
   pvecm status
   ```
   Should show:
   - Expected votes: 3 (2 nodes + 1 Qdevice)
   - Total votes: 3
   - Qdevice with 1 vote (not 0)
   - Flags: Quorate Qdevice
