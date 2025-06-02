#!/bin/bash
#######################################################################
# Hyphen to Underscore Function Rename Generator
#######################################################################
# File: val/lib/integration/generate_hyphen_underscore_mappings.sh
# Description: Discovers all functions with hyphens and generates 
#              precise rename mappings for hyphen-to-underscore conversion
#######################################################################

set -euo pipefail

# Configuration
readonly LIB_DIR="/home/es/lab/lib"
readonly OUTPUT_DIR="/tmp/hyphen_underscore_mappings"
readonly BACKUP_DIR="/tmp/lib_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}🔍 Discovering Functions with Hyphens${NC}"
echo "================================================================"

# Function to find all functions with hyphens
discover_hyphen_functions() {
    local mappings_file="$OUTPUT_DIR/hyphen_to_underscore_mappings.txt"
    local summary_file="$OUTPUT_DIR/conversion_summary.txt"
    
    echo "# Hyphen to Underscore Function Mappings" > "$mappings_file"
    echo "# Generated: $(date)" >> "$mappings_file"
    echo "# Format: old_name → new_name | file_path" >> "$mappings_file"
    echo "" >> "$mappings_file"
    
    local total_functions=0
    local hyphen_functions=0
    
    echo -e "${YELLOW}📋 Scanning all library files...${NC}"
    
    # Find all function definitions with hyphens
    while IFS= read -r -d '' file; do
        if [[ -f "$file" && -r "$file" ]]; then
            echo "  Scanning: $(basename "$file")"
            
            # Extract functions with hyphens from this file
            while IFS= read -r line; do
                if [[ "$line" =~ ^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)+)\(\)[[:space:]]*\{ ]]; then
                    local func_name="${BASH_REMATCH[1]}"
                    local new_name="${func_name//-/_}"  # Replace all hyphens with underscores
                    
                    echo "$func_name → $new_name | $file" >> "$mappings_file"
                    echo "    ✓ Found: $func_name → $new_name"
                    
                    ((hyphen_functions++))
                fi
                ((total_functions++))
            done < <(grep -E '^[a-zA-Z0-9_-]+\(\)[[:space:]]*\{' "$file" 2>/dev/null || true)
        fi
    done < <(find "$LIB_DIR" -type f -print0)
    
    # Generate summary
    {
        echo "HYPHEN TO UNDERSCORE CONVERSION SUMMARY"
        echo "======================================"
        echo "Generated: $(date)"
        echo ""
        echo "Total functions discovered: $total_functions"
        echo "Functions with hyphens: $hyphen_functions"
        echo "Functions to convert: $hyphen_functions"
        echo ""
        echo "Conversion rate: $(( hyphen_functions * 100 / total_functions ))% of total functions"
        echo ""
        echo "Files to be modified:"
        find "$LIB_DIR" -type f -exec grep -l '^[a-zA-Z0-9]*-[a-zA-Z0-9_-]*()' {} \; 2>/dev/null || true
    } > "$summary_file"
    
    echo -e "${GREEN}✓ Mapping generation complete!${NC}"
    echo "  - Mappings file: $mappings_file"
    echo "  - Summary file: $summary_file"
    echo "  - Functions with hyphens found: $hyphen_functions"
}

# Function to generate the batch rename script
generate_rename_script() {
    local script_file="$OUTPUT_DIR/execute_hyphen_underscore_rename.sh"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash
#######################################################################
# Execute Hyphen to Underscore Function Rename
#######################################################################

set -euo pipefail

readonly LIB_DIR="/home/es/lab/lib"
readonly BACKUP_DIR="/tmp/lib_backup_$(date +%Y%m%d_%H%M%S)"
readonly MAPPINGS_FILE="/tmp/hyphen_underscore_mappings/hyphen_to_underscore_mappings.txt"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

echo -e "${BLUE}🚀 Executing Hyphen to Underscore Function Rename${NC}"
echo "================================================================"

# Create backup
create_backup() {
    echo -e "${YELLOW}📦 Creating backup...${NC}"
    mkdir -p "$BACKUP_DIR"
    cp -r "$LIB_DIR" "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Backup created: $BACKUP_DIR${NC}"
}

# Perform the rename operations
perform_renames() {
    local renamed_count=0
    
    echo -e "${YELLOW}🔄 Performing function renames...${NC}"
    
    # Read mappings and perform renames
    while IFS='|' read -r mapping file_path; do
        if [[ -n "$mapping" && ! "$mapping" =~ ^# ]]; then
            local old_name=$(echo "$mapping" | awk '{print $1}')
            local new_name=$(echo "$mapping" | awk '{print $3}')
            local file_path=$(echo "$file_path" | xargs)
            
            if [[ -f "$file_path" ]]; then
                echo "  Renaming in $file_path: $old_name → $new_name"
                
                # Replace function definition
                sed -i "s/^${old_name}()/${new_name}()/g" "$file_path"
                
                # Replace function calls throughout the codebase
                find /home/es/lab -type f \( -name "*.sh" -o -name "*" ! -name ".*" \) -exec grep -l "$old_name" {} \; 2>/dev/null | while read -r call_file; do
                    sed -i "s/${old_name}/${new_name}/g" "$call_file"
                done
                
                ((renamed_count++))
            fi
        fi
    done < "$MAPPINGS_FILE"
    
    echo -e "${GREEN}✓ Renamed $renamed_count functions${NC}"
}

# Validate the changes
validate_changes() {
    echo -e "${YELLOW}🔍 Validating changes...${NC}"
    
    # Check for any remaining hyphens in function definitions
    local remaining_hyphens=$(find "$LIB_DIR" -type f -exec grep -c '^[a-zA-Z0-9]*-[a-zA-Z0-9_-]*()' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [[ $remaining_hyphens -eq 0 ]]; then
        echo -e "${GREEN}✓ All function definitions successfully converted${NC}"
    else
        echo -e "${RED}⚠ Warning: $remaining_hyphens function definitions still contain hyphens${NC}"
    fi
    
    # Test that functions can still be sourced
    echo "  Testing library loading..."
    if source /home/es/lab/src/aux/set 2>/dev/null; then
        echo -e "${GREEN}✓ Library loading test passed${NC}"
    else
        echo -e "${RED}✗ Library loading test failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    if [[ ! -f "$MAPPINGS_FILE" ]]; then
        echo -e "${RED}✗ Mappings file not found: $MAPPINGS_FILE${NC}"
        echo "Run generate_hyphen_underscore_mappings.sh first"
        exit 1
    fi
    
    create_backup
    perform_renames
    validate_changes
    
    echo -e "${GREEN}🎉 Hyphen to underscore conversion completed!${NC}"
    echo "Backup location: $BACKUP_DIR"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [--execute]"
    echo "  --execute: Perform the actual rename operations"
    exit 0
fi

case "$1" in
    --execute)
        main
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$script_file"
    echo -e "${GREEN}✓ Rename script generated: $script_file${NC}"
}

# Main execution
main() {
    discover_hyphen_functions
    generate_rename_script
    
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "1. Review the mappings: cat $OUTPUT_DIR/hyphen_to_underscore_mappings.txt"
    echo "2. Review the summary: cat $OUTPUT_DIR/conversion_summary.txt"
    echo "3. Execute the rename: $OUTPUT_DIR/execute_hyphen_underscore_rename.sh --execute"
    echo ""
    echo -e "${YELLOW}⚠️ Always backup your data before proceeding!${NC}"
}

main "$@"
