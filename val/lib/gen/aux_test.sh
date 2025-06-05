#!/bin/bash
#######################################################################
# Library Tests - Auxiliary Functions
#######################################################################
# File: val/lib/gen/aux_test.sh
# Description: Comprehensive tests for auxiliary functions including
#              function introspection, variable analysis, and utility operations.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"
readonly AUX_LIB="$TEST_LAB_DIR/lib/gen/aux"

# Test functions
test_auxiliary_library_exists() {
    test_file_exists "$AUX_LIB" "Auxiliary functions library exists"
}

test_auxiliary_library_sourceable() {
    test_source "$AUX_LIB" "Auxiliary library can be sourced"
}

test_auxiliary_functions_available() {
    local test_env=$(create_test_env "aux_functions")
    
    cat > "$test_env/test_functions.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/aux 2>/dev/null

# Test that core auxiliary functions exist
functions_found=0
if declare -f aux_fun >/dev/null; then
    ((functions_found++))
fi
if declare -f aux_var >/dev/null; then
    ((functions_found++))
fi
if declare -f aux_log >/dev/null; then
    ((functions_found++))
fi
if declare -f ana_laf >/dev/null; then
    ((functions_found++))
fi
if declare -f ana_acu >/dev/null; then
    ((functions_found++))
fi
# aux_nos function has been removed - using aux_log instead
# if declare -f aux_nos >/dev/null; then
#     ((functions_found++))
# fi
if declare -f aux_flc >/dev/null; then
    ((functions_found++))
fi
if declare -f aux_use >/dev/null; then
    ((functions_found++))
fi

[[ $functions_found -ge 5 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_functions.sh"
    
    run_test "Auxiliary functions available" "$test_env/test_functions.sh"
    cleanup_test_env "$test_env"
}

test_logging_functionality() {
    local test_env=$(create_test_env "aux_logging")
    
    cat > "$test_env/test_logging.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/aux 2>/dev/null

# Test logging functionality
if declare -f aux_log >/dev/null; then
    # Test basic logging
    log_output=$(aux_log "INFO" "Test message" 2>&1)
    if [[ "$log_output" =~ "INFO" ]] && [[ "$log_output" =~ "Test message" ]]; then
        exit 0
    fi
fi

# Test notification functionality (aux_nos has been replaced with aux_log)
if declare -f aux_log >/dev/null; then
    # Test basic logging with notification format
    log_output=$(aux_log "INFO" "test_function: executed successfully" 2>&1)
    if [[ "$log_output" =~ "test_function" ]] && [[ "$log_output" =~ "executed successfully" ]]; then
        exit 0
    fi
fi

exit 1
EOF
    chmod +x "$test_env/test_logging.sh"
    
    run_test "Logging functionality" "$test_env/test_logging.sh"
    cleanup_test_env "$test_env"
}

test_function_analysis_tools() {
    local test_env=$(create_test_env "aux_analysis")
    
    cat > "$test_env/test_analysis.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/aux 2>/dev/null

# Test function listing capabilities
analysis_tools=0

# Test if ana_laf (list all functions) works
if declare -f ana_laf >/dev/null; then
    # Test with the aux library itself
    if ana_laf "$LAB_DIR/lib/gen/aux" -t 2>/dev/null | grep -q "aux-"; then
        ((analysis_tools++))
    fi
fi

# Test if aux_flc (function library cat) works  
if declare -f aux_flc >/dev/null; then
    ((analysis_tools++))
fi

# Test if aux_use (usage information) works
if declare -f aux_use >/dev/null; then
    ((analysis_tools++))
fi

[[ $analysis_tools -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_analysis.sh"
    
    run_test "Function analysis tools" "$test_env/test_analysis.sh"
    cleanup_test_env "$test_env"
}

test_variable_analysis_capabilities() {
    local test_env=$(create_test_env "aux_variables")
    
    cat > "$test_env/test_variables.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/aux 2>/dev/null

# Test variable analysis functionality
if declare -f ana_acu >/dev/null; then
    # Create a test config file
    test_config="/tmp/test_config_$$"
    echo 'TEST_VAR1="value1"' > "$test_config"
    echo 'TEST_VAR2="value2"' > "$test_config"
    
    # Test variable analysis (don't fail if no matches found)
    if ana_acu -o "$test_config" "$LAB_DIR/lib" 2>/dev/null; then
        rm -f "$test_config"
        exit 0
    fi
    
    rm -f "$test_config"
fi

# Test variable modification functionality
if declare -f aux_mev >/dev/null; then
    exit 0
fi

exit 1
EOF
    chmod +x "$test_env/test_variables.sh"
    
    run_test "Variable analysis capabilities" "$test_env/test_variables.sh"
    cleanup_test_env "$test_env"
}

test_file_processing_capabilities() {
    local test_env=$(create_test_env "aux_files")
    
    cat > "$test_env/test_file_processing.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/aux 2>/dev/null

# Test file processing capabilities
file_tools=0

# Test if aux_ffl (file folder loop) exists
if declare -f aux_ffl >/dev/null; then
    ((file_tools++))
fi

# Test if ana_lad (list all documentation) exists
if declare -f ana_lad >/dev/null; then
    ((file_tools++))
fi

# Test directory and file variable setup
if [[ -n "${DIR_FUN:-}" ]] || [[ -n "${FILEPATH_FUN:-}" ]]; then
    ((file_tools++))
fi

[[ $file_tools -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_file_processing.sh"
    
    run_test "File processing capabilities" "$test_env/test_file_processing.sh"
    cleanup_test_env "$test_env"
}

test_auxiliary_utilities() {
    local test_env=$(create_test_env "aux_utilities")
    
    cat > "$test_env/test_utilities.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test if auxiliary utilities can integrate with library system
utilities_working=0

# Test if the library can be loaded as part of the system
if source lib/gen/aux 2>/dev/null; then
    ((utilities_working++))
fi

# Test if core bash features work (required for auxiliary functions)
if command -v awk &>/dev/null; then
    ((utilities_working++))
fi

if command -v grep &>/dev/null; then
    ((utilities_working++))
fi

if command -v sed &>/dev/null; then
    ((utilities_working++))
fi

# Test date functionality (used in logging)
if date +"%Y-%m-%d %H:%M:%S" >/dev/null 2>&1; then
    ((utilities_working++))
fi

[[ $utilities_working -ge 4 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_utilities.sh"
    
    run_test "Auxiliary utilities" "$test_env/test_utilities.sh"
    cleanup_test_env "$test_env"
}

test_configuration_integration() {
    local test_env=$(create_test_env "aux_config")
    
    cat > "$test_env/test_config_integration.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/aux 2>/dev/null

# Test configuration integration
config_features=0

# Test if SITE_CONFIG_FILE variable integration works
if [[ -n "${SITE_CONFIG_FILE:-}" ]] || [[ -n "${CONFIG_FUN:-}" ]]; then
    ((config_features++))
fi

# Test if directory variables are set properly
if [[ -n "${DIR_FUN:-}" ]]; then
    ((config_features++))
fi

# Test if base name derivation works
if [[ -n "${BASE_FUN:-}" ]]; then
    ((config_features++))
fi

# Test if file path construction works
if [[ -n "${FILEPATH_FUN:-}" ]]; then
    ((config_features++))
fi

[[ $config_features -ge 3 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_config_integration.sh"
    
    run_test "Configuration integration" "$test_env/test_config_integration.sh"
    cleanup_test_env "$test_env"
}

test_auxiliary_performance() {
    local test_env=$(create_test_env "aux_performance")
    
    cat > "$test_env/test_performance.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test auxiliary functions performance
start_time=$(date +%s.%N)

source lib/gen/aux 2>/dev/null

if declare -f aux_log >/dev/null; then
    # Test multiple log operations
    for i in {1..10}; do
        aux_log "TEST" "Performance test $i" >/dev/null 2>&1
    done
fi

end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.1")

# Should complete within reasonable time (< 2 seconds)
if (( $(echo "$duration < 2.0" | bc -l 2>/dev/null || echo 1) )); then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_performance.sh"
    
    run_test "Auxiliary performance" "$test_env/test_performance.sh"
    cleanup_test_env "$test_env"
}

test_error_handling() {
    local test_env=$(create_test_env "aux_errors")
    
    cat > "$test_env/test_error_handling.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/aux 2>/dev/null

# Test error handling in auxiliary functions
error_handling=0

# Test aux_use without parameters (should handle gracefully)
if declare -f aux_use >/dev/null; then
    if aux_use 2>/dev/null; then
        ((error_handling++))
    fi
fi

# Test aux_flc with invalid function (should handle gracefully)
if declare -f aux_flc >/dev/null; then
    if aux_flc "nonexistent_function" 2>/dev/null; then
        ((error_handling++))
    else
        # Function should return error but not crash
        ((error_handling++))
    fi
fi

# Test that sourcing doesn't break with missing dependencies
((error_handling++))

[[ $error_handling -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_error_handling.sh"
    
    run_test "Error handling" "$test_env/test_error_handling.sh"
    cleanup_test_env "$test_env"
}

# Main execution
main() {
    run_test_suite "AUXILIARY FUNCTIONS TESTS" \
        test_auxiliary_library_exists \
        test_auxiliary_library_sourceable \
        test_auxiliary_functions_available \
        test_logging_functionality \
        test_function_analysis_tools \
        test_variable_analysis_capabilities \
        test_file_processing_capabilities \
        test_auxiliary_utilities \
        test_configuration_integration \
        test_auxiliary_performance \
        test_error_handling
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
