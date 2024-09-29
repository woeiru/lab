# Shell Scripts and Configurations

This repository contains shell scripts and configuration files for customizing and managing a Linux environment, particularly focused on KDE Plasma desktop, Git, and SSH configurations.

## Contents

1. [depl.sh](#deplsh)
2. [func.sh](#funcsh)
3. [bashinject](#bashinject)

## depl.sh

The main deployment script that sets up the entire configuration.

### Functionality:
- Copies `func.sh` to the user's home directory
- Sources `func.sh` to make the `configure_git_ssh_passphrase()` function available
- Runs the `configure_git_ssh_passphrase()` function to set up Git and SSH configurations
- Injects the content of `bashinject` into `.bashrc` or `.zshrc`
- Checks for existing configurations before making changes

### Usage:
```bash
./depl.sh
```

## func.sh

Contains utility functions for system configuration.

### Main Functions:
1. `change_konsole_profile()`: Changes the default Konsole profile for the current user
2. `configure_git_ssh_passphrase()`: Sets up Git and SSH configurations

#### change_konsole_profile() functionality:
- Changes the default Konsole profile for the current user
- Supports both regular users and root
- Validates input and handles potential errors

#### Usage:
```bash
source ~/func.sh
change_konsole_profile 2  # Changes to Profile 2
```

#### configure_git_ssh_passphrase() functionality:
- Configures Git globally to disable password prompting
- Updates SSH configuration to disable ASKPASS for all hosts
- These are one-time setups that don't need to run on every shell session

#### Usage:
```bash
source ~/func.sh
configure_git_ssh_passphrase
```

## bashinject

Contains aliases and configurations that will be injected into your shell environment.

### Features:
- Sources `~/func.sh`
- Provides aliases for switching KDE Plasma themes:
  - `p1`: Switch to Breeze light theme and Konsole profile 1
  - `p2`: Switch to Breeze dark theme and Konsole profile 2
- Includes an alias `ypr` to restart the Plasma shell

## Installation

1. Clone this repository to your local machine.
2. Make sure the `depl.sh` script is executable:
   ```bash
   chmod +x depl.sh
   ```
3. Run `depl.sh` to set up the entire configuration:
   ```bash
   ./depl.sh
   ```
4. Source your updated shell configuration file:
   ```bash
   source ~/.bashrc  # or ~/.zshrc if you're using zsh
   ```

## Notes

- The Git and SSH configurations are set up as one-time, permanent changes via the `configure_git_ssh_passphrase()` function
- These configurations will take effect system-wide for Git and SSH operations
- You may need to restart your terminal or SSH sessions for all changes to take effect
- As always, ensure you understand the changes these scripts make before running them on your system
- It's recommended to backup your existing configurations before running `depl.sh`

## Contributing

Feel free to fork this repository and submit pull requests for any improvements or additional features you'd like to see.

## License

[Specify your chosen license here]
