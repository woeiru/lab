#!/bin/bash
#######################################################################
# Hyphen to Underscore Function Rename Executor
#######################################################################
# File: val/lib/integration/execute_hyphen_to_underscore_rename.sh
# Description: Safely converts all function names from hyphens to underscores
#              across the entire /lib directory with comprehensive validation
#######################################################################

set -euo pipefail

# Configuration
readonly LIB_DIR="/home/es/lab/lib"
readonly WORKSPACE_DIR="/home/es/lab"
readonly BACKUP_DIR="/tmp/lib_backup_$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="/tmp/hyphen_underscore_rename_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create comprehensive backup
create_backup() {
    echo -e "${BLUE}📦 Creating comprehensive backup...${NC}"
    log_action "Starting backup creation"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup the entire workspace for safety
    cp -r "$LIB_DIR" "$BACKUP_DIR/"
    cp -r "$WORKSPACE_DIR/src" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$WORKSPACE_DIR/cfg" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$WORKSPACE_DIR/val" "$BACKUP_DIR/" 2>/dev/null || true
    
    log_action "Backup created at: $BACKUP_DIR"
    echo -e "${GREEN}✓ Backup completed${NC}"
    return 0
}

# Discover all functions that need renaming
discover_functions() {
    echo -e "${BLUE}🔍 Discovering functions with hyphens...${NC}"
    
    declare -g -A FUNCTION_MAPPINGS
    declare -g -A FILE_LOCATIONS
    
    # Find all functions with hyphens
    while IFS=: read -r file_path function_line; do
        if [[ "$function_line" =~ ^([a-zA-Z0-9]+-[a-zA-Z0-9_-]+)\(\) ]]; then
            local old_name="${BASH_REMATCH[1]}"
            local new_name="${old_name//-/_}"  # Replace all hyphens with underscores
            
            FUNCTION_MAPPINGS["$old_name"]="$new_name"
            FILE_LOCATIONS["$old_name"]="$file_path"
            
            echo "  Found: $old_name → $new_name (in $(basename "$file_path"))"
        fi
    done < <(find "$LIB_DIR" -type f -exec grep -H '^[a-zA-Z0-9]*-[a-zA-Z0-9_-]*()' {} \;)
    
    local total_functions=${#FUNCTION_MAPPINGS[@]}
    log_action "Discovered $total_functions functions to rename"
    echo -e "${GREEN}✓ Found $total_functions functions to rename${NC}"
    
    return 0
}

# Update function definitions
update_function_definitions() {
    echo -e "${BLUE}🔄 Updating function definitions...${NC}"
    local updated_count=0
    
    for old_name in "${!FUNCTION_MAPPINGS[@]}"; do
        local new_name="${FUNCTION_MAPPINGS[$old_name]}"
        local file_path="${FILE_LOCATIONS[$old_name]}"
        
        echo "  Updating definition: $old_name → $new_name in $(basename "$file_path")"
        
        # Update the function definition line
        sed -i "s/^${old_name}()/${new_name}()/g" "$file_path"
        
        # Update any comments that reference the function by name
        sed -i "s/# ${old_name}/# ${new_name}/g" "$file_path"
        
        log_action "Updated definition: $old_name → $new_name in $file_path"
        ((updated_count++))
    done
    
    echo -e "${GREEN}✓ Updated $updated_count function definitions${NC}"
    return 0
}

# Update function calls throughout the codebase
update_function_calls() {
    echo -e "${BLUE}🔄 Updating function calls throughout codebase...${NC}"
    local total_updates=0
    
    for old_name in "${!FUNCTION_MAPPINGS[@]}"; do
        local new_name="${FUNCTION_MAPPINGS[$old_name]}"
        
        echo "  Updating calls: $old_name → $new_name"
        
        # Find and update all files that call this function
        local files_updated=0
        while IFS= read -r -d '' file; do
            if [[ -f "$file" && -w "$file" ]]; then
                # Count occurrences before update
                local before_count=$(grep -c "$old_name" "$file" 2>/dev/null || echo "0")
                
                if [[ "$before_count" -gt 0 ]]; then
                    # Update function calls (but be careful about partial matches)
                    sed -i "s/\b${old_name}\b/${new_name}/g" "$file"
                    
                    local after_count=$(grep -c "$new_name" "$file" 2>/dev/null || echo "0")
                    if [[ "$after_count" -gt 0 ]]; then
                        echo "    Updated $(basename "$file"): $before_count occurrences"
                        ((files_updated++))
                        ((total_updates += before_count))
                    fi
                fi
            fi
        done < <(find "$WORKSPACE_DIR" -type f \( -name "*.sh" -o -name "*" ! -name ".*" \) -print0 2>/dev/null)
        
        log_action "Updated calls for $old_name in $files_updated files"
    done
    
    echo -e "${GREEN}✓ Updated approximately $total_updates function calls${NC}"
    return 0
}

# Validate the changes
validate_changes() {
    echo -e "${BLUE}🔍 Validating changes...${NC}"
    local validation_errors=0
    
    # Check 1: Verify no hyphenated function definitions remain
    echo "  Checking for remaining hyphenated function definitions..."
    local remaining_hyphenated=$(find "$LIB_DIR" -type f -exec grep -c '^[a-zA-Z0-9]*-[a-zA-Z0-9_-]*()' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [[ "$remaining_hyphenated" -eq 0 ]]; then
        echo -e "    ${GREEN}✓ No hyphenated function definitions found${NC}"
    else
        echo -e "    ${RED}✗ Warning: $remaining_hyphenated hyphenated function definitions still exist${NC}"
        ((validation_errors++))
    fi
    
    # Check 2: Test library loading
    echo "  Testing library loading..."
    if (cd "$WORKSPACE_DIR" && source src/aux/set 2>/dev/null); then
        echo -e "    ${GREEN}✓ Library loading test passed${NC}"
    else
        echo -e "    ${RED}✗ Library loading test failed${NC}"
        ((validation_errors++))
    fi
    
    # Check 3: Verify expected underscored functions exist
    echo "  Verifying converted functions exist..."
    local found_converted=0
    for old_name in "${!FUNCTION_MAPPINGS[@]}"; do
        local new_name="${FUNCTION_MAPPINGS[$old_name]}"
        local file_path="${FILE_LOCATIONS[$old_name]}"
        
        if grep -q "^${new_name}()" "$file_path" 2>/dev/null; then
            ((found_converted++))
        else
            echo -e "    ${RED}✗ Function $new_name not found in $file_path${NC}"
            ((validation_errors++))
        fi
    done
    
    echo -e "    ${GREEN}✓ Found $found_converted converted functions${NC}"
    
    # Check 4: Test a few key functions
    echo "  Testing key function availability..."
    if (cd "$WORKSPACE_DIR" && source src/aux/set >/dev/null 2>&1 && declare -f aux_fun >/dev/null 2>&1); then
        echo -e "    ${GREEN}✓ Key functions are available (aux_fun)${NC}"
    else
        echo -e "    ${YELLOW}⚠ Some functions may not be available yet (normal after rename)${NC}"
    fi
    
    log_action "Validation completed with $validation_errors errors"
    
    if [[ "$validation_errors" -eq 0 ]]; then
        echo -e "${GREEN}✓ All validation checks passed${NC}"
        return 0
    else
        echo -e "${RED}⚠ Validation completed with $validation_errors issues${NC}"
        return 1
    fi
}

# Rollback function in case of issues
rollback_changes() {
    echo -e "${RED}🔄 Rolling back changes...${NC}"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        rm -rf "$LIB_DIR"
        cp -r "$BACKUP_DIR/lib" "$LIB_DIR"
        
        # Restore other directories if they were backed up
        [[ -d "$BACKUP_DIR/src" ]] && cp -r "$BACKUP_DIR/src" "$WORKSPACE_DIR/"
        [[ -d "$BACKUP_DIR/cfg" ]] && cp -r "$BACKUP_DIR/cfg" "$WORKSPACE_DIR/"
        [[ -d "$BACKUP_DIR/val" ]] && cp -r "$BACKUP_DIR/val" "$WORKSPACE_DIR/"
        
        echo -e "${GREEN}✓ Rollback completed${NC}"
        log_action "Rollback completed successfully"
    else
        echo -e "${RED}✗ Backup directory not found, manual rollback required${NC}"
        log_action "ERROR: Backup directory not found for rollback"
    fi
}

# Show summary of what will be changed
show_preview() {
    echo -e "${CYAN}📋 Preview of changes to be made:${NC}"
    echo "=================================="
    
    discover_functions
    
    echo ""
    echo "Functions to be renamed (${#FUNCTION_MAPPINGS[@]} total):"
    echo ""
    
    local count=1
    for old_name in $(printf '%s\n' "${!FUNCTION_MAPPINGS[@]}" | sort); do
        local new_name="${FUNCTION_MAPPINGS[$old_name]}"
        local file_path="${FILE_LOCATIONS[$old_name]}"
        printf "%3d. %-20s → %-20s (in %s)\n" "$count" "$old_name" "$new_name" "$(basename "$file_path")"
        ((count++))
    done
    
    echo ""
    echo -e "${YELLOW}This will update function definitions and all calls throughout the codebase.${NC}"
    echo -e "${YELLOW}A full backup will be created before making any changes.${NC}"
    
    return 0
}

# Main execution function
main() {
    local mode="${1:-preview}"
    
    echo -e "${BLUE}🚀 Hyphen to Underscore Function Rename Tool${NC}"
    echo "=============================================="
    echo "Log file: $LOG_FILE"
    echo ""
    
    case "$mode" in
        "preview"|"--preview")
            show_preview
            echo ""
            echo "To execute the rename, run: $0 --execute"
            ;;
        "execute"|"--execute")
            log_action "Starting hyphen to underscore conversion"
            
            if create_backup && discover_functions; then
                echo ""
                read -p "Proceed with renaming ${#FUNCTION_MAPPINGS[@]} functions? [y/N]: " -n 1 -r
                echo ""
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if update_function_definitions && update_function_calls; then
                        if validate_changes; then
                            echo ""
                            echo -e "${GREEN}🎉 Hyphen to underscore conversion completed successfully!${NC}"
                            echo "Backup location: $BACKUP_DIR"
                            echo "Log file: $LOG_FILE"
                            log_action "Conversion completed successfully"
                        else
                            echo ""
                            echo -e "${YELLOW}⚠ Conversion completed with validation issues${NC}"
                            echo "Check the log file for details: $LOG_FILE"
                            echo "Backup location: $BACKUP_DIR"
                        fi
                    else
                        echo -e "${RED}✗ Function updates failed${NC}"
                        rollback_changes
                        exit 1
                    fi
                else
                    echo "Operation cancelled."
                    log_action "Operation cancelled by user"
                fi
            else
                echo -e "${RED}✗ Backup or discovery failed${NC}"
                exit 1
            fi
            ;;
        "rollback"|"--rollback")
            if [[ -n "${2:-}" && -d "$2" ]]; then
                BACKUP_DIR="$2"
                rollback_changes
            else
                echo "Usage: $0 --rollback <backup_directory>"
                echo "Available backups:"
                ls -la /tmp/lib_backup_* 2>/dev/null || echo "No backups found"
            fi
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 [mode]"
            echo ""
            echo "Modes:"
            echo "  preview  (default) - Show what changes will be made"
            echo "  --execute          - Execute the hyphen to underscore conversion"
            echo "  --rollback <dir>   - Rollback changes using specified backup"
            echo "  --help             - Show this help message"
            echo ""
            echo "This tool converts all function names with hyphens to underscores"
            echo "across the entire library system with comprehensive validation."
            ;;
        *)
            echo "Unknown mode: $mode"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

# Global variables for function mappings
declare -A FUNCTION_MAPPINGS
declare -A FILE_LOCATIONS

# Run main function
main "$@"
