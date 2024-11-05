# Portable Application Development Guide with Three-Letter Directory Structure

## Table of Contents
- [1. Base Directory Structure](#1-base-directory-structure)
- [2. Core System Components](#2-core-system-components)
- [3. Implementation Examples](#3-implementation-examples)
- [4. Best Practices](#4-best-practices)
- [5. Common Patterns](#5-common-patterns)
- [6. Project Setup Scenarios](#6-project-setup-scenarios)

## 1. Base Directory Structure

### Standard Three-Letter Directory Layout
```
app/                    # Application root
├── bin/               # Binaries and executables
├── cfg/               # Configuration files
├── dat/               # Application data
├── doc/               # Documentation
├── lib/               # Libraries
├── log/               # Log files
├── res/               # Resources
├── src/               # Source code
├── tmp/               # Temporary files
└── var/               # Variable data
```

### Directory Purposes
```bash
# Directory definitions
DIRS=(
    "bin"  # Executables and scripts
    "cfg"  # Configuration files
    "dat"  # Application data storage
    "doc"  # Documentation and help files
    "lib"  # Shared libraries and dependencies
    "log"  # Log files and debug info
    "res"  # Static resources (images, templates)
    "src"  # Source code
    "tmp"  # Temporary files
    "var"  # Variable/runtime data
)
```

## 2. Core System Components

### Base Directory Detection
```bash
#!/bin/bash

# Get absolute path of script directory
get_base_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir=""
    
    # Resolve symlinks
    while [ -h "$source" ]; do
        dir="$( cd -P "$( dirname "$source" )" && pwd )"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    
    echo "$( cd -P "$( dirname "$source" )" && pwd )"
}
```

### Project Environment Setup
```bash
# Initialize project environment
init_project_env() {
    # Set up base directories
    export BASE_DIR="$(get_base_dir)"
    export BIN_DIR="${BASE_DIR}/bin"
    export CFG_DIR="${BASE_DIR}/cfg"
    export DAT_DIR="${BASE_DIR}/dat"
    export DOC_DIR="${BASE_DIR}/doc"
    export LIB_DIR="${BASE_DIR}/lib"
    export LOG_DIR="${BASE_DIR}/log"
    export RES_DIR="${BASE_DIR}/res"
    export SRC_DIR="${BASE_DIR}/src"
    export TMP_DIR="${BASE_DIR}/tmp"
    export VAR_DIR="${BASE_DIR}/var"

    # Add project's bin directory to PATH
    export PATH="${BIN_DIR}:${PATH}"
    
    # Add project's lib directory to library path
    export LD_LIBRARY_PATH="${LIB_DIR}:${LD_LIBRARY_PATH}"
    
    # Set up application-specific environment variables
    export APP_ROOT="${BASE_DIR}"
    export APP_CONFIG="${CFG_DIR}/app.conf"
    export APP_TEMP="${TMP_DIR}"
    export APP_DATA="${DAT_DIR}"
    export APP_VAR="${VAR_DIR}"

    # Verify critical directories exist
    local required_dirs=("$BIN_DIR" "$CFG_DIR" "$LIB_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            echo "Error: Required directory $dir does not exist!"
            return 1
        fi
    done

    echo "Project environment initialized at: ${BASE_DIR}"
    return 0
}
```

### Directory Structure Creation (For New Projects)
```bash
create_structure() {
    local base="$1"
    local dirs=(
        "bin" "cfg" "dat" "doc" "lib"
        "log" "res" "src" "tmp" "var"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "${base}/${dir}"
        chmod 755 "${base}/${dir}"
    done
    
    # Set specific permissions
    chmod 700 "${base}/cfg"  # Restrict config access
    chmod 700 "${base}/tmp"  # Secure temp directory
}
```

## 3. Implementation Examples

### Configuration Management
```bash
# Read config from cfg dir
read_cfg() {
    local key="$1"
    local cfg_file="${CFG_DIR}/app.conf"
    
    if [[ -f "$cfg_file" ]]; then
        grep "^${key}=" "$cfg_file" | cut -d'=' -f2-
    fi
}

# Write config to cfg dir
write_cfg() {
    local key="$1"
    local value="$2"
    local cfg_file="${CFG_DIR}/app.conf"
    
    # Remove existing key
    sed -i "/^${key}=/d" "$cfg_file"
    # Add new value
    echo "${key}=${value}" >> "$cfg_file"
}
```

### Resource Handling
```bash
# Load resource from res dir
load_res() {
    local name="$1"
    local res_path="${RES_DIR}/${name}"
    
    if [[ -f "$res_path" ]]; then
        cat "$res_path"
    else
        return 1
    fi
}

# Save resource to res dir
save_res() {
    local name="$1"
    local content="$2"
    local res_path="${RES_DIR}/${name}"
    
    echo "$content" > "$res_path"
}
```

### Logging System
```bash
# Write to log dir
log_msg() {
    local level="$1"
    local msg="$2"
    local log_file="${LOG_DIR}/app.log"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    echo "[${timestamp}] [${level}] ${msg}" >> "$log_file"
}

# Log rotation
rotate_log() {
    local max_size=$((1024 * 1024))  # 1MB
    local log_file="${LOG_DIR}/app.log"
    
    if [[ -f "$log_file" && $(stat -f%z "$log_file") -gt $max_size ]]; then
        mv "$log_file" "${log_file}.old"
    fi
}
```

## 4. Best Practices

### Path Handling
```bash
# Always use relative paths from base dir
get_path() {
    local rel_path="$1"
    echo "${BASE_DIR}/${rel_path}"
}

# Clean path joining
join_path() {
    local IFS="/"
    echo "$*"
}

# Safe file operations
safe_write() {
    local target="$1"
    local content="$2"
    local tmp_file="${TMP_DIR}/$(uuid)"
    
    echo "$content" > "$tmp_file"
    mv "$tmp_file" "$target"
}
```

### Data Management
```bash
# Store data in dat dir
store_data() {
    local key="$1"
    local value="$2"
    local data_file="${DAT_DIR}/data.db"
    
    echo "${key}:${value}" >> "$data_file"
}

# Read data from dat dir
read_data() {
    local key="$1"
    local data_file="${DAT_DIR}/data.db"
    
    grep "^${key}:" "$data_file" | cut -d':' -f2-
}
```

## 5. Common Patterns

### Complete Application Template
```bash
#!/bin/bash

# Source environment setup
source "$(dirname "$0")/init-env.sh"

# Application class
class_App() {
    init() {
        log_msg "INFO" "Initializing application"
        # Load config from cfg dir
        source "${CFG_DIR}/app.conf"
    }
    
    run() {
        log_msg "INFO" "Running application"
        # Application logic
    }
    
    cleanup() {
        log_msg "INFO" "Cleaning up"
        # Clean tmp dir
        rm -rf "${TMP_DIR}"/*
    }
}

# Create app instance
app=$(class_App)

# Main entry point
main() {
    trap "$app cleanup" EXIT
    $app init
    $app run
}

# Run if script
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
```

## 6. Project Setup Scenarios

### New Project Setup
For creating a new project from scratch:

1. Create a new directory for your project
2. Copy the `create_structure()` function and run it
3. Initialize git repository
4. Add the environment setup script

Example:
```bash
mkdir my-project
cd my-project
# Copy create_structure function and run it
create_structure "$(pwd)"
git init
# Copy init-env.sh script
```

### Existing Project Setup (Git Clone)
For working with an existing project:

1. Clone the repository
2. Source the environment setup script:

```bash
git clone <repository-url>
cd <project-directory>
source init-env.sh
```

The environment setup script (`init-env.sh`) should be placed in your project root:
```bash
#!/bin/bash

# Copy the get_base_dir() and init_project_env() functions here
# [Previous code from Project Environment Setup section]

# Source this script to initialize the environment
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_project_env
else
    echo "This script should be sourced, not executed directly."
    echo "Usage: source ${BASH_SOURCE[0]}"
    exit 1
fi
```

### Usage Examples
```bash
# Configuration
write_cfg "app_name" "MyApp"
app_name="$(read_cfg "app_name")"

# Resource handling
save_res "template.txt" "Hello, {{name}}!"
template="$(load_res "template.txt")"

# Data storage
store_data "user_pref" "dark_mode"
pref="$(read_data "user_pref")"

# Logging
log_msg "INFO" "Application started"
rotate_log
```

### Error Handling
```bash
handle_error() {
    local code="$1"
    local msg="$2"
    
    log_msg "ERROR" "$msg"
    
    case "$code" in
        1) # Config error
            cp "${CFG_DIR}/default.conf" "${CFG_DIR}/app.conf"
            ;;
        2) # Resource error
            mkdir -p "${RES_DIR}"
            ;;
        *) # General error
            ;;
    esac
    
    return "$code"
}
```

Key Features:
- Three-letter directory names for clarity and consistency
- Clear separation of concerns
- Modular design
- Portable environment setup
- Secure file operations
- Comprehensive logging
- Error handling
- Resource management
- Configuration system
- Data storage patterns
- Support for both new and existing projects
