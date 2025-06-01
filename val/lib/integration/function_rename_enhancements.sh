#!/bin/bash
#######################################################################
# Function Rename Test Enhancements
#######################################################################
# File: val/lib/integration/function_rename_enhancements.sh
# Description: Additional enhancements and utilities for the comprehensive
#              function rename test module. These extend the existing
#              capabilities with modern DevOps practices.
#
# PURPOSE:
#   Provides additional functionality to complement the existing
#   function_rename_test.sh module with:
#   - JSON/YAML output for CI/CD integration
#   - Performance benchmarking
#   - Git integration for rename tracking
#   - Advanced pattern analysis
#   - Automated fix suggestions
#######################################################################

# Source the main function rename test module
source "$(dirname "${BASH_SOURCE[0]}")/function_rename_test.sh"

# Enhanced configuration
readonly ENHANCEMENT_VERSION="1.0.0"
readonly OUTPUT_DIR="/tmp/function_rename_analysis"
readonly BENCHMARK_ITERATIONS=3

#######################################################################
# JSON/YAML OUTPUT FOR CI/CD INTEGRATION
#######################################################################

# Generates JSON report for CI/CD systems
generate_json_report() {
    local output_file="${OUTPUT_DIR}/function_rename_report.json"
    mkdir -p "$(dirname "$output_file")"
    
    echo "📄 Generating JSON report for CI/CD integration..."
    
    cat > "$output_file" << EOF
{
  "metadata": {
    "timestamp": "$(date -Iseconds)",
    "version": "$ENHANCEMENT_VERSION",
    "lab_directory": "$TEST_LAB_DIR",
    "test_mode": "${TEST_MODE:-pre-rename}"
  },
  "summary": {
    "total_functions": ${#FUNCTION_INVENTORY[@]},
    "total_references": $(echo "${FUNCTION_REFERENCES[@]}" | wc -w),
    "total_dependencies": ${#FUNCTION_DEPENDENCIES[@]},
    "validation_errors": ${#VALIDATION_ERRORS[@]}
  },
  "functions": {
EOF

    local first=true
    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        [[ "$first" == false ]] && echo "," >> "$output_file"
        first=false
        
        local ref_info="${FUNCTION_REFERENCES[$func_name]:-0:}"
        local ref_count="${ref_info%%:*}"
        local dependencies="${FUNCTION_DEPENDENCIES[$func_name]:-}"
        
        cat >> "$output_file" << EOF
    "$func_name": {
      "category": "${FUNCTION_INVENTORY[$func_name]%%/*}",
      "file": "${FUNCTION_INVENTORY[$func_name]}",
      "references": $ref_count,
      "dependencies": ["$(echo "$dependencies" | sed 's/ /", "/g')"]
    }
EOF
    done

    cat >> "$output_file" << EOF
  },
  "validation_errors": [
$(printf '    "%s"' "${VALIDATION_ERRORS[@]}" | paste -sd ',' -)
  ]
}
EOF

    echo "✓ JSON report generated: $output_file"
    return 0
}

# Generates YAML report for GitLab CI/Kubernetes
generate_yaml_report() {
    local output_file="${OUTPUT_DIR}/function_rename_report.yaml"
    mkdir -p "$(dirname "$output_file")"
    
    echo "📄 Generating YAML report for GitLab CI/Kubernetes..."
    
    cat > "$output_file" << EOF
---
metadata:
  timestamp: $(date -Iseconds)
  version: $ENHANCEMENT_VERSION
  lab_directory: $TEST_LAB_DIR
  test_mode: ${TEST_MODE:-pre-rename}

summary:
  total_functions: ${#FUNCTION_INVENTORY[@]}
  total_references: $(echo "${FUNCTION_REFERENCES[@]}" | wc -w)
  total_dependencies: ${#FUNCTION_DEPENDENCIES[@]}
  validation_errors: ${#VALIDATION_ERRORS[@]}

functions:
EOF

    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        local ref_info="${FUNCTION_REFERENCES[$func_name]:-0:}"
        local ref_count="${ref_info%%:*}"
        local dependencies="${FUNCTION_DEPENDENCIES[$func_name]:-}"
        
        cat >> "$output_file" << EOF
  $func_name:
    category: ${FUNCTION_INVENTORY[$func_name]%%/*}
    file: ${FUNCTION_INVENTORY[$func_name]}
    references: $ref_count
    dependencies: [$(echo "$dependencies" | sed 's/ /, /g')]
EOF
    done

    if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
        echo "validation_errors:" >> "$output_file"
        for error in "${VALIDATION_ERRORS[@]}"; do
            echo "  - \"$error\"" >> "$output_file"
        done
    fi

    echo "✓ YAML report generated: $output_file"
    return 0
}

#######################################################################
# PERFORMANCE BENCHMARKING
#######################################################################

# Benchmarks function discovery performance
benchmark_discovery_performance() {
    echo "⏱️  Benchmarking function discovery performance..."
    
    local total_time=0
    local results=()
    
    for ((i=1; i<=BENCHMARK_ITERATIONS; i++)); do
        echo "  Run $i/$BENCHMARK_ITERATIONS..."
        
        # Clear previous results
        unset FUNCTION_INVENTORY
        declare -A FUNCTION_INVENTORY
        
        local start_time=$(date +%s.%N)
        discover_all_functions > /dev/null 2>&1
        local end_time=$(date +%s.%N)
        
        local iteration_time=$(echo "$end_time - $start_time" | bc -l)
        results+=("$iteration_time")
        total_time=$(echo "$total_time + $iteration_time" | bc -l)
    done
    
    local avg_time=$(echo "scale=3; $total_time / $BENCHMARK_ITERATIONS" | bc -l)
    local functions_per_second=$(echo "scale=1; ${#FUNCTION_INVENTORY[@]} / $avg_time" | bc -l)
    
    echo "📊 Performance Results:"
    echo "  Average discovery time: ${avg_time}s"
    echo "  Functions per second: $functions_per_second"
    echo "  Total functions: ${#FUNCTION_INVENTORY[@]}"
    
    # Generate benchmark report
    local benchmark_file="${OUTPUT_DIR}/benchmark_report.json"
    cat > "$benchmark_file" << EOF
{
  "benchmark": {
    "timestamp": "$(date -Iseconds)",
    "iterations": $BENCHMARK_ITERATIONS,
    "total_functions": ${#FUNCTION_INVENTORY[@]},
    "average_time_seconds": $avg_time,
    "functions_per_second": $functions_per_second,
    "individual_runs": [$(printf '%.3f' "${results[@]}" | paste -sd ',' -)]
  }
}
EOF
    
    echo "✓ Benchmark report: $benchmark_file"
    return 0
}

#######################################################################
# GIT INTEGRATION
#######################################################################

# Tracks function renames in git history
analyze_git_rename_history() {
    echo "🔍 Analyzing git rename history..."
    
    if ! git -C "$TEST_LAB_DIR" rev-parse --git-dir > /dev/null 2>&1; then
        echo "⚠️  Not a git repository or git not available"
        return 1
    fi
    
    local git_log_file="${OUTPUT_DIR}/git_rename_history.log"
    mkdir -p "$(dirname "$git_log_file")"
    
    # Find commits that might contain function renames
    git -C "$TEST_LAB_DIR" log --oneline --grep="rename\|refactor" \
        --since="1 month ago" > "$git_log_file"
    
    echo "📊 Recent rename-related commits:"
    if [[ -s "$git_log_file" ]]; then
        head -10 "$git_log_file" | while read -r line; do
            echo "  $line"
        done
        echo "  (Full log: $git_log_file)"
    else
        echo "  No recent rename-related commits found"
    fi
    
    return 0
}

# Creates git pre-commit hook for function rename validation
install_git_hook() {
    echo "🔧 Installing git pre-commit hook for function validation..."
    
    local hooks_dir="$TEST_LAB_DIR/.git/hooks"
    local hook_file="$hooks_dir/pre-commit"
    
    if [[ ! -d "$hooks_dir" ]]; then
        echo "⚠️  Git hooks directory not found: $hooks_dir"
        return 1
    fi
    
    # Backup existing hook if it exists
    if [[ -f "$hook_file" ]]; then
        cp "$hook_file" "${hook_file}.backup.$(date +%s)"
        echo "  Backed up existing pre-commit hook"
    fi
    
    cat > "$hook_file" << 'EOF'
#!/bin/bash
# Auto-generated pre-commit hook for function rename validation

echo "🔍 Running function rename validation..."

# Run the function rename test in pre-rename mode
if ! /home/es/lab/val/lib/integration/function_rename_test.sh --pre-rename; then
    echo "❌ Function validation failed!"
    echo "Please resolve validation errors before committing."
    exit 1
fi

echo "✅ Function validation passed!"
exit 0
EOF
    
    chmod +x "$hook_file"
    echo "✓ Git pre-commit hook installed: $hook_file"
    return 0
}

#######################################################################
# ADVANCED PATTERN ANALYSIS
#######################################################################

# Analyzes function naming patterns and suggests improvements
analyze_naming_patterns() {
    echo "🔍 Analyzing function naming patterns..."
    
    local pattern_analysis="${OUTPUT_DIR}/pattern_analysis.txt"
    mkdir -p "$(dirname "$pattern_analysis")"
    
    # Count patterns
    declare -A pattern_counts
    declare -A category_patterns
    
    for func_name in "${!FUNCTION_INVENTORY[@]}"; do
        local category="${FUNCTION_INVENTORY[$func_name]%%/*}"
        
        # Extract pattern (prefix-suffix)
        if [[ "$func_name" =~ ^([a-z]+)-([a-z]+)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local suffix="${BASH_REMATCH[2]}"
            local pattern="$prefix-$suffix"
            
            ((pattern_counts["$pattern"]++))
            category_patterns["$category:$pattern"]="${category_patterns["$category:$pattern"]:-0}"
            ((category_patterns["$category:$pattern"]++))
        fi
    done
    
    {
        echo "FUNCTION NAMING PATTERN ANALYSIS"
        echo "================================"
        echo "Generated: $(date)"
        echo
        
        echo "Most Common Patterns:"
        for pattern in "${!pattern_counts[@]}"; do
            echo "  $pattern: ${pattern_counts[$pattern]} functions"
        done | sort -k2 -nr | head -10
        
        echo
        echo "Patterns by Category:"
        for cat_pattern in "${!category_patterns[@]}"; do
            local category="${cat_pattern%%:*}"
            local pattern="${cat_pattern#*:}"
            echo "  [$category] $pattern: ${category_patterns[$cat_pattern]} functions"
        done | sort
        
    } > "$pattern_analysis"
    
    echo "✓ Pattern analysis completed: $pattern_analysis"
    return 0
}

# Suggests function rename improvements
suggest_rename_improvements() {
    echo "💡 Generating rename improvement suggestions..."
    
    local suggestions_file="${OUTPUT_DIR}/rename_suggestions.txt"
    mkdir -p "$(dirname "$suggestions_file")"
    
    {
        echo "FUNCTION RENAME IMPROVEMENT SUGGESTIONS"
        echo "======================================"
        echo "Generated: $(date)"
        echo
        
        # Find inconsistent naming
        echo "1. INCONSISTENT NAMING PATTERNS:"
        for func_name in "${!FUNCTION_INVENTORY[@]}"; do
            if [[ ! "$func_name" =~ ^[a-z]+-[a-z]+$ ]]; then
                local category="${FUNCTION_INVENTORY[$func_name]%%/*}"
                echo "  ⚠️  $func_name (in $category) - doesn't follow prefix-suffix pattern"
            fi
        done
        
        echo
        echo "2. LONG FUNCTION NAMES (>12 characters):"
        for func_name in "${!FUNCTION_INVENTORY[@]}"; do
            if [[ ${#func_name} -gt 12 ]]; then
                echo "  📏 $func_name (${#func_name} chars) - consider shortening"
            fi
        done
        
        echo
        echo "3. POTENTIAL CATEGORY MISMATCHES:"
        for func_name in "${!FUNCTION_INVENTORY[@]}"; do
            local category="${FUNCTION_INVENTORY[$func_name]%%/*}"
            local prefix="${func_name%%-*}"
            
            # Check if prefix matches category expectations
            case "$category" in
                "ops")
                    if [[ ! "$prefix" =~ ^(pve|gpu|sys|net|sto|ssh|usr|srv|pbs)$ ]]; then
                        echo "  🔄 $func_name - consider prefix matching ops category"
                    fi
                    ;;
                "gen")
                    if [[ ! "$prefix" =~ ^(aux|env|inf|sec)$ ]]; then
                        echo "  🔄 $func_name - consider prefix matching gen category"
                    fi
                    ;;
                "core")
                    if [[ ! "$prefix" =~ ^(err|lo1|tme|ver)$ ]]; then
                        echo "  🔄 $func_name - consider prefix matching core category"
                    fi
                    ;;
            esac
        done
        
    } > "$suggestions_file"
    
    echo "✓ Rename suggestions generated: $suggestions_file"
    return 0
}

#######################################################################
# AUTOMATED FIX SUGGESTIONS
#######################################################################

# Generates automated fix scripts for common issues
generate_fix_scripts() {
    echo "🔧 Generating automated fix scripts..."
    
    local fix_script="${OUTPUT_DIR}/automated_fixes.sh"
    mkdir -p "$(dirname "$fix_script")"
    
    cat > "$fix_script" << 'EOF'
#!/bin/bash
# Auto-generated fix script for function rename issues
# Generated by function_rename_enhancements.sh

set -euo pipefail

echo "🔧 Running automated fixes for function rename issues..."

# Function to safely rename function in file
rename_function_in_file() {
    local file="$1"
    local old_name="$2" 
    local new_name="$3"
    
    if [[ -f "$file" ]]; then
        # Create backup
        cp "$file" "${file}.backup.$(date +%s)"
        
        # Replace function definition
        sed -i "s/^${old_name}()/${new_name}()/g" "$file"
        
        # Replace function calls
        sed -i "s/\\b${old_name}\\b/${new_name}/g" "$file"
        
        echo "  ✓ Updated $file: $old_name -> $new_name"
    fi
}

# Add specific fixes based on validation errors here
# This would be populated based on the errors found

echo "✅ Automated fixes completed!"
echo "⚠️  Please review changes before committing."
EOF
    
    chmod +x "$fix_script"
    echo "✓ Fix script generated: $fix_script"
    return 0
}

#######################################################################
# ENHANCED MAIN EXECUTION
#######################################################################

# Enhanced main function with additional modes
enhanced_main() {
    local mode="${1:-}"
    local subcommand="${2:-}"
    
    case "$mode" in
        "--benchmark")
            test_header "Function Rename Performance Benchmark"
            benchmark_discovery_performance
            ;;
        "--json-report")
            discover_all_functions
            map_function_references
            generate_json_report
            ;;
        "--yaml-report")
            discover_all_functions  
            map_function_references
            generate_yaml_report
            ;;
        "--git-analysis")
            analyze_git_rename_history
            ;;
        "--install-hook")
            install_git_hook
            ;;
        "--pattern-analysis")
            discover_all_functions
            analyze_naming_patterns
            suggest_rename_improvements
            ;;
        "--generate-fixes")
            discover_all_functions
            map_function_references
            analyze_function_dependencies
            generate_fix_scripts
            ;;
        "--enhanced-pre-rename")
            echo "🚀 Enhanced pre-rename validation with CI/CD integration..."
            TEST_MODE="pre-rename"
            run_pre_rename_tests
            generate_json_report
            generate_yaml_report
            analyze_naming_patterns
            ;;
        "--enhanced-post-rename")
            echo "🚀 Enhanced post-rename validation with CI/CD integration..."
            TEST_MODE="post-rename"
            run_post_rename_tests
            generate_json_report
            generate_yaml_report
            benchmark_discovery_performance
            ;;
        "--help-enhanced"|"-he")
            show_enhanced_usage
            exit 0
            ;;
        *)
            # Delegate to original main function
            main "$@"
            ;;
    esac
}

# Enhanced usage information
show_enhanced_usage() {
    echo "Function Rename Test Enhancements"
    echo
    echo "USAGE:"
    echo "  $0 [ENHANCED_OPTIONS] | [ORIGINAL_OPTIONS]"
    echo
    echo "ENHANCED OPTIONS:"
    echo "  --benchmark           Run performance benchmarks"
    echo "  --json-report         Generate JSON report for CI/CD"
    echo "  --yaml-report         Generate YAML report for GitLab CI/K8s"
    echo "  --git-analysis        Analyze git rename history"
    echo "  --install-hook        Install git pre-commit hook"
    echo "  --pattern-analysis    Analyze function naming patterns"
    echo "  --generate-fixes      Generate automated fix scripts"
    echo "  --enhanced-pre-rename Complete pre-rename with CI/CD outputs"
    echo "  --enhanced-post-rename Complete post-rename with CI/CD outputs"
    echo "  --help-enhanced       Show enhanced usage information"
    echo
    echo "ORIGINAL OPTIONS:"
    echo "  --pre-rename          Run original pre-rename validation"
    echo "  --post-rename         Run original post-rename validation"
    echo "  --help                Show original usage information"
    echo
    echo "OUTPUT DIRECTORY:"
    echo "  Reports and artifacts: $OUTPUT_DIR"
}

# Run enhanced version if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    enhanced_main "$@"
fi
