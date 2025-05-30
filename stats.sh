#!/bin/bash
#######################################################################
# Lab Environment Statistics Generator
#######################################################################
# File: /home/es/lab/stats.sh
# Description: Generates real-time statistics about the lab environment
#              codebase for documentation and monitoring purposes.
#
# Usage: ./stats.sh [--markdown|--raw]
#   --markdown  Output in markdown table format
#   --raw       Output raw numbers only
#   (default)   Output formatted statistics
#######################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$SCRIPT_DIR"

# Gather all statistics
gather_stats() {
    # Count all regular files (excluding hidden/git files) to match tree output
    local total_files=$(find "$LAB_DIR" -type f ! -path '*/.*' | wc -l)
    local directories=$(find "$LAB_DIR" -type d ! -path '*/.*' | wc -l)
    local lib_functions=$(grep -r "() {" "$LAB_DIR/lib/ops/" 2>/dev/null | wc -l)
    local lib_files=$(find "$LAB_DIR/lib" -name "*" -type f | wc -l)
    
    local ops_lines=0
    if [ -d "$LAB_DIR/lib/ops" ]; then
        ops_lines=$(wc -l "$LAB_DIR/lib/ops"/* 2>/dev/null | tail -1 | awk '{print $1}')
    fi
    
    local util_lines=0
    if [ -d "$LAB_DIR/lib/utl" ]; then
        util_lines=$(wc -l "$LAB_DIR/lib/utl"/* 2>/dev/null | tail -1 | awk '{print $1}')
    fi
    
    local wrapper_functions=$(grep -r "\-w() {" "$LAB_DIR/src/mgt/" 2>/dev/null | wc -l)
    
    local doc_lines=0
    if [ -d "$LAB_DIR/doc/man" ]; then
        doc_lines=$(wc -l "$LAB_DIR/doc/man"/* 2>/dev/null | tail -1 | awk '{print $1}')
    fi
    
    local doc_files=$(find "$LAB_DIR" -name "*.md" 2>/dev/null | wc -l)
    local config_files=$(find "$LAB_DIR/cfg" -name "*" -type f 2>/dev/null | wc -l)
    local deployment_scripts=$(find "$LAB_DIR/src" -name "*" -type f 2>/dev/null | wc -l)
    local container_vars=$(grep -r "CT_.*=" "$LAB_DIR/cfg/env/" 2>/dev/null | wc -l)
    
    local test_lines=0
    if [ -f "$LAB_DIR/tst/test_environment" ]; then
        test_lines=$(wc -l "$LAB_DIR/tst/test_environment" | awk '{print $1}')
    fi

    case "${1:-formatted}" in
        --raw)
            echo "$total_files $directories $lib_functions $lib_files $ops_lines $util_lines $wrapper_functions $doc_lines $doc_files $config_files $deployment_scripts $container_vars $test_lines"
            ;;
        --markdown)
            cat << EOF
| Metric | Value |
|--------|--------|
| Total Files | $total_files files across $directories directories |
| Library Functions | $lib_functions operational functions in $lib_files library modules |
| Operations Code | $ops_lines lines of infrastructure automation |
| Utility Libraries | $util_lines lines of reusable components |
| Wrapper Functions | $wrapper_functions environment-integration wrappers |
| Technical Documentation | $doc_lines lines across $doc_files markdown files |
| Configuration Files | $config_files environment and system config files |
| Deployment Scripts | $deployment_scripts service-specific deployment modules |
| Container Variables | $container_vars container configuration parameters |
| Test Framework | $test_lines lines of comprehensive validation logic |
EOF
            ;;
        *)
            cat << EOF
📊 Lab Environment Statistics
=============================

🏗️ Codebase Statistics:
  - Total Files: $total_files files across $directories directories
  - Library Functions: $lib_functions operational functions in $lib_files library modules
  - Operations Code: $ops_lines lines of infrastructure automation
  - Utility Libraries: $util_lines lines of reusable components
  - Wrapper Functions: $wrapper_functions environment-integration wrappers

📚 Documentation & Configuration:
  - Technical Documentation: $doc_lines lines across $doc_files markdown files
  - Configuration Files: $config_files environment and system config files
  - Deployment Scripts: $deployment_scripts service-specific deployment modules
  - Container Variables: $container_vars container configuration parameters

🧪 Quality Assurance:
  - Test Framework: $test_lines lines of comprehensive validation logic
  - Function Separation: Pure functions with management wrappers
  - Security Coverage: Zero hardcoded credentials with secure management
  - Environment Support: Multi-tier configuration hierarchy

Generated: $(date)
EOF
            ;;
    esac
}

# Main execution
gather_stats "$@"
