#!/bin/bash
#######################################################################
# Library Tests - Security Utilities
#######################################################################
# File: val/lib/gen/sec_test.sh
# Description: Comprehensive tests for security utilities including
#              password generation, secure storage, and file permissions.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"
readonly SEC_LIB="$TEST_LAB_DIR/lib/gen/sec"

# Test functions
test_security_library_exists() {
    test_file_exists "$SEC_LIB" "Security utilities library exists"
}

test_security_library_sourceable() {
    test_source "$SEC_LIB" "Security library can be sourced"
}

test_security_functions_available() {
    local test_env=$(create_test_env "sec_functions")
    
    cat > "$test_env/test_functions.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Test that core security functions exist
if declare -f sec_generate_secure_password >/dev/null && \
   declare -f sec_store_secure_password >/dev/null && \
   declare -f sec_init_password_management >/dev/null; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_functions.sh"
    
    run_test "Security functions are available" "$test_env/test_functions.sh"
    cleanup_test_env "$test_env"
}

test_password_generation() {
    local test_env=$(create_test_env "password_generation")
    
    cat > "$test_env/test_password.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Test password generation with different lengths
for length in 8 12 16 32; do
    password=$(generate_secure_password $length 2>/dev/null)
    if [[ ${#password} -eq $length ]]; then
        echo "Length $length: OK"
    else
        echo "Length $length: FAIL (got ${#password})"
        exit 1
    fi
done

exit 0
EOF
    chmod +x "$test_env/test_password.sh"
    
    run_test "Password generation with various lengths" "$test_env/test_password.sh"
    cleanup_test_env "$test_env"
}

test_password_complexity() {
    local test_env=$(create_test_env "password_complexity")
    
    cat > "$test_env/test_complexity.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Generate multiple passwords and check for variety
complexity_ok=true
for i in {1..5}; do
    password=$(generate_secure_password 16 2>/dev/null)
    
    # Check for mixed case, numbers, and special characters
    if [[ "$password" =~ [a-z] ]] && \
       [[ "$password" =~ [A-Z] ]] && \
       [[ "$password" =~ [0-9] ]]; then
        echo "Password $i has good complexity"
    else
        echo "Password $i lacks complexity: $password"
        complexity_ok=false
    fi
done

$complexity_ok && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_complexity.sh"
    
    run_test "Password complexity validation" "$test_env/test_complexity.sh"
    cleanup_test_env "$test_env"
}

test_secure_storage() {
    local test_env=$(create_test_env "secure_storage")
    
    cat > "$test_env/test_storage.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Create temporary directory for testing
temp_dir="/tmp/test_security_$$"
mkdir -p "$temp_dir"
chmod 700 "$temp_dir"

# Test password initialization
if init_password_management "$temp_dir" 2>/dev/null; then
    # Check if password files were created with correct permissions
    files_ok=true
    for file in ct_pbs.pwd nfs_user.pwd smb_user.pwd; do
        if [[ -f "$temp_dir/$file" ]]; then
            perm=$(stat -c "%a" "$temp_dir/$file")
            if [[ "$perm" == "600" ]]; then
                echo "$file: permissions OK (600)"
            else
                echo "$file: permissions FAIL ($perm)"
                files_ok=false
            fi
        else
            echo "$file: missing"
            files_ok=false
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    $files_ok && exit 0 || exit 1
else
    rm -rf "$temp_dir"
    exit 1
fi
EOF
    chmod +x "$test_env/test_storage.sh"
    
    run_test "Secure password storage and permissions" "$test_env/test_storage.sh"
    cleanup_test_env "$test_env"
}

test_password_store_function() {
    local test_env=$(create_test_env "password_store")
    
    cat > "$test_env/test_store.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Test storing a password in a variable
if store_secure_password "TEST_PASSWORD" 12 2>/dev/null; then
    if [[ -n "${TEST_PASSWORD:-}" ]] && [[ ${#TEST_PASSWORD} -eq 12 ]]; then
        echo "Password stored correctly: length ${#TEST_PASSWORD}"
        exit 0
    else
        echo "Password storage failed: '${TEST_PASSWORD:-}'"
        exit 1
    fi
else
    echo "store_secure_password function failed"
    exit 1
fi
EOF
    chmod +x "$test_env/test_store.sh"
    
    run_test "Password variable storage" "$test_env/test_store.sh"
    cleanup_test_env "$test_env"
}

test_security_performance() {
    start_performance_test "Password generation performance"
    
    local test_env=$(create_test_env "sec_performance")
    cat > "$test_env/perf_test.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Generate 10 passwords quickly
for i in {1..10}; do
    generate_secure_password 16 >/dev/null 2>&1
done
EOF
    chmod +x "$test_env/perf_test.sh"
    
    "$test_env/perf_test.sh"
    cleanup_test_env "$test_env"
    
    end_performance_test "Password generation performance" 2000  # 2 second threshold
}

test_error_handling() {
    local test_env=$(create_test_env "sec_error_handling")
    
    cat > "$test_env/test_errors.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Test invalid password lengths
if generate_secure_password 0 2>/dev/null; then
    echo "Should fail with length 0"
    exit 1
fi

if generate_secure_password -5 2>/dev/null; then
    echo "Should fail with negative length"
    exit 1
fi

# Should handle gracefully
exit 0
EOF
    chmod +x "$test_env/test_errors.sh"
    
    run_test "Security error handling" "$test_env/test_errors.sh"
    cleanup_test_env "$test_env"
}

# Main execution
main() {
    run_test_suite "SECURITY UTILITIES TESTS" \
        test_security_library_exists \
        test_security_library_sourceable \
        test_security_functions_available \
        test_password_generation \
        test_password_complexity \
        test_secure_storage \
        test_password_store_function \
        test_security_performance \
        test_error_handling
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
