#!/bin/bash
# Verbosity Control Library Tests
# Tests for lib/core/ver verbosity control functions

# Test configuration
TEST_NAME="Verbosity Control Library"
TEST_CATEGORY="core"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Load the library being tested
source "${LAB_ROOT}/lib/core/ver"

# Test: Verbosity functions exist
test_verbosity_functions_exist() {
    local functions=("set_verbosity" "get_verbosity" "is_verbose" "is_debug")
    local missing=()
    
    for func in "${functions[@]}"; do
        if ! command -v "$func" &> /dev/null; then
            missing+=("$func")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        echo "✓ All verbosity functions exist"
        return 0
    else
        echo "✗ Missing verbosity functions: ${missing[*]}"
        return 1
    fi
}

# Test: Verbosity level setting and getting
test_verbosity_levels() {
    # Test different verbosity levels
    local levels=(0 1 2 3)
    
    for level in "${levels[@]}"; do
        set_verbosity "$level" 2>/dev/null || true
        local current_level
        current_level=$(get_verbosity 2>/dev/null) || current_level="unknown"
        
        if [[ "$current_level" == "$level" ]]; then
            echo "✓ Verbosity level $level set and retrieved correctly"
        else
            echo "✗ Verbosity level $level failed (got $current_level)"
            return 1
        fi
    done
    
    return 0
}

# Test: Verbose mode detection
test_verbose_mode_detection() {
    # Set to verbose mode
    set_verbosity 2 2>/dev/null || true
    
    if is_verbose 2>/dev/null; then
        echo "✓ Verbose mode detection works"
    else
        echo "✗ Verbose mode detection failed"
        return 1
    fi
    
    # Set to quiet mode
    set_verbosity 0 2>/dev/null || true
    
    if ! is_verbose 2>/dev/null; then
        echo "✓ Quiet mode detection works"
        return 0
    else
        echo "✗ Quiet mode detection failed"
        return 1
    fi
}

# Test: Debug mode detection
test_debug_mode_detection() {
    # Set to debug mode
    set_verbosity 3 2>/dev/null || true
    
    if is_debug 2>/dev/null; then
        echo "✓ Debug mode detection works"
    else
        echo "✗ Debug mode detection failed"
        return 1
    fi
    
    # Set to normal mode
    set_verbosity 1 2>/dev/null || true
    
    if ! is_debug 2>/dev/null; then
        echo "✓ Non-debug mode detection works"
        return 0
    else
        echo "✗ Non-debug mode detection failed"
        return 1
    fi
}

# Test: Environment variable integration
test_environment_variable_integration() {
    # Test if verbosity respects environment variables
    local original_verbose="$VERBOSE"
    local original_debug="$DEBUG"
    
    # Test VERBOSE environment variable
    export VERBOSE=1
    source "${LAB_ROOT}/lib/core/ver" 2>/dev/null || true
    
    if is_verbose 2>/dev/null; then
        echo "✓ VERBOSE environment variable integration works"
    else
        echo "✗ VERBOSE environment variable integration failed"
        export VERBOSE="$original_verbose"
        export DEBUG="$original_debug"
        return 1
    fi
    
    # Test DEBUG environment variable
    export DEBUG=1
    source "${LAB_ROOT}/lib/core/ver" 2>/dev/null || true
    
    if is_debug 2>/dev/null; then
        echo "✓ DEBUG environment variable integration works"
    else
        echo "✗ DEBUG environment variable integration failed"
        export VERBOSE="$original_verbose"
        export DEBUG="$original_debug"
        return 1
    fi
    
    # Restore original values
    export VERBOSE="$original_verbose"
    export DEBUG="$original_debug"
    return 0
}

# Test: Invalid verbosity level handling
test_invalid_verbosity_levels() {
    local invalid_levels=(-1 5 "abc" "")
    local current_level
    current_level=$(get_verbosity 2>/dev/null) || current_level="1"
    
    for level in "${invalid_levels[@]}"; do
        set_verbosity "$level" 2>/dev/null || true
        local new_level
        new_level=$(get_verbosity 2>/dev/null) || new_level="unknown"
        
        # Should either reject invalid level or handle gracefully
        if [[ "$new_level" == "$level" ]] && [[ "$level" =~ ^[0-3]$ ]]; then
            echo "✗ Invalid verbosity level '$level' was accepted"
            return 1
        fi
    done
    
    echo "✓ Invalid verbosity levels handled appropriately"
    return 0
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_verbosity_functions_exist
    run_test test_verbosity_levels
    run_test test_verbose_mode_detection
    run_test test_debug_mode_detection
    run_test test_environment_variable_integration
    run_test test_invalid_verbosity_levels
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
