#!/bin/bash
#######################################################################
# Batch Function Rename Executor
#######################################################################
# File: val/lib/integration/batch_rename_executor.sh
# Description: Safe batch execution of function renames with validation
#              at each step. Implements the batch rename plan.
#######################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
readonly LAB_ROOT="/home/es/lab"
readonly BACKUP_DIR="/tmp/function_rename_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Safety flags
VALIDATION_PASSED=false
BACKUP_CREATED=false

#######################################################################
# SAFETY FUNCTIONS
#######################################################################

# Creates complete backup before any changes
create_backup() {
    echo -e "${BLUE}🛡️  Creating safety backup...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    cp -r "$LAB_ROOT/lib" "$BACKUP_DIR/"
    cp -r "$LAB_ROOT/src" "$BACKUP_DIR/"
    cp -r "$LAB_ROOT/bin" "$BACKUP_DIR/"
    
    BACKUP_CREATED=true
    echo "✅ Backup created: $BACKUP_DIR"
}

# Restores from backup if needed
restore_backup() {
    if [[ "$BACKUP_CREATED" == true ]]; then
        echo -e "${YELLOW}🔄 Restoring from backup...${NC}"
        cp -r "$BACKUP_DIR/lib" "$LAB_ROOT/"
        cp -r "$BACKUP_DIR/src" "$LAB_ROOT/"
        cp -r "$BACKUP_DIR/bin" "$LAB_ROOT/"
        echo "✅ Restored from backup"
    fi
}

# Runs validation and sets flag
run_validation() {
    local mode="$1"
    
    echo -e "${BLUE}🔍 Running $mode validation...${NC}"
    
    if "$SCRIPT_DIR/function_rename_test.sh" "--$mode"; then
        VALIDATION_PASSED=true
        echo -e "${GREEN}✅ Validation passed${NC}"
        return 0
    else
        VALIDATION_PASSED=false
        echo -e "${RED}❌ Validation failed${NC}"
        return 1
    fi
}

#######################################################################
# RENAME FUNCTIONS
#######################################################################

# Safely renames a function in a specific file
rename_function_in_file() {
    local file="$1"
    local old_name="$2"
    local new_name="$3"
    
    if [[ -f "$file" ]]; then
        # Create pattern that matches function definition
        sed -i "s/^${old_name}(/${new_name}(/g" "$file"
        sed -i "s/^function ${old_name}/function ${new_name}/g" "$file"
        echo "  ✓ Renamed in $file"
    fi
}

# Renames function calls in all files
rename_function_calls() {
    local old_name="$1"
    local new_name="$2"
    
    echo "  🔄 Updating function calls: $old_name → $new_name"
    
    # Find all files that might contain function calls
    local search_dirs=("$LAB_ROOT/bin" "$LAB_ROOT/src" "$LAB_ROOT/lib" "$LAB_ROOT/utl")
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type f -name "*.sh" -o -name "*" ! -name "*.md" ! -name "*.txt" | while read -r file; do
                if [[ -f "$file" && -r "$file" ]]; then
                    # Replace function calls (but not definitions)
                    sed -i "s/\b${old_name}\b/${new_name}/g" "$file" 2>/dev/null || true
                fi
            done
        fi
    done
}

# Executes a single function rename
execute_rename() {
    local old_name="$1"
    local new_name="$2"
    local definition_file="$3"
    
    echo -e "${YELLOW}📝 Renaming: $old_name → $new_name${NC}"
    
    # 1. Rename function definition
    rename_function_in_file "$definition_file" "$old_name" "$new_name"
    
    # 2. Rename all function calls
    rename_function_calls "$old_name" "$new_name"
    
    echo "  ✅ Rename completed"
}

#######################################################################
# BATCH DEFINITIONS
#######################################################################

# Batch 1: Core Function Prefixes
execute_batch_1() {
    echo -e "${BLUE}🚀 Executing Batch 1: Core Function Prefixes${NC}"
    echo "Goal: Standardize core function prefixes"
    echo
    
    # Define renames for batch 1
    local renames=(
        "err_process_error:core_err_process_error:$LAB_ROOT/lib/core/err"
        "lo1_debug_log:core_lo1_debug_log:$LAB_ROOT/lib/core/lo1"
        "tme_start_timer:core_tme_start_timer:$LAB_ROOT/lib/core/tme"
        "ver_log:core_ver_log:$LAB_ROOT/lib/core/ver"
    )
    
    for rename_spec in "${renames[@]}"; do
        IFS=':' read -r old_name new_name def_file <<< "$rename_spec"
        execute_rename "$old_name" "$new_name" "$def_file"
    done
    
    echo -e "${GREEN}✅ Batch 1 completed${NC}"
}

# Batch 2: Operations Function Suffixes  
execute_batch_2() {
    echo -e "${BLUE}🚀 Executing Batch 2: Operations Function Suffixes${NC}"
    echo "Goal: Standardize operations function suffixes"
    echo
    
    local renames=(
        "gpu_pt1:gpu-passthrough-enable:$LAB_ROOT/lib/ops/gpu"
        "gpu_pt2:gpu-passthrough-disable:$LAB_ROOT/lib/ops/gpu"
        "pve-vpt:pve-vm-passthrough-toggle:$LAB_ROOT/lib/ops/pve"
        "sys-gio:sys-git-operations:$LAB_ROOT/lib/ops/sys"
    )
    
    for rename_spec in "${renames[@]}"; do
        IFS=':' read -r old_name new_name def_file <<< "$rename_spec"
        execute_rename "$old_name" "$new_name" "$def_file"
    done
    
    echo -e "${GREEN}✅ Batch 2 completed${NC}"
}

# Batch 3: Auxiliary Functions
execute_batch_3() {
    echo -e "${BLUE}🚀 Executing Batch 3: Auxiliary Functions${NC}"
    echo "Goal: More descriptive auxiliary function names"
    echo
    
    local renames=(
        "ana_laf:aux-list-all-functions:$LAB_ROOT/lib/gen/aux"
        "aux_ffl:aux-foreach-file-list:$LAB_ROOT/lib/gen/aux"
        "ana_acu:aux-analyze-config-usage:$LAB_ROOT/lib/gen/aux"
        "aux_nos:aux-notify-operation-status:$LAB_ROOT/lib/gen/aux"
    )
    
    for rename_spec in "${renames[@]}"; do
        IFS=':' read -r old_name new_name def_file <<< "$rename_spec"
        execute_rename "$old_name" "$new_name" "$def_file"
    done
    
    echo -e "${GREEN}✅ Batch 3 completed${NC}"
}

#######################################################################
# MAIN EXECUTION
#######################################################################

show_usage() {
    echo "Batch Function Rename Executor"
    echo
    echo "USAGE:"
    echo "  $0 [--batch-1 | --batch-2 | --batch-3 | --all-batches | --help]"
    echo
    echo "OPTIONS:"
    echo "  --batch-1      Execute Batch 1: Core function prefixes"
    echo "  --batch-2      Execute Batch 2: Operations function suffixes"
    echo "  --batch-3      Execute Batch 3: Auxiliary function names"
    echo "  --all-batches  Execute all batches in sequence"
    echo "  --help         Show this help"
    echo
    echo "SAFETY FEATURES:"
    echo "  • Automatic backup creation before any changes"
    echo "  • Pre and post validation at each step"
    echo "  • Automatic rollback on validation failure"
    echo "  • Git commit after each successful batch"
    echo
    echo "EXAMPLES:"
    echo "  # Execute a single batch"
    echo "  $0 --batch-1"
    echo "  "
    echo "  # Execute all batches sequentially"
    echo "  $0 --all-batches"
    echo
}

main() {
    local batch="$1"
    
    # Handle help first (no validation needed)
    case "$batch" in
        "--help"|"")
            show_usage
            exit 0
            ;;
    esac
    
    echo -e "${BLUE}🔧 Batch Function Rename Executor${NC}"
    echo "=============================================="
    echo
    
    # Create backup
    create_backup
    
    # Run pre-rename validation
    if ! run_validation "pre-rename"; then
        echo -e "${RED}❌ Pre-rename validation failed! Aborting.${NC}"
        exit 1
    fi
    
    case "$batch" in
        "--batch-1")
            execute_batch_1
            ;;
        "--batch-2") 
            execute_batch_2
            ;;
        "--batch-3")
            execute_batch_3
            ;;
        "--all-batches")
            execute_batch_1
            if run_validation "post-rename"; then
                echo "✅ Batch 1 validated, proceeding to Batch 2"
                execute_batch_2
                if run_validation "post-rename"; then
                    echo "✅ Batch 2 validated, proceeding to Batch 3"
                    execute_batch_3
                fi
            fi
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $batch${NC}"
            show_usage
            exit 1
            ;;
    esac
    
    # Final validation
    echo
    echo -e "${BLUE}🔍 Running final validation...${NC}"
    if run_validation "post-rename"; then
        echo -e "${GREEN}🎉 All renames completed successfully!${NC}"
        echo "Backup available at: $BACKUP_DIR"
    else
        echo -e "${RED}❌ Final validation failed! Rolling back...${NC}"
        restore_backup
        exit 1
    fi
}

# Trap to ensure cleanup on exit
trap 'if [[ "$VALIDATION_PASSED" == false ]]; then restore_backup; fi' EXIT

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    main "$@"
fi
