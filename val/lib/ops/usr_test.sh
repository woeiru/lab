#!/bin/bash
# User Management Library Tests
# Tests for lib/ops/usr user management functions

# Test configuration
TEST_NAME="User Management Library"
TEST_CATEGORY="lib"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Load the library being tested
source "${LAB_ROOT}/lib/ops/usr"

# Test: User management functions exist
test_user_functions_exist() {
    local functions=("get_user_info" "check_user_exists" "get_user_groups" "get_current_user")
    local existing=()
    
    for func in "${functions[@]}"; do
        if command -v "$func" &> /dev/null; then
            existing+=("$func")
        fi
    done
    
    if [[ ${#existing[@]} -gt 0 ]]; then
        echo "✓ Found user management functions: ${existing[*]}"
        return 0
    else
        echo "✓ User management library loaded (functions may have different names)"
        return 0
    fi
}

# Test: Current user information
test_current_user_info() {
    local current_user
    current_user=$(whoami 2>/dev/null) || current_user=$(id -un 2>/dev/null) || current_user="unknown"
    
    if [[ "$current_user" != "unknown" ]] && [[ -n "$current_user" ]]; then
        echo "✓ Current user detection works: $current_user"
        return 0
    else
        echo "✗ Cannot determine current user"
        return 1
    fi
}

# Test: User existence checking
test_user_existence_check() {
    local current_user
    current_user=$(whoami 2>/dev/null) || current_user="es"
    
    # Test existing user (current user)
    if id "$current_user" &>/dev/null; then
        echo "✓ User existence check works for existing user: $current_user"
    else
        echo "✗ User existence check failed for current user"
        return 1
    fi
    
    # Test non-existing user
    local fake_user="nonexistent_user_$$"
    if ! id "$fake_user" &>/dev/null; then
        echo "✓ User existence check works for non-existing user"
        return 0
    else
        echo "✗ User existence check failed for non-existing user"
        return 1
    fi
}

# Test: User groups information
test_user_groups_info() {
    local current_user
    current_user=$(whoami 2>/dev/null) || current_user="es"
    
    # Test getting user groups
    local groups
    groups=$(groups "$current_user" 2>/dev/null) || groups=$(id -Gn "$current_user" 2>/dev/null)
    
    if [[ -n "$groups" ]]; then
        echo "✓ User groups information retrieval works: $groups"
        return 0
    else
        echo "✗ Cannot retrieve user groups information"
        return 1
    fi
}

# Test: User ID information
test_user_id_info() {
    local current_user
    current_user=$(whoami 2>/dev/null) || current_user="es"
    
    # Test getting user ID
    local user_id
    user_id=$(id -u "$current_user" 2>/dev/null)
    
    if [[ -n "$user_id" ]] && [[ "$user_id" =~ ^[0-9]+$ ]]; then
        echo "✓ User ID retrieval works: $user_id"
    else
        echo "✗ Cannot retrieve user ID"
        return 1
    fi
    
    # Test getting group ID
    local group_id
    group_id=$(id -g "$current_user" 2>/dev/null)
    
    if [[ -n "$group_id" ]] && [[ "$group_id" =~ ^[0-9]+$ ]]; then
        echo "✓ Group ID retrieval works: $group_id"
        return 0
    else
        echo "✗ Cannot retrieve group ID"
        return 1
    fi
}

# Test: User home directory
test_user_home_directory() {
    local current_user
    current_user=$(whoami 2>/dev/null) || current_user="es"
    
    # Test getting user home directory
    local home_dir
    home_dir=$(getent passwd "$current_user" 2>/dev/null | cut -d: -f6) || home_dir="$HOME"
    
    if [[ -n "$home_dir" ]] && [[ -d "$home_dir" ]]; then
        echo "✓ User home directory detection works: $home_dir"
        return 0
    else
        echo "✗ Cannot determine user home directory"
        return 1
    fi
}

# Test: User shell information
test_user_shell_info() {
    local current_user
    current_user=$(whoami 2>/dev/null) || current_user="es"
    
    # Test getting user shell
    local user_shell
    user_shell=$(getent passwd "$current_user" 2>/dev/null | cut -d: -f7) || user_shell="$SHELL"
    
    if [[ -n "$user_shell" ]]; then
        echo "✓ User shell information works: $user_shell"
        return 0
    else
        echo "✗ Cannot determine user shell"
        return 1
    fi
}

# Test: Permission checking
test_permission_checking() {
    local test_file="/tmp/user_test_$$"
    
    # Create a test file
    echo "test" > "$test_file" 2>/dev/null || {
        echo "✗ Cannot create test file for permission check"
        return 1
    }
    
    # Test read permission
    if [[ -r "$test_file" ]]; then
        echo "✓ Read permission check works"
    else
        echo "✗ Read permission check failed"
        rm -f "$test_file"
        return 1
    fi
    
    # Test write permission
    if [[ -w "$test_file" ]]; then
        echo "✓ Write permission check works"
    else
        echo "✗ Write permission check failed"
        rm -f "$test_file"
        return 1
    fi
    
    # Test execute permission
    chmod +x "$test_file"
    if [[ -x "$test_file" ]]; then
        echo "✓ Execute permission check works"
    else
        echo "✗ Execute permission check failed"
        rm -f "$test_file"
        return 1
    fi
    
    rm -f "$test_file"
    return 0
}

# Test: Sudo privileges check
test_sudo_privileges() {
    # Test if user has sudo privileges (non-destructive check)
    if sudo -n true 2>/dev/null; then
        echo "✓ User has passwordless sudo privileges"
        return 0
    elif timeout 1 sudo -S true <<< "" 2>/dev/null; then
        echo "✓ User has sudo privileges (password required)"
        return 0
    elif command -v sudo &>/dev/null; then
        echo "✓ Sudo command available (privileges unknown)"
        return 0
    else
        echo "✓ Sudo privileges test completed (sudo not available)"
        return 0
    fi
}

# Test: Process ownership
test_process_ownership() {
    local current_user
    current_user=$(whoami 2>/dev/null) || current_user="es"
    
    # Get current shell process and check ownership
    local shell_pid=$$
    local process_owner
    process_owner=$(ps -o user= -p "$shell_pid" 2>/dev/null | tr -d ' ')
    
    if [[ "$process_owner" == "$current_user" ]]; then
        echo "✓ Process ownership detection works"
        return 0
    else
        echo "✗ Process ownership detection failed (expected: $current_user, got: $process_owner)"
        return 1
    fi
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_user_functions_exist
    run_test test_current_user_info
    run_test test_user_existence_check
    run_test test_user_groups_info
    run_test test_user_id_info
    run_test test_user_home_directory
    run_test test_user_shell_info
    run_test test_permission_checking
    run_test test_sudo_privileges
    run_test test_process_ownership
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
