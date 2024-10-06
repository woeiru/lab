# Shell Configuration and Deployment Scripts

This directory contains scripts and configurations for customizing and deploying shell environments, particularly focused on Bash and Zsh setups.

## Contents

1. [depl.sh](#deplsh)
2. [inject](#inject)

## depl.sh

The main deployment script that sets up the shell configuration.

### Functionality:
- Sources necessary library files from the project structure
- Configures Git and SSH settings
- Injects custom configurations into the user's shell configuration file (.bashrc or .zshrc)
- Checks for existing configurations before making changes

### Usage:
```bash
./depl.sh
```

## inject

Contains aliases, functions, and configurations that will be injected into your shell environment.

### Features:
- Sources user-specific configuration files
- Provides aliases for common tasks and customizations
- Includes system-specific configurations

## Installation

1. Ensure you have the correct project structure with necessary library files.

2. Make sure the `depl.sh` script is executable:
   ```bash
   chmod +x depl.sh
   ```

3. Run `depl.sh` to set up the entire configuration:
   ```bash
   ./depl.sh
   ```

4. After running the script, source your updated shell configuration file:
   ```bash
   source ~/.bashrc  # or ~/.zshrc if you're using zsh
   ```

Note: The `depl.sh` script is designed to work relative to its location in the project structure. You can run it from this directory or provide the full path from anywhere in your system.

## Notes

- The configurations set up by this script may affect your shell environment and system-wide operations.
- You may need to restart your terminal or SSH sessions for all changes to take effect.
- Always review the script and injected content before running to ensure it meets your needs.
- It's recommended to backup your existing shell configurations before running `depl.sh`.

## Customization

To customize the injected content, modify the `inject` file in this directory. You can add or remove aliases, functions, or any other shell configurations as needed.

## Contributing

Feel free to fork this repository and submit pull requests for any improvements or additional features you'd like to see.

## License

[Specify your chosen license here]
