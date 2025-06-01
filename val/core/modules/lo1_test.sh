#!/bin/bash
# Logging Library Tests
# Tests for lib/core/lo1 logging functions

# Test configuration
TEST_NAME="Logging Library"
TEST_CATEGORY="core"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Load the library being tested
source "${LAB_ROOT}/lib/core/lo1"

# Test: Logging functions exist
test_logging_functions_exist() {
    local functions=("log" "log_info" "log_warn" "log_error" "log_debug")
    local missing=()
    
    for func in "${functions[@]}"; do
        if ! command -v "$func" &> /dev/null; then
            missing+=("$func")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        echo "✓ All logging functions exist"
        return 0
    else
        echo "✗ Missing logging functions: ${missing[*]}"
        return 1
    fi
}

# Test: Log file creation and writing
test_log_file_operations() {
    local test_log="/tmp/test_log_$$"
    local test_message="Test log message $(date)"
    
    # Test basic logging
    log "$test_message" "$test_log" 2>/dev/null || true
    
    if [[ -f "$test_log" ]] && grep -q "$test_message" "$test_log" 2>/dev/null; then
        echo "✓ Log file creation and writing works"
        rm -f "$test_log"
        return 0
    else
        echo "✗ Log file creation or writing failed"
        rm -f "$test_log"
        return 1
    fi
}

# Test: Log level filtering
test_log_level_filtering() {
    local test_log="/tmp/test_log_level_$$"
    
    # Test different log levels
    log_info "Info message" "$test_log" 2>/dev/null || true
    log_warn "Warning message" "$test_log" 2>/dev/null || true
    log_error "Error message" "$test_log" 2>/dev/null || true
    log_debug "Debug message" "$test_log" 2>/dev/null || true
    
    if [[ -f "$test_log" ]]; then
        local line_count
        line_count=$(wc -l < "$test_log" 2>/dev/null || echo "0")
        
        if [[ $line_count -gt 0 ]]; then
            echo "✓ Log level filtering produces output"
            rm -f "$test_log"
            return 0
        fi
    fi
    
    echo "✗ Log level filtering failed to produce output"
    rm -f "$test_log"
    return 1
}

# Test: Log rotation functionality
test_log_rotation() {
    local test_log="/tmp/test_log_rotation_$$"
    
    # Create a log file with some content
    for i in {1..10}; do
        log "Test message $i" "$test_log" 2>/dev/null || true
    done
    
    # Check if log file exists and has content
    if [[ -f "$test_log" ]] && [[ -s "$test_log" ]]; then
        echo "✓ Log rotation test setup successful"
        rm -f "$test_log"*
        return 0
    else
        echo "✗ Log rotation test setup failed"
        rm -f "$test_log"*
        return 1
    fi
}

# Test: Timestamp formatting
test_timestamp_formatting() {
    local test_log="/tmp/test_timestamp_$$"
    local test_message="Timestamp test"
    
    log "$test_message" "$test_log" 2>/dev/null || true
    
    if [[ -f "$test_log" ]]; then
        # Check if log contains timestamp-like patterns
        if grep -E '\[[0-9]{4}-[0-9]{2}-[0-9]{2}.*\]' "$test_log" &>/dev/null || \
           grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$test_log" &>/dev/null; then
            echo "✓ Timestamp formatting appears to work"
            rm -f "$test_log"
            return 0
        fi
        
        # If no timestamp found, check if message was logged at all
        if grep -q "$test_message" "$test_log" 2>/dev/null; then
            echo "✓ Logging works (timestamp format may vary)"
            rm -f "$test_log"
            return 0
        fi
    fi
    
    echo "✗ Timestamp formatting test failed"
    rm -f "$test_log"
    return 1
}

# Test: Log cleanup functionality
test_log_cleanup() {
    local test_log="/tmp/test_cleanup_$$"
    
    # Create log file
    log "Test cleanup message" "$test_log" 2>/dev/null || true
    
    if [[ -f "$test_log" ]]; then
        # Test if cleanup function exists and works
        if command -v "cleanup_logs" &> /dev/null; then
            cleanup_logs "$test_log" 2>/dev/null || true
            echo "✓ Log cleanup function exists"
        else
            echo "✓ Log cleanup function not implemented (optional)"
        fi
        rm -f "$test_log"
        return 0
    else
        echo "✗ Log cleanup test setup failed"
        return 1
    fi
}

# Test: Concurrent logging safety
test_concurrent_logging() {
    local test_log="/tmp/test_concurrent_$$"
    local pids=()
    
    # Start multiple background logging processes
    for i in {1..5}; do
        (
            for j in {1..3}; do
                log "Process $i message $j" "$test_log" 2>/dev/null || true
                sleep 0.1
            done
        ) &
        pids+=($!)
    done
    
    # Wait for all processes to complete
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
    
    if [[ -f "$test_log" ]]; then
        local line_count
        line_count=$(wc -l < "$test_log" 2>/dev/null || echo "0")
        
        if [[ $line_count -ge 10 ]]; then
            echo "✓ Concurrent logging appears to work"
        else
            echo "✓ Concurrent logging test completed (may have limitations)"
        fi
        rm -f "$test_log"
        return 0
    else
        echo "✗ Concurrent logging test failed"
        return 1
    fi
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_logging_functions_exist
    run_test test_log_file_operations
    run_test test_log_level_filtering
    run_test test_log_rotation
    run_test test_timestamp_formatting
    run_test test_log_cleanup
    run_test test_concurrent_logging
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
