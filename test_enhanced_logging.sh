#!/bin/bash
# Test script for enhanced logging system

# Set up environment
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Source the enhanced auxiliary library
source lib/gen/aux

echo "=== Testing Enhanced Logging System ==="
echo

# Test 1: Convenience logging functions
echo "1. Testing convenience logging functions:"
aux_info "System startup initiated"
aux_warn "Configuration file not found, using defaults"
aux_err "Database connection failed"
echo

# Test 2: Structured logging with different formats
echo "2. Testing structured logging formats:"

# Test JSON format
export AUX_LOG_FORMAT="json"
aux_log "INFO" "Testing JSON format" "user_id=123,session=abc"

# Test CSV format
export AUX_LOG_FORMAT="csv"
aux_log "INFO" "Testing CSV format" "user_id=123,session=abc"

# Test key-value format
export AUX_LOG_FORMAT="kv"
aux_log "INFO" "Testing key-value format" "user_id=123,session=abc"

# Reset to human format
export AUX_LOG_FORMAT="human"
echo

# Test 3: Debug logging
echo "3. Testing debug logging:"
aux_dbg "Starting configuration validation"
aux_dbg "Found 5 items in array" "INFO"
aux_dbg "Variable value: user=testuser, status=active"
echo

# Test 4: Specialized logging functions
echo "4. Testing specialized logging functions:"
aux_business "Order processed successfully" "order_id=12345,amount=99.99"
aux_security "Failed login attempt detected" "ip=192.168.1.100,user=admin"
aux_audit "User permissions modified" "admin=john,target_user=jane,action=grant"
aux_perf "Database query completed" "duration=250ms,query=user_lookup"
echo

# Test 5: Distributed tracing
echo "5. Testing distributed tracing:"
aux_start_trace "user_authentication"
aux_dbg "Processing authentication request"
aux_dbg "Validating credentials"
aux_dbg "Authentication successful"
aux_end_trace
echo

# Test 6: Metrics integration
echo "6. Testing metrics integration:"
aux_metric "login_count" 15 "counter"
aux_metric "response_time" 125.5 "gauge"
aux_metric "cache_hits" 8543 "counter"
echo

echo "=== Enhanced Logging System Test Complete ==="
echo
echo "Log files created (if LOG_DIR is writable):"
if [[ -n "${LOG_DIR:-}" && -d "${LOG_DIR:-}" ]]; then
    echo "  - ${LOG_DIR}/aux_operational.log (operational logs)"
    echo "  - ${LOG_DIR}/aux_debug.log (debug logs)"
    echo "  - ${LOG_DIR}/aux_operational.jsonl (JSON format logs)"
    echo "  - ${LOG_DIR}/aux_operational.csv (CSV format logs)"
    echo "  - ${LOG_DIR}/aux_debug.jsonl (JSON debug logs)"
    echo "  - ${LOG_DIR}/aux_debug.csv (CSV debug logs)"
else
    echo "  LOG_DIR not set or not writable - logs output to console only"
fi
