# Lab Environment Setup

This is a modular environment setup system that provides a structured way to manage your shell configuration and system initialization. It aims to create a consistent and efficient development and operational environment.

## Features

*   **Modular Design:** Easily extendable and maintainable.
*   **Shell Integration:** Configures Bash (4+) and Zsh (5+) environments.
*   **Automated Setup:** Streamlines the process of setting up directories and loading modules.
*   **Core Utilities:** Provides essential system utilities.
*   **Deployment Scripts:** Includes tools for various deployment tasks (PVE, NFS, SMB, PBS, DSK).
*   **Configuration Management:** Centralized configuration for different components, including Ansible playbooks.
*   **Container Support:** Configurations for Podman containers.
*   **Extensive Libraries:** A rich set of shell libraries for common tasks.
*   **Testing Framework:** Uses BATS for automated testing.

## Prerequisites

-   Bash version 4 or higher, or Zsh version 5 or higher.
-   Standard Unix/Linux utilities.
-   `bats` for running tests (see Testing section).

## Quick Start

To set up your environment, run the main injection script or use the `entry.sh` symlink:

```bash
bin/env/inject
# or
./entry.sh
```

Running the `bin/env/inject` or `./entry.sh` command performs the following actions:
1.  **Verifies shell compatibility** (Bash 4+ or Zsh 5+).
2.  **Modifies your shell's configuration file** (e.g., `.bashrc` or `.zshrc`). It adds a line that will source the `/home/es/lab/bin/init` script every time a new shell starts.
3.  **Restarts your shell.**

Upon shell restart, the now-modified shell configuration file will automatically execute (source) the `/home/es/lab/bin/init` script. This `init` script is then responsible for the main environment setup tasks:
-   Configuring your shell environment further by sourcing relevant library files.
-   Setting up necessary directories within the project structure.
-   Loading required modules and libraries.

In essence, `bin/env/inject` sets up the persistent mechanism for initialization, and the actual environment configuration happens when `bin/init` is sourced by a new shell session.

Other initialization scripts are available in `bin/`:
-   `bin/init`: Standard initialization, suitable for most use cases.
-   `bin/silent_init`: Initialization with minimal output, ideal for scripting or when a quiet setup is preferred.
-   `bin/verbose_init`: Initialization with detailed output, useful for debugging or understanding the setup process.

## Directory Structure

The project is organized as follows:

-   `bin/`: Executable scripts.
    -   `init`, `silent_init`, `verbose_init`: Main initialization scripts.
    -   `core/`: Core system components (e.g., `comp`).
    -   `depl/`: Deployment scripts for various services (e.g., `dsk`, `nfs`, `pbs`, `pve`, `smb`).
    -   `env/`: Environment setup scripts (e.g., `inject`).
-   `cfg/`: Configuration files.
    -   `ans/`: Ansible playbooks and configurations (e.g., `main.yml`, `vars.yml`).
    -   `core/`: Configuration for core components (e.g., `mdc`, `rdc`, `ric`).
    -   `depl/`: Deployment-related configurations (e.g., `site.env`).
    -   `pod/`: Podman container configurations and related files (e.g., `Containerfile` for `qdev`, `shus`).
-   `doc/`: Documentation.
    -   `guideline/`: Project guidelines and standards.
    -   `network/`: Network-related documentation.
    -   `session/`: Work session summaries.
    -   `workaround/`: Documented workarounds for known issues.
-   `lib/`: Shell script libraries and modules.
    -   `alias/`: Scripts for managing dynamic and static aliases.
    -   `core/`: Core library functions (e.g., error handling `err`, versioning `ver`).
    -   `depl/`: Helper libraries for deployment tasks.
    -   `dev/`: Development utilities (e.g., debugging `dbg`).
    -   `ssh`: SSH related utility functions.
    -   `util/`: General utility functions.
-   `pro/`: Project-specific utilities and professional setups.
    -   `acpi/`: Scripts and services for ACPI event handling and power management.
    -   `replace/`: A utility for replacing text in files based on a JSON configuration.
-   `res/`: Resource files.
    -   `prompt/`: Templates or prompts, possibly for AI interactions or code generation.
-   `src/`: Source code for larger scripts or components, primarily for deployment.
    -   `depl/`: Source files for deployment modules (e.g., `gpu`, `net`, `pbs`, `pve`, `srv`, `sto`, `sys`, `usr`).
-   `test/`: Automated tests.
    -   `lib/`: Tests for library components (e.g., `test_dbg.bats`).
    -   `test_helper/`: BATS helper libraries (`bats-assert`, `bats-file`, `bats-support`).
-   `entry.sh`: Root-level entry script (purpose to be documented or inferred).
-   `README.md`: This file.

## Key Components & Usage

### Environment Initialization
-   **`bin/env/inject`**: The primary script to set up and configure the shell environment.
-   The scripts in `bin/` (`init`, `silent_init`, `verbose_init`) handle different aspects or modes of system initialization.

### Deployment
-   Scripts in `bin/depl/` are used to deploy and manage various services.
-   Configurations for these deployments can be found in `cfg/depl/` and source files in `src/depl/`.

### Ansible Automation
-   Ansible playbooks are located in `cfg/ans/`.
-   Run playbooks using `ansible-playbook cfg/ans/main.yml` (adjust as needed).
-   Variables are typically managed in `cfg/ans/vars.yml`.

### Container Management
-   Podman container definitions are in `cfg/pod/`.
-   Each subdirectory (e.g., `qdev`, `shus`) usually contains a `Containerfile` and a `readme.md`.

### Libraries
-   The `lib/` directory contains a wealth of shell functions. These are typically sourced by the environment setup scripts.
    -   `lib/core/err`: For error handling.
    -   `lib/core/ver`: For version management.
    -   `lib/dev/dbg`: For debugging shell scripts.

## Configuration

-   Global and component-specific configurations are stored in the `cfg/` directory.
-   `cfg/core/`: Configurations for core functionalities.
-   `cfg/depl/site.env`: Likely contains environment variables for deployment scripts.
-   `cfg/ans/vars.yml`: Variables for Ansible playbooks.
-   Individual tools or modules may have their own configuration files within their respective subdirectories.

## Testing

-   Automated tests are written using the [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) framework.
-   Test files are located in the `test/` directory (e.g., `test/lib/dev/test_dbg.bats`).
-   Helper libraries for BATS (`bats-assert`, `bats-file`, `bats-support`) are included in `test/test_helper/`.
-   To run all tests, you might navigate to the `test/` directory and execute `bats .` or run specific test files like `bats test/lib/dev/test_dbg.bats`. (Consult BATS documentation for more detailed instructions on running tests).

## Documentation

Detailed documentation can be found in the `doc/` directory:
-   **Guidelines:** `doc/guideline/` - Contains coding standards, architectural principles, and other guidelines.
-   **Network Information:** `doc/network/` - Documentation related to network setup or concepts.
-   **Workarounds:** `doc/workaround/` - Solutions for specific issues encountered.
-   **Session Summaries:** `doc/session/` - Contains work session summaries, which might be useful for tracking progress or decisions.

(Note: Previous links to `doc/architectural/` and `doc/unsorted/Domain-First Directory Architecture: Theoretical Framework.md` have been removed as these paths were not found in the current project structure.)

## Contributing

Please refer to the guidelines in `doc/guideline/` before contributing. (If a specific contribution guide exists, link it here).

## License

(Specify the license for your project here, if applicable)
