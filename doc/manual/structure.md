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
    -   `network/`: Network-related documentation.
    -   `session/`: Work session summaries.
    -   `workaround/`: Documented workarounds for known issues.
-   `lib/`: Shell script libraries and modules.
    -   `alias/`: Scripts for managing dynamic and static aliases.
    -   `core/`: Core library functions (e.g., error handling `err`, verification `ver`).
    -   `depl/`: Helper libraries for deployment tasks.
    -   `dev/`: Development utilities (e.g., debugging `dbg`).
    -   `ssh`: SSH related utility functions.
    -   `util/`: General utility functions.
-   `acpi/`: Scripts and services for ACPI event handling and power management.
-   `pro/`: Utilities for one-time projects and special-case scenarios.
    -   `acpi/`: Scripts and services for ACPI event handling and power management.
    -   `replace/`: A utility for replacing text in files based on a JSON configuration.
-   `res/`: Resource files.
    -   `guideline/`: Project guidelines and standards.
    -   `prompt/`: Templates for AI interactions
-   `src/`: Source code for larger scripts or components, primarily for deployment.
    -   `depl/`: Source files for deployment modules (e.g., `gpu`, `net`, `pbs`, `pve`, `srv`, `sto`, `sys`, `usr`).
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
## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
