#!/bin/bash
#######################################################################
# Lab Environment Management System - Main Entry Point
#######################################################################
# Purpose: Primary command-line interface for the Lab system
#
# Features:
#   - Supports both Bash (4+) and Zsh (5+)
#   - Manages configuration blocks with clear markers
#   - Non-destructive updates with backup capability
#   - Interactive and non-interactive modes
#   - User-specific configuration targeting
#
# Usage:
#   ./go init          Setup/configure shell integration
#   ./go status        Check system status  
#   ./go validate      Run system validation
#   ./go help          Show detailed help
#######################################################################

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly LAB_ROOT="$SCRIPT_DIR"

# Shell injection configuration
readonly DEFAULT_CONFIG_FILES=(".zshrc" ".bashrc")
readonly INJECT_MARKER_START="# === BEGIN MANAGED BLOCK: Shell Configuration [source: lab] ==="
readonly INJECT_MARKER_END="# === END MANAGED BLOCK: Shell Configuration ==="
readonly FILEPATH="bin/ini"
readonly TMP_DIR="$SCRIPT_DIR/.tmp"
readonly SETTINGS_FILE="$TMP_DIR/go_settings"

# Runtime variables for shell injection
declare -g YES_FLAG=false
declare -g TARGET_USER=""
declare -g TARGET_HOME=""
declare -g CONFIG_FILE=""
declare -g INJECT_CONTENT=""

#######################################################################
# Shell Injection Functions
#######################################################################

# Initialize configuration for shell injection
init_injection_config() {
    local determined_bin_dir
    
    # Determine the correct bin directory for the init script
    if [[ -f "$SCRIPT_DIR/$FILEPATH" ]]; then
        determined_bin_dir="$SCRIPT_DIR"
    elif [[ -f "$SCRIPT_DIR/bin/ini" ]]; then
        determined_bin_dir="$SCRIPT_DIR"
    else
        printf "Error: Could not find ini script at expected locations\n" >&2
        return 1
    fi
    
    # Set the injection content
    INJECT_CONTENT=". ${determined_bin_dir}/${FILEPATH}"
    
    printf "Configuration initialized. Using path: %s\n" "$determined_bin_dir/$FILEPATH"
    return 0
}

# Check shell version compatibility
check_shell_version() {
    if [[ -n "${BASH_VERSION:-}" ]]; then
        [[ "${BASH_VERSION:0:1}" -lt 4 ]] && {
            printf "Error: Unsupported Bash version (need 4+)\n"
            return 1
        }
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        [[ "${ZSH_VERSION:0:1}" -lt 5 ]] && {
            printf "Error: Unsupported Zsh version (need 5+)\n"
            return 1
        }
    else
        printf "Error: Unknown shell detected\n"
        return 1
    fi
    return 0
}

# Initialize target user and home directory
init_target_user() {
    local default_user=$(whoami)
    
    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Enter target user (default: $default_user): " input_user
        TARGET_USER=${input_user:-$default_user}
    else
        TARGET_USER=$default_user
    fi
    
    TARGET_HOME=$(eval echo ~$TARGET_USER)
    if [[ ! -d "$TARGET_HOME" ]]; then
        printf "Error: Home directory %s does not exist\n" "$TARGET_HOME"
        return 1
    fi
    
    printf "Target user: %s\n" "${TARGET_USER}"
    printf "Home directory: %s\n" "${TARGET_HOME}"
    return 0
}

# Set appropriate config file
set_config_file() {
    [[ -z "$TARGET_HOME" ]] && TARGET_HOME=$(eval echo ~$(whoami))
    
    local default_config=""
    
    # Check for existing config files
    for config_file in "${DEFAULT_CONFIG_FILES[@]}"; do
        if [[ -f "$TARGET_HOME/$config_file" ]]; then
            default_config="$TARGET_HOME/$config_file"
            printf "Found %s configuration file\n" "$config_file"
            break
        fi
    done
    
    # If no config file found, use default .bashrc
    [[ -z "$default_config" ]] && default_config="$TARGET_HOME/.bashrc"
    
    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Enter config file path (default: $default_config): " input_config
        CONFIG_FILE=${input_config:-$default_config}
    else
        CONFIG_FILE=$default_config
    fi
    
    # Create config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        local config_dir=$(dirname "$CONFIG_FILE")
        if [[ ! -d "$config_dir" ]]; then
            printf "Error: Directory %s does not exist\n" "$config_dir"
            return 1
        fi
        if [[ ! -w "$config_dir" ]]; then
            printf "Error: Cannot write to directory %s\n" "$config_dir"
            return 1
        fi
        touch "$CONFIG_FILE" || {
            printf "Error: Failed to create config file %s\n" "$CONFIG_FILE"
            return 1
        }
        printf "Created new config file: %s\n" "$CONFIG_FILE"
    fi
    
    printf "Using config file: %s\n" "${CONFIG_FILE}"
    return 0
}

# Inject content into config file
inject_content() {
    printf "Processing config file '%s' for injection...\n" "$CONFIG_FILE"
    
    if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
        printf "Error: Invalid config file: %s\n" "${CONFIG_FILE}"
        return 1
    fi
    
    local temp_new_config
    temp_new_config=$(mktemp)
    if [[ -z "$temp_new_config" || ! -f "$temp_new_config" ]]; then
        printf "Error: Failed to create temporary file.\n"
        return 1
    fi
    
    # The desired block content
    local desired_block
    printf -v desired_block "%s\n%s\n%s" "$INJECT_MARKER_START" "$INJECT_CONTENT" "$INJECT_MARKER_END"
    
    # Use awk to filter out old managed blocks and any bare instance of INJECT_CONTENT
    awk -v sm="$INJECT_MARKER_START" -v em="$INJECT_MARKER_END" -v ic="$INJECT_CONTENT" '
        BEGIN { in_block = 0 }
        $0 == sm { in_block = 1; next }
        $0 == em { in_block = 0; next }
        !in_block && $0 != ic { print }
    ' "$CONFIG_FILE" > "$temp_new_config"
    
    # Ensure there's a newline before our block if temp file is not empty and doesn't end with one
    if [[ -s "$temp_new_config" ]] && [[ $(tail -c1 "$temp_new_config" | wc -l) -eq 0 ]]; then
        echo "" >> "$temp_new_config"
    fi
    
    # Append the correct, new block to temp file
    echo -e "$desired_block" >> "$temp_new_config"
    
    # Compare the newly constructed temp file with the original
    if diff -q "$CONFIG_FILE" "$temp_new_config" >/dev/null; then
        printf "Configuration file '%s' is already correct. No changes made.\n" "$CONFIG_FILE"
        rm "$temp_new_config"
        return 0 
    else
        printf "Updating configuration file '%s'.\n" "$CONFIG_FILE"
        local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$backup_file"
        if [[ $? -ne 0 ]]; then
            printf "Error: Failed to create backup file '%s'. Aborting update.\n" "$backup_file"
            rm "$temp_new_config"
            return 1
        fi
        
        mv "$temp_new_config" "$CONFIG_FILE"
        if [[ $? -ne 0 ]]; then
            printf "Error: Failed to move temporary file to '%s'. Check permissions.\n" "$CONFIG_FILE"
            cp "$backup_file" "$CONFIG_FILE" 
            rm "$temp_new_config"
            return 1
        fi
        printf "Content injection complete. Backup created at '%s'.\n" "$backup_file"
        return 0
    fi
}

# Parse command line arguments for init
parse_init_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y)
                YES_FLAG=true
                printf "Non-interactive mode enabled\n"
                shift
                ;;
            -u|--user)
                TARGET_USER="$2"
                printf "Target user set to: %s\n" "${TARGET_USER}"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                printf "Config file set to: %s\n" "${CONFIG_FILE}"
                shift 2
                ;;
            -h|--help)
                show_init_usage
                exit 0
                ;;
            *)
                printf "Error: Invalid argument: %s\n" "$1"
                show_init_usage
                exit 1
                ;;
        esac
    done
}

# Show usage for init command
show_init_usage() {
    cat << 'EOF'
Usage: ./go init [-y] [-u|--user USER] [-c|--config FILE] [-h|--help]

Setup shell integration for the Lab Environment Management System.

Options:
  -y              Non-interactive mode (yes to all prompts)
  -u, --user      Specify target user
  -c, --config    Specify config file
  -h, --help      Show this help message

Examples:
  ./go init                    # Interactive setup
  ./go init -y                 # Non-interactive setup
  ./go init -u john -y         # Setup for specific user, non-interactive
EOF
}

# Execute the shell integration setup (initialization phase)
setup_shell_integration() {
    printf "╔════════════════════════════════════════════════════════════════╗\n"
    printf "║                Lab Environment Shell Integration               ║\n"
    printf "╚════════════════════════════════════════════════════════════════╝\n\n"
    
    printf "This will configure shell integration settings and save them for later use.\n"
    printf "Settings will be saved to enable 'on/off' switching:\n"
    printf "• ./go on  - Enable shell integration\n"
    printf "• ./go off - Disable shell integration\n\n"
    
    # Check if this is the first run
    if [ ! -f "${HOME}/.lab_initialized" ]; then
        if [[ "$YES_FLAG" == "false" ]]; then
            read -p "Press Enter to continue or Ctrl+C to abort..."
        fi
        touch "${HOME}/.lab_initialized"
    fi
    
    # Execute setup steps
    printf "Step 1: Checking shell compatibility...\n"
    check_shell_version || return 1
    printf "✓ Shell compatibility verified\n\n"
    
    printf "Step 2: Initializing configuration...\n"
    init_injection_config || return 1
    printf "✓ Configuration initialized\n\n"
    
    printf "Step 3: Setting target user...\n"
    init_target_user || return 1
    printf "✓ Target user configured\n\n"
    
    printf "Step 4: Configuring shell file...\n"
    set_config_file || return 1
    printf "✓ Shell config file set\n\n"
    
    printf "Step 5: Saving settings...\n"
    save_settings || return 1
    printf "✓ Settings saved\n\n"
    
    printf "Initialization completed successfully!\n\n"
    printf "Next steps:\n"
    printf "1. Run './go on' to enable shell integration\n"
    printf "2. Run './go off' to disable shell integration\n"
    printf "3. Verify with: ./go status\n"
    printf "4. Run tests with: ./go validate\n\n"
}

show_usage() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║              Lab Environment Management System                   ║
╚══════════════════════════════════════════════════════════════════╝

A sophisticated infrastructure automation and environment management platform.

COMMANDS:
    init            Initialize and configure shell integration settings
    on              Enable shell integration (activate saved settings)
    off             Disable shell integration (remove from shell config)
    status          Check system initialization status
    validate        Run system validation tests
    help            Show detailed help and documentation
    
EXAMPLES:
    ./go init                    # First-time setup (configure settings)
    ./go on                      # Enable shell integration
    ./go off                     # Disable shell integration
    ./go status                  # Check if system is ready
    ./go validate               # Run validation tests

WORKFLOW:
    1. Run './go init' to configure settings (only needed once)
    2. Use './go on' to enable shell integration
    3. Use './go off' to disable shell integration
    4. Repeat steps 2-3 as needed

For detailed documentation, see: README.md

Settings are saved in .tmp/go_settings after running 'init'.
EOF
}

check_init_status() {
    if [[ -f "${HOME}/.lab_initialized" ]]; then
        echo "✓ Lab system has been initialized"
        
        # Check if settings file exists
        if [[ -f "$SETTINGS_FILE" ]]; then
            echo "✓ Settings file found (on/off commands available)"
        else
            echo "⚠ Settings file not found. Run './go init' to configure settings."
        fi
        
        # Check if shell integration is working
        if command -v ini >/dev/null 2>&1 || [[ -n "${LAB_ROOT:-}" ]]; then
            echo "✓ Shell integration is active"
        else
            echo "⚠ Shell integration not detected. Try restarting your shell or run: source ~/.bashrc"
        fi
        
        return 0
    else
        echo "✗ Lab system not initialized. Run: ./go init"
        return 1
    fi
}

#######################################################################
# Settings Management Functions
#######################################################################

# Save current settings to temporary file
save_settings() {
    # Create .tmp directory if it doesn't exist
    if [[ ! -d "$TMP_DIR" ]]; then
        mkdir -p "$TMP_DIR" || {
            printf "Error: Failed to create temporary directory: %s\n" "$TMP_DIR" >&2
            return 1
        }
        printf "Created temporary directory: %s\n" "$TMP_DIR"
    fi
    
    local settings_content
    settings_content=$(cat << EOF
TARGET_USER="$TARGET_USER"
TARGET_HOME="$TARGET_HOME"
CONFIG_FILE="$CONFIG_FILE"
INJECT_CONTENT="$INJECT_CONTENT"
EOF
)
    
    echo "$settings_content" > "$SETTINGS_FILE"
    printf "Settings saved to: %s\n" "$SETTINGS_FILE"
    return 0
}

# Load settings from temporary file
load_settings() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        printf "Error: Settings file not found: %s\n" "$SETTINGS_FILE" >&2
        printf "Please run './go init' first to generate settings.\n" >&2
        return 1
    fi
    
    # Source the settings file
    source "$SETTINGS_FILE"
    
    # Validate that required variables are set
    if [[ -z "$TARGET_USER" || -z "$TARGET_HOME" || -z "$CONFIG_FILE" || -z "$INJECT_CONTENT" ]]; then
        printf "Error: Invalid settings found in %s\n" "$SETTINGS_FILE" >&2
        printf "Please run './go init' to regenerate settings.\n" >&2
        return 1
    fi
    
    printf "Settings loaded from: %s\n" "$SETTINGS_FILE"
    printf "Target user: %s\n" "$TARGET_USER"
    printf "Config file: %s\n" "$CONFIG_FILE"
    return 0
}

# Remove injection content from config file
remove_content() {
    printf "Removing lab integration from config file '%s'...\n" "$CONFIG_FILE"
    
    if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
        printf "Error: Invalid config file: %s\n" "${CONFIG_FILE}"
        return 1
    fi
    
    local temp_new_config
    temp_new_config=$(mktemp)
    if [[ -z "$temp_new_config" || ! -f "$temp_new_config" ]]; then
        printf "Error: Failed to create temporary file.\n"
        return 1
    fi
    
    # Use awk to filter out managed blocks and any bare instance of INJECT_CONTENT
    awk -v sm="$INJECT_MARKER_START" -v em="$INJECT_MARKER_END" -v ic="$INJECT_CONTENT" '
        BEGIN { in_block = 0 }
        $0 == sm { in_block = 1; next }
        $0 == em { in_block = 0; next }
        !in_block && $0 != ic { print }
    ' "$CONFIG_FILE" > "$temp_new_config"
    
    # Compare the newly constructed temp file with the original
    if diff -q "$CONFIG_FILE" "$temp_new_config" >/dev/null; then
        printf "Configuration file '%s' has no lab integration to remove.\n" "$CONFIG_FILE"
        rm "$temp_new_config"
        return 0 
    else
        printf "Removing lab integration from configuration file '%s'.\n" "$CONFIG_FILE"
        local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$backup_file"
        if [[ $? -ne 0 ]]; then
            printf "Error: Failed to create backup file '%s'. Aborting update.\n" "$backup_file"
            rm "$temp_new_config"
            return 1
        fi
        
        mv "$temp_new_config" "$CONFIG_FILE"
        if [[ $? -ne 0 ]]; then
            printf "Error: Failed to move temporary file to '%s'. Check permissions.\n" "$CONFIG_FILE"
            cp "$backup_file" "$CONFIG_FILE" 
            rm "$temp_new_config"
            return 1
        fi
        printf "Lab integration removed successfully. Backup created at '%s'.\n" "$backup_file"
        return 0
    fi
}

# Handle the "on" command - enable shell integration
handle_on_command() {
    printf "╔════════════════════════════════════════════════════════════════╗\n"
    printf "║                 Enabling Shell Integration                     ║\n"
    printf "╚════════════════════════════════════════════════════════════════╝\n\n"
    
    # Load settings from .tmp file
    load_settings || return 1
    
    printf "Enabling lab integration...\n"
    inject_content || return 1
    
    printf "\n✓ Shell integration enabled successfully!\n\n"
    printf "Next steps:\n"
    printf "1. Restart your shell or run: source %s\n" "$CONFIG_FILE"
    printf "2. Verify with: ./go status\n\n"
}

# Handle the "off" command - disable shell integration
handle_off_command() {
    printf "╔════════════════════════════════════════════════════════════════╗\n"
    printf "║                Disabling Shell Integration                     ║\n"
    printf "╚════════════════════════════════════════════════════════════════╝\n\n"
    
    # Load settings from .tmp file
    load_settings || return 1
    
    printf "Disabling lab integration...\n"
    remove_content || return 1
    
    printf "\n✓ Shell integration disabled successfully!\n\n"
    printf "To re-enable, run: ./go on\n\n"
}

main() {
    case "${1:-help}" in
        init|setup)
            parse_init_arguments "${@:2}"
            setup_shell_integration
            ;;
        status)
            check_init_status
            ;;
        validate|test)
            if check_init_status >/dev/null; then
                if [[ -f "${LAB_ROOT}/val/validate_system" ]]; then
                    exec "${LAB_ROOT}/val/validate_system" "${@:2}"
                elif [[ -f "${LAB_ROOT}/val/run_all_tests.sh" ]]; then
                    exec "${LAB_ROOT}/val/run_all_tests.sh" "${@:2}"
                else
                    echo "Validation scripts not found"
                    exit 1
                fi
            else
                echo "Please run './go init' first"
                exit 1
            fi
            ;;
        on)
            handle_on_command
            ;;
        off)
            handle_off_command
            ;;
        help|--help|-h)
            show_usage
            echo ""
            echo "For more detailed documentation:"
            echo "  • README.md - System overview and architecture"
            echo "  • doc/ - Complete technical documentation"
            echo "  • val/ - Validation and testing framework"
            ;;
        *)
            echo "Unknown command: ${1:-}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
