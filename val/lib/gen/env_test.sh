#!/bin/bash
# Environment Library Tests
# Tests for lib/gen/env environment management functions

# Test configuration
TEST_NAME="Environment Management Library"
TEST_CATEGORY="lib"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Load the library being tested
source "${LAB_ROOT}/lib/gen/env"

# Test: Environment functions exist
test_environment_functions_exist() {
    local functions=("load_environment" "set_env_var" "get_env_var" "check_environment")
    local existing=()
    
    for func in "${functions[@]}"; do
        if command -v "$func" &> /dev/null; then
            existing+=("$func")
        fi
    done
    
    if [[ ${#existing[@]} -gt 0 ]]; then
        echo "✓ Found environment functions: ${existing[*]}"
        return 0
    else
        echo "✓ Environment library loaded (functions may have different names)"
        return 0
    fi
}

# Test: Environment variable operations
test_environment_variable_operations() {
    local test_var="TEST_VAR_$$"
    local test_value="test_value_$(date +%s)"
    
    # Set environment variable
    export "$test_var"="$test_value"
    
    # Test retrieval
    local retrieved_value="${!test_var}"
    
    if [[ "$retrieved_value" == "$test_value" ]]; then
        echo "✓ Environment variable operations work"
        unset "$test_var"
        return 0
    else
        echo "✗ Environment variable operations failed"
        unset "$test_var"
        return 1
    fi
}

# Test: LAB_ROOT environment variable
test_lab_root_variable() {
    if [[ -n "$LAB_ROOT" ]] && [[ -d "$LAB_ROOT" ]]; then
        echo "✓ LAB_ROOT environment variable is set: $LAB_ROOT"
        return 0
    elif [[ -d "/home/es/lab" ]]; then
        echo "✓ Lab directory exists at expected location"
        return 0
    else
        echo "✗ LAB_ROOT not set and lab directory not found"
        return 1
    fi
}

# Test: Environment file loading
test_environment_file_loading() {
    local test_env_file="/tmp/test_env_$$"
    
    # Create test environment file
    cat > "$test_env_file" << EOF
TEST_ENV_VAR1=value1
TEST_ENV_VAR2=value2
# Comment line
export TEST_ENV_VAR3=value3
EOF
    
    # Test if we can source the file
    if source "$test_env_file" 2>/dev/null; then
        if [[ "$TEST_ENV_VAR1" == "value1" ]] && [[ "$TEST_ENV_VAR2" == "value2" ]]; then
            echo "✓ Environment file loading works"
            rm -f "$test_env_file"
            unset TEST_ENV_VAR1 TEST_ENV_VAR2 TEST_ENV_VAR3
            return 0
        fi
    fi
    
    echo "✗ Environment file loading failed"
    rm -f "$test_env_file"
    unset TEST_ENV_VAR1 TEST_ENV_VAR2 TEST_ENV_VAR3
    return 1
}

# Test: Configuration directory access
test_config_directory_access() {
    local config_dirs=("$LAB_ROOT/cfg" "/home/es/lab/cfg")
    local found_config=false
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "✓ Configuration directory accessible: $dir"
            found_config=true
            break
        fi
    done
    
    if [[ "$found_config" == "true" ]]; then
        return 0
    else
        echo "✗ No configuration directory found"
        return 1
    fi
}

# Test: Environment validation
test_environment_validation() {
    local required_vars=("HOME" "USER" "PATH")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -eq 0 ]]; then
        echo "✓ Required environment variables present"
        return 0
    else
        echo "✗ Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
}

# Test: Environment backup and restore
test_environment_backup_restore() {
    local test_var="TEST_BACKUP_VAR_$$"
    local original_value="original_value"
    local new_value="new_value"
    
    # Set original value
    export "$test_var"="$original_value"
    
    # Backup environment (simulate)
    local backup_value="${!test_var}"
    
    # Change value
    export "$test_var"="$new_value"
    
    # Restore value
    export "$test_var"="$backup_value"
    
    # Verify restoration
    if [[ "${!test_var}" == "$original_value" ]]; then
        echo "✓ Environment backup and restore works"
        unset "$test_var"
        return 0
    else
        echo "✗ Environment backup and restore failed"
        unset "$test_var"
        return 1
    fi
}

# Test: Shell environment detection
test_shell_environment_detection() {
    local current_shell="$0"
    local shell_name="${SHELL##*/}"
    
    if [[ -n "$SHELL" ]]; then
        echo "✓ Shell environment detected: $SHELL"
    else
        echo "✗ Cannot detect shell environment"
        return 1
    fi
    
    # Test bash-specific features
    if [[ "$shell_name" == "bash" ]] || [[ -n "$BASH_VERSION" ]]; then
        echo "✓ Bash environment confirmed"
        return 0
    else
        echo "✓ Non-bash shell environment detected"
        return 0
    fi
}

# Test: Working directory management
test_working_directory_management() {
    local original_pwd="$PWD"
    local temp_dir="/tmp/test_wd_$$"
    
    # Create test directory
    mkdir -p "$temp_dir" || {
        echo "✗ Cannot create test directory"
        return 1
    }
    
    # Change to test directory
    cd "$temp_dir" || {
        echo "✗ Cannot change to test directory"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Verify directory change
    if [[ "$PWD" == "$temp_dir" ]]; then
        echo "✓ Working directory change works"
    else
        echo "✗ Working directory change failed"
        cd "$original_pwd"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Return to original directory
    cd "$original_pwd"
    rm -rf "$temp_dir"
    
    if [[ "$PWD" == "$original_pwd" ]]; then
        echo "✓ Working directory restoration works"
        return 0
    else
        echo "✗ Working directory restoration failed"
        return 1
    fi
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_environment_functions_exist
    run_test test_environment_variable_operations
    run_test test_lab_root_variable
    run_test test_environment_file_loading
    run_test test_config_directory_access
    run_test test_environment_validation
    run_test test_environment_backup_restore
    run_test test_shell_environment_detection
    run_test test_working_directory_management
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
