# Shell Scripts and Configurations

This repository contains shell scripts and configuration files for customizing and managing a Linux environment, particularly focused on KDE Plasma desktop, Git, and SSH configurations.

## Directory Structure

```
ini/
└── user/
    ├── depl.sh
    ├── inject
    └── readme.md
lib/
└── usr.bash
```

## Contents

1. [depl.sh](#deplsh)
2. [usr.bash](#usrbash)
3. [inject](#inject)

## depl.sh

The main deployment script that sets up the entire configuration.

### Functionality:
- Sources `usr.bash` from the `lib` folder
- Runs configuration functions to set up various system settings
- Injects the content of `inject` into `.bashrc` or `.zshrc`
- Checks for existing configurations before making changes

### Usage:
```bash
./depl.sh
```

## usr.bash

Located in the `lib` folder, this file contains utility functions for system configuration. These functions can be used to customize various aspects of the system, including but not limited to Konsole profiles, Git settings, and SSH configurations.

## inject

Contains aliases and configurations that will be injected into your shell environment.

### Features:
- Sources `usr.bash` from the `lib` folder
- Provides aliases for common tasks and customizations
- Includes system-specific configurations

## Installation

1. Ensure you're in the `ini/user` directory.
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

- The configurations set up by this script may affect system-wide operations
- You may need to restart your terminal or SSH sessions for all changes to take effect
- As always, ensure you understand the changes these scripts make before running them on your system
- It's recommended to backup your existing configurations before running `depl.sh`

## Contributing

Feel free to fork this repository and submit pull requests for any improvements or additional features you'd like to see.

## License

[Specify your chosen license here]
