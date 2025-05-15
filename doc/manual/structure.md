# Project Structure and Architecture

This document outlines the overall structure of the Lab Environment project, explaining the purpose of each directory and key components within the system.

## Directory Structure

The project follows a domain-oriented architecture with these main directories:

-   `bin/`: Executable scripts and entry points.
    -   `init`: Main initialization script.
    -   `core/`: Core system components (e.g., `comp` - component orchestrator).
    -   `depl/`: Deployment scripts for various services (`dsk`, `nfs`, `pbs`, `pve`, `smb`).
    -   `env/`: Environment setup scripts, including `inject` which configures shell environments.
-   `cfg/`: Configuration files and definitions.
    -   `ans/`: Ansible playbooks and configurations.
        -   `main.yml`, `vars.yml`: Main playbook and variable definitions.
        -   `mods/`: Module-specific configurations (`askpass.yml`, `keyboard.yml`, `konsole.yml`, etc.).
    -   `core/`: Core configuration files (`mdc`, `rdc`, `ric` - runtime initialization constants).
    -   `depl/`: Deployment-related configurations (e.g., `site1.env` with environment variables).
    -   `pod/`: Podman container configurations with `Containerfile`s and documentation.
-   `doc/`: Documentation files.
    -   `manual/`: User and developer manuals (`initiation.md`, `logging.md`, `structure.md`).
    -   `network/`: Network architecture and configuration documentation.
    -   `session/`: Work session summaries and progress tracking.
    -   `workaround/`: Solutions for known issues and special cases.
-   `lib/`: Shell script libraries and reusable modules.
    -   `alias/`: Scripts for managing dynamic and static aliases and wrappers.
    -   `aux/`: Auxiliary binaries and source files.
    -   `core/`: Core library functions (e.g., `ver` for version management).
    -   `ssh`: SSH-related utility functions.
    -   `util/`: General utilities (`err` for error handling, `lo1`/`lo2` for logging, `tme` for timing).
    -   `depl/`: Source files for deployment modules (`gpu`, `net`, `pbs`, `pve`, `srv`, `sto`, `sys`, `usr`).
-   `pro/`: Special projects and standalone utilities.
    -   `acpi/`: Scripts and services for ACPI event handling and power management.
    -   `replace/`: A utility for replacing text in files based on a JSON configuration.
-   `res/`: Resource files and templates.
    -   `guideline/`: Project guidelines, coding standards, and architectural principles.
    -   `prompt/`: Templates for AI interactions and code generation.
-   `entry.sh`: Root-level symlink to `bin/env/inject` for easy environment setup.
-   `README.md`: Main project documentation and quick start guide.

## Key Components & Usage

### Environment Setup and Initialization

-   **`entry.sh`**: A symlink to `bin/env/inject` for easy access to the environment setup utility.
-   **`bin/env/inject`**: The primary script that configures shell environments by injecting initialization code into shell config files (`.bashrc` or `.zshrc`).
    -   Supports both interactive and non-interactive modes.
    -   Creates non-destructive and reversible modifications to shell configuration files.
    -   Takes command-line options `-y` (non-interactive), `-u`/`--user` (target user), and `-c`/`--config` (config file).
-   **`bin/init`**: Main initialization script. This is automatically sourced when a shell starts after the environment is set up.

### Core Modules

-   **Error Handling (`lib/util/err`)**: Provides error trapping and handling mechanisms.
-   **Logging (`lib/util/lo1`, `lib/util/lo2`)**: Advanced logging systems with support for module-specific debug and control features.
-   **Timing (`lib/util/tme`)**: Performance monitoring and reporting.
-   **Component Orchestration (`bin/core/comp`)**: Manages loading and initialization of system components.

### Deployment System

-   **Scripts**: Located in `bin/depl/` for deploying and managing various services.
-   **Configurations**: Found in `cfg/depl/`, including environment variables in `site1.env`.
-   **Source Modules**: Available in `lib/depl/` with specialized modules for different system areas:
    -   `gpu`: GPU-related functionality
    -   `net`: Network configuration and management
    -   `pbs`: PBS (Portable Batch System) functionality
    -   `pve`: Proxmox VE management
    -   `srv`: Server configuration
    -   `sto`: Storage management
    -   `sys`: System-level operations
    -   `usr`: User management

### Ansible Integration

-   **Playbooks**: Located in `cfg/ans/` with `main.yml` as the primary entry point.
-   **Variables**: Managed in `cfg/ans/vars.yml` for centralized configuration.
-   **Modules**: Specialized Ansible modules in `cfg/ans/mods/` for specific tasks like keyboard configuration, KDE components, etc.
-   **Usage**: Run playbooks using `ansible-playbook cfg/ans/main.yml` (adjust as needed).

### Container Management

-   **Definitions**: Podman container configurations in `cfg/pod/`.
-   **Containers**:
    -   `qdev`: Development environment container with accompanying scripts.
    -   `shus`: Likely a service container with SMB configuration capabilities.
-   **Documentation**: Each container directory includes a `readme.md` with usage instructions.

### Utility Libraries

-   **Alias Management**: The `lib/alias` directory provides utilities to create and manage:
    -   Static aliases (`static`): Fixed command shortcuts
    -   Dynamic aliases (`dynamic`): Contextually generated shortcuts
    -   Alias wrappers (`wrap`): For wrapping commands with additional functionality

-   **SSH Utilities**: SSH-related tools and functions in the `lib/ssh` directory.

### Special Projects

-   **ACPI Management**: Scripts in `pro/acpi/` for power management:
    -   `deploy.sh`: Deployment script for ACPI services
    -   `disable-devices-as-wakeup.service`: Systemd service to control wake-up devices
    -   `post-wake-usb-reset.service`: Service to handle USB devices after system wake

-   **File Replacement Tool**: Utility in `pro/replace/` for text substitution in files:
    -   Configuration-driven using JSON format
    -   Useful for templating and configuration management

## Configuration System

The configuration system is organized hierarchically:

-   **Core Configurations** (`cfg/core/`):
    -   `ric`: Runtime Initialization Constants, defining global variables and paths
    -   `mdc`: Module Definition Constants
    -   `rdc`: Runtime Definition Constants

-   **Deployment Configurations** (`cfg/depl/`):
    -   `site1.env`: Environment variables for deployment scripts

-   **Ansible Configuration** (`cfg/ans/`):
    -   `vars.yml`: Centralized variables for all playbooks
    -   Module-specific configurations in `mods/` subdirectory

-   **Container Configurations** (`cfg/pod/`):
    -   Each container has its own directory with Containerfiles and related scripts

## Documentation Resources

-   **User Manuals** (`doc/manual/`):
    -   `initiation.md`: User interaction and configuration guide
    -   `logging.md`: Logging system documentation
    -   `structure.md`: This document explaining project organization

-   **Network Documentation** (`doc/network/`):
    -   Network architecture and configuration resources

-   **Workarounds** (`doc/workaround/`):
    -   Documented solutions for specific issues (e.g., `audioroot.md`)

-   **Session Records** (`doc/session/`):
    -   Chronological work session summaries and progress tracking

-   **Guidelines** (`res/guideline/`):
    -   Architectural principles and coding standards
    -   Framework documentation and organizational guidelines

## Getting Started

1. Use the `entry.sh` symlink (or directly run `bin/env/inject`) to set up your shell environment.
2. After environment setup and shell restart, the system is automatically initialized with each new shell session.
3. Refer to `doc/manual/initiation.md` for detailed information on configuration options and runtime controls.

## License

This project is licensed under the MIT License - see the LICENSE file in the project root for details.
