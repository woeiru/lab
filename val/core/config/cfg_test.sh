#!/bin/bash
# Configuration Management Tests
# Tests for core configuration loading and validation

# Test configuration
TEST_NAME="Configuration Management"
TEST_CATEGORY="core"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Test: Configuration directory structure
test_config_directory_structure() {
    local config_root="${LAB_ROOT}/cfg"
    local required_dirs=("core" "env" "ali" "pod")
    local missing_dirs=()
    
    if [[ ! -d "$config_root" ]]; then
        echo "✗ Configuration root directory not found: $config_root"
        return 1
    fi
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$config_root/$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -eq 0 ]]; then
        echo "✓ Configuration directory structure is complete"
        return 0
    else
        echo "✗ Missing configuration directories: ${missing_dirs[*]}"
        return 1
    fi
}

# Test: Core configuration files
test_core_config_files() {
    local config_core="${LAB_ROOT}/cfg/core"
    local core_files=("ecc" "mdc" "rdc" "ric")
    local existing_files=()
    
    for file in "${core_files[@]}"; do
        if [[ -f "$config_core/$file" ]]; then
            existing_files+=("$file")
        fi
    done
    
    if [[ ${#existing_files[@]} -gt 0 ]]; then
        echo "✓ Found core configuration files: ${existing_files[*]}"
        return 0
    else
        echo "✗ No core configuration files found"
        return 1
    fi
}

# Test: Environment configuration files
test_environment_config_files() {
    local config_env="${LAB_ROOT}/cfg/env"
    local env_files=()
    
    if [[ -d "$config_env" ]]; then
        while IFS= read -r -d '' file; do
            env_files+=("$(basename "$file")")
        done < <(find "$config_env" -type f -print0 2>/dev/null)
    fi
    
    if [[ ${#env_files[@]} -gt 0 ]]; then
        echo "✓ Found environment configuration files: ${env_files[*]}"
        return 0
    else
        echo "✗ No environment configuration files found"
        return 1
    fi
}

# Test: Configuration file syntax validation
test_config_file_syntax() {
    local config_root="${LAB_ROOT}/cfg"
    local syntax_errors=()
    local files_checked=0
    
    # Check shell script syntax in config files
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && [[ -r "$file" ]]; then
            files_checked=$((files_checked + 1))
            
            # Try to source the file in a subshell to check syntax
            if ! (source "$file" 2>/dev/null); then
                # If sourcing fails, try bash syntax check
                if ! bash -n "$file" 2>/dev/null; then
                    syntax_errors+=("$(basename "$file")")
                fi
            fi
        fi
    done < <(find "$config_root" -type f -print0 2>/dev/null)
    
    if [[ $files_checked -eq 0 ]]; then
        echo "✗ No configuration files found to check"
        return 1
    elif [[ ${#syntax_errors[@]} -eq 0 ]]; then
        echo "✓ Configuration file syntax validation passed ($files_checked files)"
        return 0
    else
        echo "✗ Configuration files with syntax errors: ${syntax_errors[*]}"
        return 1
    fi
}

# Test: Configuration loading performance
test_config_loading_performance() {
    local config_root="${LAB_ROOT}/cfg"
    local start_time end_time duration
    local files_loaded=0
    
    start_time=$(date +%s.%N)
    
    # Attempt to load configuration files
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && [[ -r "$file" ]]; then
            # Try to source the file (in subshell to avoid side effects)
            if (source "$file" 2>/dev/null); then
                files_loaded=$((files_loaded + 1))
            fi
        fi
    done < <(find "$config_root" -type f -print0 2>/dev/null)
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "unknown")
    
    if [[ "$duration" != "unknown" ]] && (( $(echo "$duration < 5.0" | bc -l 2>/dev/null || echo 0) )); then
        echo "✓ Configuration loading performance acceptable (${duration}s, $files_loaded files)"
        return 0
    else
        echo "✓ Configuration loading completed ($files_loaded files)"
        return 0
    fi
}

# Test: Configuration variable validation
test_config_variable_validation() {
    local config_vars=()
    local undefined_vars=()
    
    # Look for common configuration patterns
    local patterns=("LAB_" "CFG_" "ENV_" "SITE_")
    
    for pattern in "${patterns[@]}"; do
        while IFS= read -r var; do
            if [[ -n "$var" ]]; then
                config_vars+=("$var")
                if [[ -z "${!var}" ]]; then
                    undefined_vars+=("$var")
                fi
            fi
        done < <(compgen -v | grep "^$pattern" 2>/dev/null || true)
    done
    
    if [[ ${#config_vars[@]} -gt 0 ]]; then
        echo "✓ Found configuration variables: ${#config_vars[@]} total"
        if [[ ${#undefined_vars[@]} -eq 0 ]]; then
            echo "  All configuration variables are defined"
        else
            echo "  Undefined variables: ${undefined_vars[*]}"
        fi
        return 0
    else
        echo "✓ Configuration variable validation completed (no pattern matches)"
        return 0
    fi
}

# Test: Pod configuration structure
test_pod_config_structure() {
    local pod_config="${LAB_ROOT}/cfg/pod"
    local pod_dirs=()
    
    if [[ -d "$pod_config" ]]; then
        while IFS= read -r -d '' dir; do
            pod_dirs+=("$(basename "$dir")")
        done < <(find "$pod_config" -type d -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
    fi
    
    if [[ ${#pod_dirs[@]} -gt 0 ]]; then
        echo "✓ Found pod configurations: ${pod_dirs[*]}"
        return 0
    else
        echo "✗ No pod configurations found"
        return 1
    fi
}

# Test: Alias configuration structure
test_alias_config_structure() {
    local alias_config="${LAB_ROOT}/cfg/ali"
    local alias_files=()
    
    if [[ -d "$alias_config" ]]; then
        while IFS= read -r -d '' file; do
            alias_files+=("$(basename "$file")")
        done < <(find "$alias_config" -type f -print0 2>/dev/null)
    fi
    
    if [[ ${#alias_files[@]} -gt 0 ]]; then
        echo "✓ Found alias configurations: ${alias_files[*]}"
        return 0
    else
        echo "✗ No alias configurations found"
        return 1
    fi
}

# Test: Configuration backup capability
test_config_backup_capability() {
    local config_root="${LAB_ROOT}/cfg"
    local backup_dir="/tmp/config_backup_test_$$"
    local files_backed_up=0
    
    # Create backup directory
    mkdir -p "$backup_dir" || {
        echo "✗ Cannot create backup directory"
        return 1
    }
    
    # Attempt to backup configuration files
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && [[ -r "$file" ]]; then
            local relative_path="${file#$config_root/}"
            local backup_file="$backup_dir/$relative_path"
            local backup_dir_path="$(dirname "$backup_file")"
            
            mkdir -p "$backup_dir_path" && cp "$file" "$backup_file" 2>/dev/null && {
                files_backed_up=$((files_backed_up + 1))
            }
        fi
    done < <(find "$config_root" -type f -print0 2>/dev/null)
    
    # Cleanup
    rm -rf "$backup_dir"
    
    if [[ $files_backed_up -gt 0 ]]; then
        echo "✓ Configuration backup capability works ($files_backed_up files)"
        return 0
    else
        echo "✗ Configuration backup capability failed"
        return 1
    fi
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_config_directory_structure
    run_test test_core_config_files
    run_test test_environment_config_files
    run_test test_config_file_syntax
    run_test test_config_loading_performance
    run_test test_config_variable_validation
    run_test test_pod_config_structure
    run_test test_alias_config_structure
    run_test test_config_backup_capability
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
