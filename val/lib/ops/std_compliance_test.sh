#!/bin/bash
#######################################################################
# .std Standards Compliance Testing Framework
#######################################################################
# File: val/lib/ops/std_compliance_test.sh
# Description: Comprehensive testing framework for .std standards
#              compliance in lib/ops functions, including aux function
#              integration monitoring and validation.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"
readonly LIB_OPS_DIR="$TEST_LAB_DIR/lib/ops"
readonly AUX_LIB="$TEST_LAB_DIR/lib/gen/aux"

# Compliance metrics
declare -g TOTAL_FUNCTIONS=0
declare -g COMPLIANT_FUNCTIONS=0
declare -g VALIDATION_COMPLIANT=0
declare -g HELP_COMPLIANT=0
declare -g ERROR_HANDLING_COMPLIANT=0
declare -g DOCUMENTATION_COMPLIANT=0
declare -g AUX_INTEGRATION_COMPLIANT=0

# Function categories for integration requirements
declare -A SYSTEM_OPS_MODULES=(["sys"]=1 ["srv"]=1 ["net"]=1 ["pve"]=1 ["gpu"]=1 ["sto"]=1 ["ssh"]=1 ["pbs"]=1)
declare -A UTILITY_MODULES=(["usr"]=1)

#######################################################################
# CORE COMPLIANCE TESTS
#######################################################################

# Test that all functions follow parameter validation standards
test_parameter_validation_compliance() {
    local test_env=$(create_test_env "std_param_validation")
    
    cat > "$test_env/test_validation.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Source aux library
source lib/gen/aux 2>/dev/null

compliance_score=0
total_functions=0
validation_compliant=0

# Test each lib/ops module
for module_file in lib/ops/*; do
    [[ ! -f "$module_file" ]] && continue
    [[ "$(basename "$module_file")" == ".std" ]] && continue
    
    module_name=$(basename "$module_file")
    source "$module_file" 2>/dev/null
    
    # Extract function names from module
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        [[ ! "$func_name" =~ ^${module_name}_ ]] && continue
        
        ((total_functions++))
        
        # Test parameter validation
        if declare -f "$func_name" >/dev/null 2>&1; then
            # Test with no parameters (should fail gracefully)
            if $func_name 2>/dev/null; then
                # Function executed without validation - FAIL
                :
            else
                # Function failed as expected - check if it uses aux_use
                if grep -q "aux_use" "$module_file" && grep -A 10 "^$func_name()" "$module_file" | grep -q "aux_use"; then
                    ((validation_compliant++))
                fi
            fi
        fi
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null)
done

echo "VALIDATION_STATS:$validation_compliant:$total_functions"
[[ $validation_compliant -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_validation.sh"
    
    run_test "Parameter validation compliance" "$test_env/test_validation.sh"
    
    # Extract stats
    local stats_output=$(cat "$test_env/test_validation.sh" | tail -1)
    if [[ "$stats_output" =~ VALIDATION_STATS:([0-9]+):([0-9]+) ]]; then
        VALIDATION_COMPLIANT=${BASH_REMATCH[1]}
        TOTAL_FUNCTIONS=${BASH_REMATCH[2]}
    fi
    
    cleanup_test_env "$test_env"
}

# Test help system compliance (aux_use and aux_tec)
test_help_system_compliance() {
    local test_env=$(create_test_env "std_help_system")
    
    cat > "$test_env/test_help.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

help_compliant=0
total_functions=0

# Test each lib/ops module
for module_file in lib/ops/*; do
    [[ ! -f "$module_file" ]] && continue
    [[ "$(basename "$module_file")" == ".std" ]] && continue
    
    module_name=$(basename "$module_file")
    
    # Check for aux_use and aux_tec usage
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        [[ ! "$func_name" =~ ^${module_name}_ ]] && continue
        
        ((total_functions++))
        
        # Check if function has help system
        if grep -A 15 "^$func_name()" "$module_file" | grep -q "aux_tec\|aux_use"; then
            # Check for proper help flag handling
            if grep -A 15 "^$func_name()" "$module_file" | grep -q '\$1.*=.*"--help"\|\$1.*=.*"-h"'; then
                ((help_compliant++))
            fi
        fi
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null)
done

echo "HELP_STATS:$help_compliant:$total_functions"
[[ $help_compliant -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_help.sh"
    
    run_test "Help system compliance" "$test_env/test_help.sh"
    
    # Extract stats
    local output=$(bash "$test_env/test_help.sh" 2>&1 | grep "HELP_STATS")
    if [[ "$output" =~ HELP_STATS:([0-9]+):([0-9]+) ]]; then
        HELP_COMPLIANT=${BASH_REMATCH[1]}
    fi
    
    cleanup_test_env "$test_env"
}

# Test error handling compliance
test_error_handling_compliance() {
    local test_env=$(create_test_env "std_error_handling")
    
    cat > "$test_env/test_errors.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

error_compliant=0
total_functions=0

# Test each lib/ops module
for module_file in lib/ops/*; do
    [[ ! -f "$module_file" ]] && continue
    [[ "$(basename "$module_file")" == ".std" ]] && continue
    
    # Check for proper error handling patterns
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        
        ((total_functions++))
        
        # Check for proper return codes and aux_err usage
        func_body=$(sed -n "/^$func_name()/,/^}/p" "$module_file")
        
        # Check for return code standards (0, 1, 2, 127)
        if echo "$func_body" | grep -q "return [012]\\|return 127"; then
            # Check for aux_err usage
            if echo "$func_body" | grep -q "aux_err"; then
                ((error_compliant++))
            elif echo "$func_body" | grep -q "echo.*Error\|echo.*error"; then
                # Basic error handling without aux_err
                ((error_compliant++))
            fi
        fi
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null)
done

echo "ERROR_STATS:$error_compliant:$total_functions"
[[ $error_compliant -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_errors.sh"
    
    run_test "Error handling compliance" "$test_env/test_errors.sh"
    
    # Extract stats
    local output=$(bash "$test_env/test_errors.sh" 2>&1 | grep "ERROR_STATS")
    if [[ "$output" =~ ERROR_STATS:([0-9]+):([0-9]+) ]]; then
        ERROR_HANDLING_COMPLIANT=${BASH_REMATCH[1]}
    fi
    
    cleanup_test_env "$test_env"
}

# Test documentation compliance
test_documentation_compliance() {
    local test_env=$(create_test_env "std_documentation")
    
    cat > "$test_env/test_docs.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

doc_compliant=0
total_functions=0

# Test each lib/ops module
for module_file in lib/ops/*; do
    [[ ! -f "$module_file" ]] && continue
    [[ "$(basename "$module_file")" == ".std" ]] && continue
    
    # Check for proper documentation format
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        
        ((total_functions++))
        
        # Find function in file and check preceding comments
        func_line_num=$(grep -n "^$func_name()" "$module_file" | cut -d: -f1)
        [[ -z "$func_line_num" ]] && continue
        
        # Check for three comment lines above function (description, shortname, usage)
        if [[ $func_line_num -gt 3 ]]; then
            desc_line=$((func_line_num - 3))
            shortname_line=$((func_line_num - 2))
            usage_line=$((func_line_num - 1))
            
            desc=$(sed -n "${desc_line}p" "$module_file")
            shortname=$(sed -n "${shortname_line}p" "$module_file")
            usage=$(sed -n "${usage_line}p" "$module_file")
            
            # Check if all three lines are comments
            if [[ "$desc" =~ ^#.*[a-zA-Z] ]] && [[ "$shortname" =~ ^#.*[a-zA-Z] ]] && [[ "$usage" =~ ^# ]]; then
                # Check for technical documentation after function
                tech_docs=$(sed -n "$((func_line_num + 1)),$((func_line_num + 20))p" "$module_file")
                if echo "$tech_docs" | grep -q "Technical Description:\|Dependencies:\|Arguments:"; then
                    ((doc_compliant++))
                fi
            fi
        fi
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null)
done

echo "DOC_STATS:$doc_compliant:$total_functions"
[[ $doc_compliant -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_docs.sh"
    
    run_test "Documentation compliance" "$test_env/test_docs.sh"
    
    # Extract stats
    local output=$(bash "$test_env/test_docs.sh" 2>&1 | grep "DOC_STATS")
    if [[ "$output" =~ DOC_STATS:([0-9]+):([0-9]+) ]]; then
        DOCUMENTATION_COMPLIANT=${BASH_REMATCH[1]}
    fi
    
    cleanup_test_env "$test_env"
}

#######################################################################
# AUX FUNCTION INTEGRATION TESTS
#######################################################################

# Test aux function integration compliance
test_aux_integration_compliance() {
    local test_env=$(create_test_env "std_aux_integration")
    
    cat > "$test_env/test_aux_integration.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

aux_compliant=0
total_functions=0

# Test each lib/ops module
for module_file in lib/ops/*; do
    [[ ! -f "$module_file" ]] && continue
    [[ "$(basename "$module_file")" == ".std" ]] && continue
    
    module_name=$(basename "$module_file")
    
    # Check for aux function usage
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        
        ((total_functions++))
        
        # Get function body
        func_body=$(sed -n "/^$func_name()/,/^}/p" "$module_file")
        
        # Count aux function usage
        aux_count=0
        
        # Check for required aux functions
        echo "$func_body" | grep -q "aux_val" && ((aux_count++))
        echo "$func_body" | grep -q "aux_use\|aux_tec" && ((aux_count++))
        
        # Check for operational aux functions (for system operations)
        if [[ "$module_name" == "sys" || "$module_name" == "srv" || "$module_name" == "net" || "$module_name" == "pve" ]]; then
            echo "$func_body" | grep -q "aux_log\|aux_info\|aux_warn\|aux_err" && ((aux_count++))
            echo "$func_body" | grep -q "aux_chk" && ((aux_count++))
        fi
        
        # Function is compliant if it uses at least 2 aux functions
        [[ $aux_count -ge 2 ]] && ((aux_compliant++))
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null)
done

echo "AUX_STATS:$aux_compliant:$total_functions"
[[ $aux_compliant -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_aux_integration.sh"
    
    run_test "Aux function integration compliance" "$test_env/test_aux_integration.sh"
    
    # Extract stats
    local output=$(bash "$test_env/test_aux_integration.sh" 2>&1 | grep "AUX_STATS")
    if [[ "$output" =~ AUX_STATS:([0-9]+):([0-9]+) ]]; then
        AUX_INTEGRATION_COMPLIANT=${BASH_REMATCH[1]}
    fi
    
    cleanup_test_env "$test_env"
}

# Test specific aux functions integration
test_aux_val_integration() {
    test_aux_function_usage "aux_val" "Parameter validation with aux_val"
}

test_aux_chk_integration() {
    test_aux_function_usage "aux_chk" "Dependency checking with aux_chk"
}

test_aux_log_integration() {
    test_aux_function_usage "aux_log\|aux_info\|aux_warn\|aux_err" "Operational logging functions"
}

test_aux_cmd_integration() {
    test_aux_function_usage "aux_cmd" "Safe command execution with aux_cmd"
}

test_aux_ask_integration() {
    test_aux_function_usage "aux_ask" "User interaction with aux_ask"
}

test_aux_arr_integration() {
    test_aux_function_usage "aux_arr" "Array operations with aux_arr"
}

# Helper function to test specific aux function usage
test_aux_function_usage() {
    local aux_pattern="$1"
    local description="$2"
    
    local test_env=$(create_test_env "aux_$(echo $aux_pattern | tr '|\\' '_')")
    
    cat > "$test_env/test_aux_specific.sh" << EOF
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "\$LAB_DIR"

usage_count=0

# Count usage across all lib/ops modules
for module_file in lib/ops/*; do
    [[ ! -f "\$module_file" ]] && continue
    [[ "\$(basename "\$module_file")" == ".std" ]] && continue
    
    # Count occurrences of the aux pattern
    count=\$(grep -c "$aux_pattern" "\$module_file" 2>/dev/null || echo 0)
    usage_count=\$((usage_count + count))
done

echo "Found \$usage_count usages of $aux_pattern"
[[ \$usage_count -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_aux_specific.sh"
    
    run_test "$description" "$test_env/test_aux_specific.sh"
    cleanup_test_env "$test_env"
}

#######################################################################
# FUNCTION CATEGORY TESTS
#######################################################################

# Test system operations functions compliance
test_system_ops_compliance() {
    local test_env=$(create_test_env "std_system_ops")
    
    cat > "$test_env/test_system_ops.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

compliant_count=0
total_count=0

# Test system operation modules
for module in sys srv net pve gpu sto ssh pbs; do
    module_file="lib/ops/$module"
    [[ ! -f "$module_file" ]] && continue
    
    # Check functions in this module
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        [[ ! "$func_name" =~ ^${module}_ ]] && continue
        
        ((total_count++))
        
        # Get function body
        func_body=$(sed -n "/^$func_name()/,/^}/p" "$module_file")
        
        # Check for required aux functions for system ops
        required_count=0
        echo "$func_body" | grep -q "aux_val" && ((required_count++))
        echo "$func_body" | grep -q "aux_chk" && ((required_count++))
        echo "$func_body" | grep -q "aux_log\|aux_info\|aux_warn\|aux_err" && ((required_count++))
        
        # System ops should have at least aux_val + one operational function
        [[ $required_count -ge 2 ]] && ((compliant_count++))
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null)
done

echo "SYSTEM_OPS:$compliant_count:$total_count"
[[ $compliant_count -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_system_ops.sh"
    
    run_test "System operations compliance" "$test_env/test_system_ops.sh"
    cleanup_test_env "$test_env"
}

# Test utility functions compliance  
test_utility_functions_compliance() {
    local test_env=$(create_test_env "std_utilities")
    
    cat > "$test_env/test_utilities.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

compliant_count=0
total_count=0

# Test utility modules (minimal requirements)
for module in usr; do
    module_file="lib/ops/$module"
    [[ ! -f "$module_file" ]] && continue
    
    # Check functions in this module
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        [[ ! "$func_name" =~ ^${module}_ ]] && continue
        
        ((total_count++))
        
        # Get function body
        func_body=$(sed -n "/^$func_name()/,/^}/p" "$module_file")
        
        # Check for minimal aux functions for utilities
        required_count=0
        echo "$func_body" | grep -q "aux_val\|aux_use" && ((required_count++))
        
        # Utilities need at least basic validation or help
        [[ $required_count -ge 1 ]] && ((compliant_count++))
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null)
done

echo "UTILITIES:$compliant_count:$total_count"
[[ $compliant_count -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_utilities.sh"
    
    run_test "Utility functions compliance" "$test_env/test_utilities.sh"
    cleanup_test_env "$test_env"
}

#######################################################################
# REGRESSION TESTS
#######################################################################

# Test that existing functionality still works
test_backward_compatibility() {
    local test_env=$(create_test_env "std_backward_compat")
    
    cat > "$test_env/test_backward.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Source environment
source bin/ini 2>/dev/null || true

compatibility_score=0

# Test that modules can still be sourced
for module_file in lib/ops/*; do
    [[ ! -f "$module_file" ]] && continue
    [[ "$(basename "$module_file")" == ".std" ]] && continue
    
    if source "$module_file" 2>/dev/null; then
        ((compatibility_score++))
    fi
done

echo "Backward compatibility score: $compatibility_score"
[[ $compatibility_score -gt 5 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_backward.sh"
    
    run_test "Backward compatibility" "$test_env/test_backward.sh"
    cleanup_test_env "$test_env"
}

# Test function execution doesn't break
test_function_execution_safety() {
    local test_env=$(create_test_env "std_execution_safety")
    
    cat > "$test_env/test_execution.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test that functions with --help don't cause errors
safe_functions=0
tested_functions=0

for module_file in lib/ops/*; do
    [[ ! -f "$module_file" ]] && continue
    [[ "$(basename "$module_file")" == ".std" ]] && continue
    
    module_name=$(basename "$module_file")
    source "$module_file" 2>/dev/null
    
    # Test functions that should have help
    while IFS= read -r func_line; do
        [[ -z "$func_line" ]] && continue
        func_name=$(echo "$func_line" | cut -d'(' -f1)
        [[ ! "$func_name" =~ ^${module_name}_ ]] && continue
        
        ((tested_functions++))
        
        # Test help functionality (should not crash)
        if timeout 5 $func_name --help >/dev/null 2>&1; then
            ((safe_functions++))
        elif timeout 5 $func_name -h >/dev/null 2>&1; then
            ((safe_functions++))
        fi
        
        # Limit testing to avoid long execution
        [[ $tested_functions -gt 20 ]] && break 2
        
    done < <(grep -E "^[a-zA-Z0-9_]+\(\)" "$module_file" 2>/dev/null | head -5)
done

echo "EXECUTION_SAFETY:$safe_functions:$tested_functions"
[[ $safe_functions -gt 0 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_execution.sh"
    
    run_test "Function execution safety" "$test_env/test_execution.sh"
    cleanup_test_env "$test_env"
}

#######################################################################
# COMPLIANCE REPORTING
#######################################################################

# Generate compliance report
generate_compliance_report() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    .STD COMPLIANCE REPORT                       ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    
    # Calculate percentages
    local val_percent=0
    local help_percent=0
    local error_percent=0
    local doc_percent=0
    local aux_percent=0
    
    if [[ $TOTAL_FUNCTIONS -gt 0 ]]; then
        val_percent=$((VALIDATION_COMPLIANT * 100 / TOTAL_FUNCTIONS))
        help_percent=$((HELP_COMPLIANT * 100 / TOTAL_FUNCTIONS))
        error_percent=$((ERROR_HANDLING_COMPLIANT * 100 / TOTAL_FUNCTIONS))
        doc_percent=$((DOCUMENTATION_COMPLIANT * 100 / TOTAL_FUNCTIONS))
        aux_percent=$((AUX_INTEGRATION_COMPLIANT * 100 / TOTAL_FUNCTIONS))
    fi
    
    echo "║ Parameter Validation:    $VALIDATION_COMPLIANT/$TOTAL_FUNCTIONS ($val_percent%)"
    echo "║ Help System:             $HELP_COMPLIANT/$TOTAL_FUNCTIONS ($help_percent%)"
    echo "║ Error Handling:          $ERROR_HANDLING_COMPLIANT/$TOTAL_FUNCTIONS ($error_percent%)"
    echo "║ Documentation:           $DOCUMENTATION_COMPLIANT/$TOTAL_FUNCTIONS ($doc_percent%)"
    echo "║ Aux Integration:         $AUX_INTEGRATION_COMPLIANT/$TOTAL_FUNCTIONS ($aux_percent%)"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    
    # Overall compliance score
    local total_checks=$((VALIDATION_COMPLIANT + HELP_COMPLIANT + ERROR_HANDLING_COMPLIANT + DOCUMENTATION_COMPLIANT + AUX_INTEGRATION_COMPLIANT))
    local max_checks=$((TOTAL_FUNCTIONS * 5))
    local overall_percent=0
    [[ $max_checks -gt 0 ]] && overall_percent=$((total_checks * 100 / max_checks))
    
    echo "║ Overall Compliance:      $total_checks/$max_checks ($overall_percent%)"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Recommendations
    if [[ $overall_percent -lt 80 ]]; then
        echo "🔴 RECOMMENDATIONS:"
        [[ $val_percent -lt 90 ]] && echo "   • Add aux_val parameter validation to more functions"
        [[ $help_percent -lt 90 ]] && echo "   • Implement aux_use/aux_tec help system in more functions"
        [[ $error_percent -lt 80 ]] && echo "   • Add proper error handling with aux_err"
        [[ $doc_percent -lt 70 ]] && echo "   • Improve function documentation"
        [[ $aux_percent -lt 60 ]] && echo "   • Increase aux function integration"
    else
        echo "✅ GOOD COMPLIANCE - Ready for production!"
    fi
    echo ""
}

#######################################################################
# MAIN EXECUTION
#######################################################################

# Main test suite execution
main() {
    test_header "STD COMPLIANCE TESTS"
    
    # Prerequisites
    test_file_exists "$LIB_OPS_DIR" "lib/ops directory exists"
    test_file_exists "$AUX_LIB" "aux library exists"
    
    echo ""
    echo "🔍 Running .std standards compliance tests..."
    echo ""
    
    # Core compliance tests
    test_parameter_validation_compliance
    test_help_system_compliance
    test_error_handling_compliance
    test_documentation_compliance
    
    # Aux integration tests
    test_aux_integration_compliance
    test_aux_val_integration
    test_aux_chk_integration
    test_aux_log_integration
    test_aux_cmd_integration
    test_aux_ask_integration
    test_aux_arr_integration
    
    # Category-specific tests
    test_system_ops_compliance
    test_utility_functions_compliance
    
    # Regression tests
    test_backward_compatibility
    test_function_execution_safety
    
    # Generate report
    generate_compliance_report
    
    test_footer
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
