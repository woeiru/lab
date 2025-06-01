#!/bin/bash
#######################################################################
# Core Module Tests - Initialization System
#######################################################################
# File: val/core/initialization/ini_test.sh
# Description: Comprehensive tests for the system initialization
#              controller (bin/ini) including module loading,
#              dependency verification, and startup sequence.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"
readonly INI_SCRIPT="$TEST_LAB_DIR/bin/ini"

# Test functions
test_ini_script_exists() {
    test_file_exists "$INI_SCRIPT" "Initialization script exists"
}

test_ini_script_executable() {
    run_test "Initialization script is executable" test -x "$INI_SCRIPT"
}

test_ini_script_shebang() {
    local shebang
    if read -r shebang < "$INI_SCRIPT"; then
        run_test "Initialization script has correct shebang" test "$shebang" = "#!/bin/bash"
    else
        test_failure "Cannot read shebang from initialization script"
    fi
}

test_core_modules_loading() {
    # Test that ini can load core modules
    local test_env=$(create_test_env "ini_core_modules")
    
    cat > "$test_env/test_ini_modules.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test sourcing ini (should load core modules)
if source bin/ini 2>/dev/null; then
    # Check if core modules are loaded
    if declare -f err_log >/dev/null && declare -f lo1_log >/dev/null && declare -f tme_start_timer >/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_ini_modules.sh"
    
    run_test "Core modules loading via ini" "$test_env/test_ini_modules.sh"
    cleanup_test_env "$test_env"
}

test_dependency_verification() {
    # Test that ini properly verifies dependencies
    local test_env=$(create_test_env "ini_dependencies")
    
    cat > "$test_env/test_dependencies.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Source ini and check if verification functions are available
if source bin/ini 2>/dev/null; then
    if declare -f verify_path >/dev/null && declare -f verify_module >/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_dependencies.sh"
    
    run_test "Dependency verification system loaded" "$test_env/test_dependencies.sh"
    cleanup_test_env "$test_env"
}

test_environment_variables() {
    # Test that ini sets up required environment variables
    local test_env=$(create_test_env "ini_env_vars")
    
    cat > "$test_env/test_env_vars.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

if source bin/ini 2>/dev/null; then
    # Check for critical environment variables
    if [[ -n "${BASE_DIR:-}" ]] && [[ -n "${LOG_DIR:-}" ]] && [[ -n "${TMP_DIR:-}" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_env_vars.sh"
    
    run_test "Environment variables properly set" "$test_env/test_env_vars.sh"
    cleanup_test_env "$test_env"
}

test_logging_initialization() {
    # Test that logging system is properly initialized
    local test_env=$(create_test_env "ini_logging")
    
    cat > "$test_env/test_logging.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

if source bin/ini 2>/dev/null; then
    # Test if logging functions work
    if lo1_log "test" "test_function" 2>/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_logging.sh"
    
    run_test "Logging system initialization" "$test_env/test_logging.sh"
    cleanup_test_env "$test_env"
}

test_performance_init() {
    start_performance_test "ini sourcing performance"
    
    local test_env=$(create_test_env "ini_performance")
    cat > "$test_env/perf_test.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"
source bin/ini >/dev/null 2>&1
EOF
    chmod +x "$test_env/perf_test.sh"
    
    "$test_env/perf_test.sh"
    cleanup_test_env "$test_env"
    
    end_performance_test "ini sourcing performance" 5000  # 5 second threshold
}

# Main execution
main() {
    run_test_suite "INITIALIZATION CONTROLLER TESTS" \
        test_ini_script_exists \
        test_ini_script_executable \
        test_ini_script_shebang \
        test_core_modules_loading \
        test_dependency_verification \
        test_environment_variables \
        test_logging_initialization \
        test_performance_init
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
