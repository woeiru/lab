#!/bin/bash
#######################################################################
# Library Integration Tests - Function Rename Validation
#######################################################################
# File: val/lib/integration/function_rename_test.sh
# Description: Comprehensive test module for mass function renaming scenarios
#              in the /lib directory. Validates function dependencies, usage
#              patterns, and ensures all references are properly updated.
#
# PURPOSE:
#   When renaming a large number of functions in the library system, this
#   test module provides comprehensive validation to ensure:
#   - All function references are updated across the codebase
#   - Function dependencies remain intact
#   - Wrapper functions maintain correct linkage to pure functions
#   - Configuration files and documentation are updated
#   - No orphaned function calls exist
#
# USAGE:
#   ./function_rename_test.sh [--pre-rename | --post-rename | --help]
#   
#   --pre-rename   : Run before renaming to establish baseline
#   --post-rename  : Run after renaming to validate changes
#   --help         : Show usage information
#
# INTEGRATION:
#   Works with existing test framework and can be included in CI/CD
#   pipelines for automated validation of mass refactoring operations.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_NAME="Function Rename Validation"
readonly TEST_CATEGORY="integration"
readonly TEST_LAB_DIR="/home/es/lab"

# Global tracking variables
declare -A FUNCTION_INVENTORY
declare -A FUNCTION_REFERENCES
declare -A FUNCTION_DEPENDENCIES
declare -A RENAMED_FUNCTIONS
declare -a VALIDATION_ERRORS

# Color codes for enhanced output (avoid conflicts with test framework)
readonly RENAME_CYAN='\033[0;36m'
readonly RENAME_MAGENTA='\033[0;35m'
readonly RENAME_BOLD='\033[1m'

#######################################################################
# CORE INVENTORY FUNCTIONS
#######################################################################

# Discovers all functions in the library system
discover_all_functions() {
    local lib_dir="$TEST_LAB_DIR/lib"
    local function_count=0
    
    echo -e "${RENAME_CYAN}📊 Discovering all functions in library system...${NC}"
    
    # Core libraries
    for lib_file in "$lib_dir"/core/*; do
        if [[ -f "$lib_file" ]]; then
            while IFS= read -r func_name; do
                if [[ -n "$func_name" ]]; then
                    FUNCTION_INVENTORY["$func_name"]="core/$(basename "$lib_file")"
                    ((function_count++))
                fi
            done < <(grep -oP '^[a-zA-Z][a-zA-Z0-9_-]*\(\)' "$lib_file" | sed 's/()//')
        fi
    done
    
    # Operations libraries  
    for lib_file in "$lib_dir"/ops/*; do
        if [[ -f "$lib_file" ]]; then
            while IFS= read -r func_name; do
                if [[ -n "$func_name" ]]; then
                    FUNCTION_INVENTORY["$func_name"]="ops/$(basename "$lib_file")"
                    ((function_count++))
                fi
            done < <(grep -oP '^[a-zA-Z][a-zA-Z0-9_-]*\(\)' "$lib_file" | sed 's/()//')
        fi
    done
    
    # General utilities libraries
    for lib_file in "$lib_dir"/gen/*; do
        if [[ -f "$lib_file" ]]; then
            while IFS= read -r func_name; do
                if [[ -n "$func_name" ]]; then
                    FUNCTION_INVENTORY["$func_name"]="gen/$(basename "$lib_file")"
                    ((function_count++))
                fi
            done < <(grep -oP '^[a-zA-Z][a-zA-Z0-9_-]*\(\)' "$lib_file" | sed 's/()//')
        fi
    done
    
    echo "✓ Discovered $function_count functions across ${#FUNCTION_INVENTORY[@]} unique names"
    return 0
}

# Maps all function usage across the codebase
map_function_references() {
    local total_refs=0
    
    echo -e "${RENAME_CYAN}🔍 Mapping function references across codebase...${NC}"
    
    # Search in all script files
    local search_dirs=("$TEST_LAB_DIR/bin" "$TEST_LAB_DIR/src" "$TEST_LAB_DIR/lib" "$TEST_LAB_DIR/utl")
    
    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        local ref_count=0
        local ref_files=()
        
        for search_dir in "${search_dirs[@]}"; do
            if [[ -d "$search_dir" ]]; then
                while IFS= read -r -d '' file; do
                    if grep -q "$func_name" "$file" 2>/dev/null; then
                        ref_files+=("$file")
                        ((ref_count++))
                    fi
                done < <(find "$search_dir" -type f -name "*.sh" -o -name "*" -print0 2>/dev/null)
            fi
        done
        
        if [[ $ref_count -gt 0 ]]; then
            FUNCTION_REFERENCES["$func_name"]="$ref_count:${ref_files[*]}"
            ((total_refs += ref_count))
        fi
    done
    
    echo "✓ Mapped $total_refs function references across codebase"
    return 0
}

# Analyzes function dependencies within libraries
analyze_function_dependencies() {
    local dependency_count=0
    
    echo -e "${RENAME_CYAN}🔗 Analyzing function dependencies...${NC}"
    
    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        local lib_path="${FUNCTION_INVENTORY[$func_name]}"
        local full_path="$TEST_LAB_DIR/lib/$lib_path"
        local dependencies=()
        
        if [[ -f "$full_path" ]]; then
            # Find function calls within the same library
            while IFS= read -r dep_func; do
                if [[ "$dep_func" != "$func_name" && -n "${FUNCTION_INVENTORY[$dep_func]:-}" ]]; then
                    dependencies+=("$dep_func")
                fi
            done < <(sed -n "/^$func_name()/,/^}$/p" "$full_path" | grep -oP '[a-zA-Z][a-zA-Z0-9_-]*(?=\()')
            
            if [[ ${#dependencies[@]} -gt 0 ]]; then
                FUNCTION_DEPENDENCIES["$func_name"]="${dependencies[*]}"
                ((dependency_count += ${#dependencies[@]}))
            fi
        fi
    done
    
    echo "✓ Analyzed $dependency_count function dependencies"
    return 0
}

#######################################################################
# VALIDATION FUNCTIONS
#######################################################################

# Validates function naming patterns follow conventions
test_function_naming_conventions() {
    echo -e "${RENAME_MAGENTA}📋 Testing function naming conventions...${NC}"
    
    local convention_violations=0
    local expected_patterns=(
        "aux-[a-z]{3}"      # aux-fun, aux-var, aux-log
        "pve-[a-z]{3}"      # pve-fun, pve-var, pve-vms
        "gpu-[a-z]{3}"      # gpu-fun, gpu-var, gpu-pts
        "sys-[a-z]{3}"      # sys-fun, sys-var, sys-gio
        "[a-z]{3}-[a-z]{3}" # Generic three-letter patterns
    )
    
    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        local lib_category="${FUNCTION_INVENTORY[$func_name]%%/*}"
        local follows_convention=false
        
        # Check against expected patterns
        for pattern in "${expected_patterns[@]}"; do
            if [[ "$func_name" =~ ^$pattern$ ]]; then
                follows_convention=true
                break
            fi
        done
        
        if [[ "$follows_convention" == false ]]; then
            echo "  ⚠  Convention violation: $func_name (in $lib_category)"
            ((convention_violations++))
        fi
    done
    
    if [[ $convention_violations -eq 0 ]]; then
        echo "✓ All functions follow naming conventions"
        return 0
    else
        echo "✗ Found $convention_violations naming convention violations"
        return 1
    fi
}

# Validates wrapper function relationships
test_wrapper_function_integrity() {
    echo -e "${RENAME_MAGENTA}🔗 Testing wrapper function integrity...${NC}"
    
    local wrapper_issues=0
    local src_mgt_dir="$TEST_LAB_DIR/src/mgt"
    
    # Find all wrapper functions (ending with -w)
    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        if [[ "$func_name" =~ -w$ ]]; then
            local pure_func="${func_name%-w}"
            
            # Check if corresponding pure function exists
            if [[ -z "${FUNCTION_INVENTORY[$pure_func]:-}" ]]; then
                echo "  ✗ Orphaned wrapper: $func_name (no pure function $pure_func)"
                VALIDATION_ERRORS+=("Orphaned wrapper: $func_name")
                ((wrapper_issues++))
            else
                echo "  ✓ Valid wrapper pair: $func_name -> $pure_func"
            fi
        fi
    done
    
    # Check for pure functions that should have wrappers
    if [[ -d "$src_mgt_dir" ]]; then
        for mgt_file in "$src_mgt_dir"/*; do
            if [[ -f "$mgt_file" ]]; then
                local mgt_category=$(basename "$mgt_file")
                
                # Find functions that should have wrappers
                while IFS= read -r func_name; do
                    if [[ -n "$func_name" && ! "$func_name" =~ -w$ ]]; then
                        local wrapper_name="${func_name}-w"
                        
                        # Check if wrapper exists in management file
                        if ! grep -q "^${wrapper_name}()" "$mgt_file" 2>/dev/null; then
                            echo "  ⚠  Missing wrapper: $wrapper_name for $func_name"
                        fi
                    fi
                done < <(grep -oP '^[a-zA-Z][a-zA-Z0-9_-]*\(\)' "$mgt_file" | sed 's/()//')
            fi
        done
    fi
    
    if [[ $wrapper_issues -eq 0 ]]; then
        echo "✓ Wrapper function integrity validated"
        return 0
    else
        echo "✗ Found $wrapper_issues wrapper function issues"
        return 1
    fi
}

# Validates function cross-references
test_function_cross_references() {
    echo -e "${RENAME_MAGENTA}🎯 Testing function cross-references...${NC}"
    
    local broken_refs=0
    
    for func_name in "${!FUNCTION_REFERENCES[@]}"; do
        local ref_info="${FUNCTION_REFERENCES[$func_name]}"
        local ref_count="${ref_info%%:*}"
        local ref_files="${ref_info#*:}"
        
        # Check if function still exists in inventory
        if [[ -z "${FUNCTION_INVENTORY[$func_name]:-}" ]]; then
            echo "  ✗ Broken reference: $func_name (referenced $ref_count times, but function not found)"
            VALIDATION_ERRORS+=("Broken reference: $func_name")
            ((broken_refs++))
        else
            echo "  ✓ Valid reference: $func_name ($ref_count references)"
        fi
    done
    
    if [[ $broken_refs -eq 0 ]]; then
        echo "✓ All function cross-references are valid"
        return 0
    else
        echo "✗ Found $broken_refs broken function references"
        return 1
    fi
}

# Validates dependency chains
test_dependency_chains() {
    echo -e "${RENAME_MAGENTA}⛓️  Testing function dependency chains...${NC}"
    
    local circular_deps=0
    local broken_deps=0
    
    for func_name in "${!FUNCTION_DEPENDENCIES[@]}"; do
        local dependencies=(${FUNCTION_DEPENDENCIES[$func_name]})
        
        # Check for broken dependencies
        for dep in "${dependencies[@]}"; do
            if [[ -z "${FUNCTION_INVENTORY[$dep]:-}" ]]; then
                echo "  ✗ Broken dependency: $func_name depends on missing function $dep"
                VALIDATION_ERRORS+=("Broken dependency: $func_name -> $dep")
                ((broken_deps++))
            fi
        done
        
        # Check for circular dependencies (simple check)
        for dep in "${dependencies[@]}"; do
            if [[ -n "${FUNCTION_DEPENDENCIES[$dep]:-}" ]]; then
                local sub_deps=(${FUNCTION_DEPENDENCIES[$dep]})
                for sub_dep in "${sub_deps[@]}"; do
                    if [[ "$sub_dep" == "$func_name" ]]; then
                        echo "  ⚠  Circular dependency: $func_name <-> $dep"
                        ((circular_deps++))
                    fi
                done
            fi
        done
    done
    
    local total_issues=$((broken_deps + circular_deps))
    if [[ $total_issues -eq 0 ]]; then
        echo "✓ All dependency chains are valid"
        return 0
    else
        echo "✗ Found $broken_deps broken dependencies and $circular_deps circular dependencies"
        return 1
    fi
}

# Validates configuration file consistency
test_configuration_consistency() {
    echo -e "${RENAME_MAGENTA}⚙️  Testing configuration file consistency...${NC}"
    
    local config_issues=0
    local config_dirs=("$TEST_LAB_DIR/cfg" "$TEST_LAB_DIR/cfg/env")
    
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            while IFS= read -r -d '' config_file; do
                # Check for function references in config files
                for func_name in "${!FUNCTION_INVENTORY[@]}"; do
                    if grep -q "$func_name" "$config_file" 2>/dev/null; then
                        # Verify function still exists
                        if [[ -z "${FUNCTION_INVENTORY[$func_name]:-}" ]]; then
                            echo "  ✗ Config references missing function: $(basename "$config_file") -> $func_name"
                            ((config_issues++))
                        fi
                    fi
                done
            done < <(find "$config_dir" -type f -print0 2>/dev/null)
        fi
    done
    
    if [[ $config_issues -eq 0 ]]; then
        echo "✓ Configuration consistency validated"
        return 0
    else
        echo "✗ Found $config_issues configuration consistency issues"
        return 1
    fi
}

#######################################################################
# RENAME SCENARIO TESTING
#######################################################################

# Simulates a batch function rename scenario
test_batch_rename_scenario() {
    echo -e "${RENAME_MAGENTA}🔄 Testing batch rename scenario simulation...${NC}"
    
    # Define a test rename mapping (old_name -> new_name)
    local test_renames=(
        "aux-fun:aux-functions"
        "aux-var:aux-variables"
        "pve-fun:pve-functions"
        "gpu-fun:gpu-functions"
    )
    
    local rename_issues=0
    
    for rename_pair in "${test_renames[@]}"; do
        local old_name="${rename_pair%:*}"
        local new_name="${rename_pair#*:}"
        
        # Check if old function exists
        if [[ -n "${FUNCTION_INVENTORY[$old_name]:-}" ]]; then
            echo "  📝 Simulating rename: $old_name -> $new_name"
            
            # Check for potential conflicts
            if [[ -n "${FUNCTION_INVENTORY[$new_name]:-}" ]]; then
                echo "    ⚠  Name conflict: $new_name already exists"
                ((rename_issues++))
            fi
            
            # Check reference count
            local ref_info="${FUNCTION_REFERENCES[$old_name]:-}"
            if [[ -n "$ref_info" ]]; then
                local ref_count="${ref_info%%:*}"
                echo "    📊 Would affect $ref_count references"
                
                if [[ $ref_count -gt 10 ]]; then
                    echo "    ⚠  High-impact rename (>10 references)"
                fi
            fi
            
            # Check for wrapper function implications
            local wrapper_name="${old_name}-w"
            if [[ -n "${FUNCTION_INVENTORY[$wrapper_name]:-}" ]]; then
                echo "    🔗 Has wrapper function: $wrapper_name (would need rename to ${new_name}-w)"
            fi
            
        else
            echo "  ⚠  Cannot rename non-existent function: $old_name"
            ((rename_issues++))
        fi
    done
    
    if [[ $rename_issues -eq 0 ]]; then
        echo "✓ Batch rename scenario simulation completed successfully"
        return 0
    else
        echo "✗ Found $rename_issues issues in batch rename scenario"
        return 1
    fi
}

# Validates post-rename state
test_post_rename_validation() {
    echo -e "${RENAME_MAGENTA}✅ Testing post-rename validation...${NC}"
    
    if [[ ${#RENAMED_FUNCTIONS[@]} -eq 0 ]]; then
        echo "  ℹ️  No renamed functions tracked - skipping post-rename validation"
        return 0
    fi
    
    local post_rename_issues=0
    
    for old_name in "${!RENAMED_FUNCTIONS[@]}"; do
        local new_name="${RENAMED_FUNCTIONS[$old_name]}"
        
        # Verify old function no longer exists
        if [[ -n "${FUNCTION_INVENTORY[$old_name]:-}" ]]; then
            echo "  ✗ Old function still exists: $old_name"
            ((post_rename_issues++))
        fi
        
        # Verify new function exists
        if [[ -z "${FUNCTION_INVENTORY[$new_name]:-}" ]]; then
            echo "  ✗ New function not found: $new_name"
            ((post_rename_issues++))
        else
            echo "  ✓ Rename successful: $old_name -> $new_name"
        fi
        
        # Check for remaining references to old name
        if [[ -n "${FUNCTION_REFERENCES[$old_name]:-}" ]]; then
            local ref_info="${FUNCTION_REFERENCES[$old_name]}"
            local ref_count="${ref_info%%:*}"
            echo "  ⚠  Found $ref_count remaining references to old name: $old_name"
            ((post_rename_issues++))
        fi
    done
    
    if [[ $post_rename_issues -eq 0 ]]; then
        echo "✓ Post-rename validation completed successfully"
        return 0
    else
        echo "✗ Found $post_rename_issues post-rename issues"
        return 1
    fi
}

#######################################################################
# REPORTING FUNCTIONS
#######################################################################

# Generates comprehensive function inventory report
generate_inventory_report() {
    echo -e "${RENAME_BOLD}${CYAN}📊 FUNCTION INVENTORY REPORT${NC}"
    echo "============================================"
    
    # Count by category
    local core_count=0 ops_count=0 gen_count=0
    
    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        local category="${FUNCTION_INVENTORY[$func_name]%%/*}"
        case "$category" in
            "core") ((core_count++)) ;;
            "ops") ((ops_count++)) ;;
            "gen") ((gen_count++)) ;;
        esac
    done
    
    echo "Core Libraries:       $core_count functions"
    echo "Operations Libraries: $ops_count functions"  
    echo "General Libraries:    $gen_count functions"
    echo "Total Functions:      ${#FUNCTION_INVENTORY[@]} functions"
    echo
    
    # Most referenced functions
    echo "Most Referenced Functions:"
    local -a sorted_refs=()
    for func_name in "${!FUNCTION_REFERENCES[@]}"; do
        local ref_count="${FUNCTION_REFERENCES[$func_name]%%:*}"
        sorted_refs+=("$ref_count:$func_name")
    done
    
    # Sort and display top 5
    IFS=$'\n' sorted_refs=($(sort -rn <<< "${sorted_refs[*]}"))
    for i in {0..4}; do
        if [[ -n "${sorted_refs[$i]:-}" ]]; then
            local ref_count="${sorted_refs[$i]%%:*}"
            local func_name="${sorted_refs[$i]#*:}"
            echo "  $((i+1)). $func_name ($ref_count references)"
        fi
    done
    echo
}

# Generates validation error summary
generate_error_summary() {
    if [[ ${#VALIDATION_ERRORS[@]} -eq 0 ]]; then
        echo -e "${GREEN}✅ No validation errors found${NC}"
        return 0
    fi
    
    echo -e "${RED}❌ VALIDATION ERRORS SUMMARY${NC}"
    echo "============================================"
    
    local error_count=1
    for error in "${VALIDATION_ERRORS[@]}"; do
        echo "$error_count. $error"
        ((error_count++))
    done
    
    echo
    echo "Total Errors: ${#VALIDATION_ERRORS[@]}"
    return 1
}

#######################################################################
# MAIN TEST EXECUTION
#######################################################################

# Pre-rename baseline establishment
run_pre_rename_tests() {
    echo -e "${RENAME_BOLD}${BLUE}🏁 PRE-RENAME BASELINE TESTS${NC}"
    echo "============================================"
    
    run_test "Function Discovery" discover_all_functions
    run_test "Reference Mapping" map_function_references  
    run_test "Dependency Analysis" analyze_function_dependencies
    run_test "Naming Conventions" test_function_naming_conventions
    run_test "Wrapper Integrity" test_wrapper_function_integrity
    run_test "Cross References" test_function_cross_references
    run_test "Dependency Chains" test_dependency_chains
    run_test "Configuration Consistency" test_configuration_consistency
    run_test "Batch Rename Simulation" test_batch_rename_scenario
    
    generate_inventory_report
}

# Post-rename validation
run_post_rename_tests() {
    echo -e "${RENAME_BOLD}${BLUE}🔍 POST-RENAME VALIDATION TESTS${NC}"
    echo "============================================"
    
    # Re-discover functions after rename
    run_test "Function Re-discovery" discover_all_functions
    run_test "Reference Re-mapping" map_function_references
    run_test "Dependency Re-analysis" analyze_function_dependencies
    run_test "Post-rename Validation" test_post_rename_validation
    run_test "Naming Conventions" test_function_naming_conventions
    run_test "Wrapper Integrity" test_wrapper_function_integrity
    run_test "Cross References" test_function_cross_references
    run_test "Dependency Chains" test_dependency_chains
    run_test "Configuration Consistency" test_configuration_consistency
    
    generate_inventory_report
}

# Show usage information
show_usage() {
    echo "Function Rename Test Module"
    echo
    echo "USAGE:"
    echo "  $0 [--pre-rename | --post-rename | --help]"
    echo
    echo "OPTIONS:"
    echo "  --pre-rename   Run before function renaming to establish baseline"
    echo "  --post-rename  Run after function renaming to validate changes"
    echo "  --help         Show this usage information"
    echo
    echo "DESCRIPTION:"
    echo "  This test module provides comprehensive validation for mass function"
    echo "  renaming scenarios in the /lib directory. It tracks function"
    echo "  dependencies, usage patterns, and ensures all references are"
    echo "  properly updated during refactoring operations."
    echo
    echo "EXAMPLES:"
    echo "  # Before renaming functions"
    echo "  $0 --pre-rename"
    echo
    echo "  # After renaming functions"  
    echo "  $0 --post-rename"
}

# Main execution function
main() {
    local mode="${1:-}"
    
    test_header "$TEST_NAME"
    
    case "$mode" in
        "--pre-rename")
            run_pre_rename_tests
            ;;
        "--post-rename") 
            run_post_rename_tests
            ;;
        "--help"|"-h")
            show_usage
            exit 0
            ;;
        "")
            echo "Running full function rename validation suite..."
            run_pre_rename_tests
            ;;
        *)
            echo "Error: Unknown option '$mode'"
            show_usage
            exit 1
            ;;
    esac
    
    generate_error_summary
    test_footer
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
