# How to Add a User to Sudoers in Debian

After a standard Debian installation, your regular user account might not have `sudo` privileges by default. 

Here are the exact commands you need to execute to add your user to the `sudo` group:

### 1. Switch to the root user
You must switch to the `root` user to make these changes. It's crucial to use `su -` (with the hyphen) rather than just `su`. The hyphen ensures you load the root user's environment, including the proper `$PATH` required to run system administration commands like `adduser` or `usermod`.

```bash
su -
```
*(You will be prompted to enter the root password you set during installation)*

### 2. Add your user to the `sudo` group
Once you are logged in as root, run the following command. Make sure to replace `your_username` with your actual username.

```bash
adduser your_username sudo
```

*(Alternatively, you can also use `usermod -aG sudo your_username`, which does exactly the same thing. `adduser` is generally preferred on Debian systems as it's a friendlier perl wrapper.)*

### 3. Apply the changes
Group assignments are only evaluated at login. To start using `sudo`, you must apply the new group permissions. You can do this by either:

- **Logging out and logging back in** to your graphical session or terminal.
- **Or, starting a new login shell** for your user directly from the terminal:
  ```bash
  exit               # First, exit the root shell
  su - your_username # Start a new shell as your user
  ```

Now you should be able to execute commands with `sudo`!

## How to Set Up an SSH Server

If you did not select "SSH server" during the Debian installation process, you will need to install and configure it manually to allow remote access to your machine.

### 1. Update the package list
Before installing new software, it's always a good practice to update your local package index.

```bash
sudo apt update
```

### 2. Install the OpenSSH server
Install the `openssh-server` package from the Debian repositories. 

```bash
sudo apt install openssh-server
```

### 3. Verify the SSH service is running
In Debian, the SSH service should start automatically after installation. You can verify its status with:

```bash
sudo systemctl status ssh
```
*(Press `q` to exit the status output if it takes up the full screen)*

If the service is not running or not enabled to start at boot, you can start and enable it manually:

```bash
sudo systemctl enable --now ssh
```

### 4. Connect to your machine
You can now connect to your Debian machine from another computer on the same network using the `ssh` command:

```bash
ssh your_username@your_machine_ip
```
*(You can find your machine's IP address by running `ip a`)*
