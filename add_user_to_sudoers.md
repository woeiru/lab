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
