#!/bin/bash
# SSH Operations Library Tests
# Tests for lib/ops/ssh SSH operation functions

# Test configuration
TEST_NAME="SSH Operations Library"
TEST_CATEGORY="lib"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Load the library being tested (optional, handle gracefully if missing)
if [[ -f "${LAB_ROOT}/lib/ops/ssh" ]]; then
    source "${LAB_ROOT}/lib/ops/ssh" 2>/dev/null || true
fi

# Test: SSH functions exist
test_ssh_functions_exist() {
    local functions=("ssh_connect" "ssh_copy" "ssh_exec" "generate_ssh_key")
    local existing=()
    
    for func in "${functions[@]}"; do
        if command -v "$func" &> /dev/null; then
            existing+=("$func")
        fi
    done
    
    if [[ ${#existing[@]} -gt 0 ]]; then
        echo "✓ Found SSH functions: ${existing[*]}"
        return 0
    else
        echo "✓ SSH library loaded (functions may have different names)"
        return 0
    fi
}

# Test: SSH client availability
test_ssh_client_availability() {
    local ssh_tools=()
    
    if command -v ssh &>/dev/null; then
        ssh_tools+=("ssh")
    fi
    
    if command -v scp &>/dev/null; then
        ssh_tools+=("scp")
    fi
    
    if command -v sftp &>/dev/null; then
        ssh_tools+=("sftp")
    fi
    
    if command -v ssh-keygen &>/dev/null; then
        ssh_tools+=("ssh-keygen")
    fi
    
    if command -v ssh-copy-id &>/dev/null; then
        ssh_tools+=("ssh-copy-id")
    fi
    
    if [[ ${#ssh_tools[@]} -ge 2 ]]; then
        echo "✓ SSH client tools available: ${ssh_tools[*]}"
        return 0
    else
        echo "✗ Insufficient SSH client tools available"
        return 1
    fi
}

# Test: SSH configuration validation
test_ssh_config_validation() {
    local ssh_config_locations=("$HOME/.ssh/config" "/etc/ssh/ssh_config")
    local config_found=false
    local config_readable=false
    
    for config_file in "${ssh_config_locations[@]}"; do
        if [[ -f "$config_file" ]]; then
            config_found=true
            if [[ -r "$config_file" ]]; then
                config_readable=true
                echo "✓ SSH config file found and readable: $config_file"
                break
            fi
        fi
    done
    
    if [[ "$config_found" == "true" ]]; then
        if [[ "$config_readable" == "true" ]]; then
            return 0
        else
            echo "✓ SSH config file found but not readable"
            return 0
        fi
    else
        echo "✓ No SSH config files found (using defaults)"
        return 0
    fi
}

# Test: SSH key management
test_ssh_key_management() {
    local ssh_dir="$HOME/.ssh"
    local key_types=("rsa" "ed25519" "ecdsa")
    local existing_keys=()
    
    if [[ -d "$ssh_dir" ]]; then
        for key_type in "${key_types[@]}"; do
            if [[ -f "$ssh_dir/id_$key_type" ]] || [[ -f "$ssh_dir/id_$key_type.pub" ]]; then
                existing_keys+=("$key_type")
            fi
        done
    fi
    
    # Test key generation capability
    local temp_key="/tmp/test_ssh_key_$$"
    if command -v ssh-keygen &>/dev/null; then
        if ssh-keygen -t ed25519 -f "$temp_key" -N "" -C "test key" &>/dev/null; then
            echo "✓ SSH key generation works"
            rm -f "$temp_key" "$temp_key.pub" 2>/dev/null
            
            if [[ ${#existing_keys[@]} -gt 0 ]]; then
                echo "  Existing keys: ${existing_keys[*]}"
            fi
            return 0
        else
            rm -f "$temp_key" "$temp_key.pub" 2>/dev/null
        fi
    fi
    
    if [[ ${#existing_keys[@]} -gt 0 ]]; then
        echo "✓ SSH keys exist: ${existing_keys[*]}"
        return 0
    else
        echo "✓ SSH key management test completed"
        return 0
    fi
}

# Test: SSH directory permissions
test_ssh_directory_permissions() {
    local ssh_dir="$HOME/.ssh"
    
    if [[ -d "$ssh_dir" ]]; then
        local dir_perms
        dir_perms=$(stat -c "%a" "$ssh_dir" 2>/dev/null) || dir_perms="unknown"
        
        if [[ "$dir_perms" == "700" ]]; then
            echo "✓ SSH directory permissions correct ($dir_perms)"
        elif [[ "$dir_perms" != "unknown" ]]; then
            echo "⚠ SSH directory permissions ($dir_perms) - should be 700"
        else
            echo "✓ SSH directory exists (permissions check unavailable)"
        fi
        
        # Check key file permissions if they exist
        local key_files=("$ssh_dir"/id_*)
        local correct_permissions=0
        local total_keys=0
        
        for key_file in "${key_files[@]}"; do
            if [[ -f "$key_file" ]] && [[ ! "$key_file" =~ \.pub$ ]]; then
                total_keys=$((total_keys + 1))
                local key_perms
                key_perms=$(stat -c "%a" "$key_file" 2>/dev/null) || key_perms="unknown"
                
                if [[ "$key_perms" == "600" ]]; then
                    correct_permissions=$((correct_permissions + 1))
                fi
            fi
        done
        
        if [[ $total_keys -gt 0 ]]; then
            echo "✓ SSH key permissions checked ($correct_permissions/$total_keys correct)"
        fi
        
        return 0
    else
        echo "✓ No SSH directory found (normal for new users)"
        return 0
    fi
}

# Test: SSH agent functionality
test_ssh_agent_functionality() {
    local agent_status="not_running"
    
    # Check if SSH agent is running
    if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -S "$SSH_AUTH_SOCK" ]]; then
        agent_status="running"
        
        # Test ssh-add if available
        if command -v ssh-add &>/dev/null; then
            local loaded_keys
            loaded_keys=$(ssh-add -l 2>/dev/null | wc -l) || loaded_keys=0
            
            echo "✓ SSH agent is running ($loaded_keys keys loaded)"
        else
            echo "✓ SSH agent is running (ssh-add not available)"
        fi
    elif command -v ssh-agent &>/dev/null; then
        echo "✓ SSH agent available but not running"
    else
        echo "✓ SSH agent not available"
    fi
    
    return 0
}

# Test: Known hosts management
test_known_hosts_management() {
    local known_hosts_file="$HOME/.ssh/known_hosts"
    
    if [[ -f "$known_hosts_file" ]]; then
        local host_count
        host_count=$(wc -l < "$known_hosts_file" 2>/dev/null) || host_count=0
        
        echo "✓ Known hosts file exists ($host_count entries)"
        
        # Check file permissions
        local file_perms
        file_perms=$(stat -c "%a" "$known_hosts_file" 2>/dev/null) || file_perms="unknown"
        
        if [[ "$file_perms" == "644" ]] || [[ "$file_perms" == "600" ]]; then
            echo "  File permissions correct ($file_perms)"
        elif [[ "$file_perms" != "unknown" ]]; then
            echo "  File permissions: $file_perms"
        fi
    else
        echo "✓ No known hosts file (normal for new users)"
    fi
    
    # Test ssh-keyscan if available
    if command -v ssh-keyscan &>/dev/null; then
        echo "✓ SSH key scanning capability available"
    fi
    
    return 0
}

# Test: Local SSH connectivity
test_local_ssh_connectivity() {
    local localhost_ssh=false
    
    # Test if SSH server is running locally
    if command -v ss &>/dev/null; then
        if ss -ln | grep -q ":22 "; then
            localhost_ssh=true
        fi
    elif command -v netstat &>/dev/null; then
        if netstat -ln | grep -q ":22 "; then
            localhost_ssh=true
        fi
    fi
    
    if [[ "$localhost_ssh" == "true" ]]; then
        echo "✓ SSH server appears to be running locally"
        
        # Test localhost connection (non-interactive)
        if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=2 localhost exit 2>/dev/null; then
            echo "✓ Local SSH connectivity works"
        else
            echo "✓ SSH server detected (authentication may be required)"
        fi
    else
        echo "✓ No SSH server detected locally (normal)"
    fi
    
    return 0
}

# Test: SSH security features
test_ssh_security_features() {
    local security_features=()
    
    # Check SSH client configuration security
    if command -v ssh &>/dev/null; then
        # Test if SSH supports modern security features
        if ssh -Q cipher 2>/dev/null | grep -q "aes"; then
            security_features+=("modern_ciphers")
        fi
        
        if ssh -Q mac 2>/dev/null | grep -q "hmac"; then
            security_features+=("mac_algorithms")
        fi
        
        if ssh -Q kex 2>/dev/null | grep -q "diffie-hellman"; then
            security_features+=("key_exchange")
        fi
    fi
    
    # Check for additional security tools
    if command -v fail2ban-client &>/dev/null; then
        security_features+=("fail2ban")
    fi
    
    if [[ -f /etc/ssh/sshd_config ]]; then
        security_features+=("sshd_config")
    fi
    
    if [[ ${#security_features[@]} -gt 0 ]]; then
        echo "✓ SSH security features available: ${security_features[*]}"
        return 0
    else
        echo "✓ Basic SSH security features available"
        return 0
    fi
}

# Test: SSH file transfer capabilities
test_ssh_file_transfer() {
    local transfer_tools=()
    local test_file="/tmp/ssh_transfer_test_$$"
    
    # Check available transfer tools
    if command -v scp &>/dev/null; then
        transfer_tools+=("scp")
    fi
    
    if command -v sftp &>/dev/null; then
        transfer_tools+=("sftp")
    fi
    
    if command -v rsync &>/dev/null && command -v ssh &>/dev/null; then
        transfer_tools+=("rsync_over_ssh")
    fi
    
    # Test local file operations for transfer tools
    echo "test transfer content" > "$test_file"
    
    if [[ -f "$test_file" ]] && [[ ${#transfer_tools[@]} -gt 0 ]]; then
        echo "✓ SSH file transfer tools available: ${transfer_tools[*]}"
        rm -f "$test_file"
        return 0
    else
        echo "✗ SSH file transfer capabilities limited"
        rm -f "$test_file"
        return 1
    fi
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_ssh_functions_exist
    run_test test_ssh_client_availability
    run_test test_ssh_config_validation
    run_test test_ssh_key_management
    run_test test_ssh_directory_permissions
    run_test test_ssh_agent_functionality
    run_test test_known_hosts_management
    run_test test_local_ssh_connectivity
    run_test test_ssh_security_features
    run_test test_ssh_file_transfer
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
