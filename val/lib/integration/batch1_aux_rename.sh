#!/bin/bash
#######################################################################
# Manual Hyphen to Underscore Batch Rename - First Batch
#######################################################################
# This is the FIRST BATCH focused on the aux library functions
# We'll start with a small, manageable batch to test the process
#######################################################################

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

echo -e "${BLUE}🚀 Batch 1: Converting aux- functions (hyphens → underscores)${NC}"
echo "================================================================"

# Create backup first
BACKUP_DIR="/tmp/batch1_backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}📦 Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r /home/es/lab/lib /home/es/lab/src /home/es/lab/cfg "$BACKUP_DIR/"
echo -e "${GREEN}✓ Backup created: $BACKUP_DIR${NC}"

# Define the first batch - aux functions only
declare -A BATCH1_FUNCTIONS=(
    ["aux_fun"]="aux_fun"
    ["aux_var"]="aux_var" 
    ["aux_log"]="aux_log"
    ["aux_ffl"]="aux_ffl"
    ["aux_laf"]="aux_laf"
    ["aux_acu"]="aux_acu"
    ["aux_mev"]="aux_mev"
    ["aux_nos"]="aux_nos"
    ["aux_flc"]="aux_flc"
    ["aux_use"]="aux_use"
    ["aux_lad"]="aux_lad"
)

echo -e "${YELLOW}📋 Batch 1 Functions to rename:${NC}"
for old_name in "${!BATCH1_FUNCTIONS[@]}"; do
    echo "  $old_name → ${BATCH1_FUNCTIONS[$old_name]}"
done
echo ""

read -p "Proceed with Batch 1 rename? [y/N]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo -e "${BLUE}🔄 Starting Batch 1 rename...${NC}"

# Step 1: Update function definitions in lib/gen/aux
echo "Step 1: Updating function definitions in lib/gen/aux..."
for old_name in "${!BATCH1_FUNCTIONS[@]}"; do
    new_name="${BATCH1_FUNCTIONS[$old_name]}"
    echo "  Renaming: $old_name → $new_name"
    
    # Update the function definition
    sed -i "s/^${old_name}()/${new_name}()/g" /home/es/lab/lib/gen/aux
    
    # Update any comments that reference the function
    sed -i "s/# ${old_name}/# ${new_name}/g" /home/es/lab/lib/gen/aux
done

# Step 2: Update function calls throughout the codebase
echo ""
echo "Step 2: Updating function calls throughout codebase..."
for old_name in "${!BATCH1_FUNCTIONS[@]}"; do
    new_name="${BATCH1_FUNCTIONS[$old_name]}"
    echo "  Updating calls: $old_name → $new_name"
    
    # Update calls in all relevant files
    find /home/es/lab -type f \( -name "*.sh" -o -name "*" ! -name ".*" \) -exec grep -l "$old_name" {} \; 2>/dev/null | while read -r file; do
        if [[ -f "$file" && -w "$file" ]]; then
            # Use word boundaries to avoid partial replacements
            sed -i "s/\b${old_name}\b/${new_name}/g" "$file"
            echo "    Updated: $(basename "$file")"
        fi
    done
done

# Step 3: Validation
echo ""
echo -e "${BLUE}🔍 Validating Batch 1 changes...${NC}"

# Check that old function names are gone from lib/gen/aux
echo "Checking for remaining hyphenated aux- functions..."
remaining=$(grep -c '^aux-[a-zA-Z0-9]*()' /home/es/lab/lib/gen/aux 2>/dev/null || echo "0")
if [[ "$remaining" -eq 0 ]]; then
    echo -e "${GREEN}✓ No hyphenated aux- functions found${NC}"
else
    echo -e "${RED}⚠ Warning: $remaining hyphenated aux- functions still exist${NC}"
fi

# Check that new function names exist
echo "Checking for new underscored aux_ functions..."
new_count=$(grep -c '^aux_[a-zA-Z0-9]*()' /home/es/lab/lib/gen/aux 2>/dev/null || echo "0")
echo -e "${GREEN}✓ Found $new_count underscored aux_ functions${NC}"

# Test library loading
echo "Testing library loading..."
if (cd /home/es/lab && source src/aux/set >/dev/null 2>&1); then
    echo -e "${GREEN}✓ Library loading test passed${NC}"
else
    echo -e "${YELLOW}⚠ Library loading test had issues (may be normal after rename)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Batch 1 completed!${NC}"
echo "Backup location: $BACKUP_DIR"
echo ""
echo "Next step: Review the changes and then run batch 2 for the next set of functions."
echo ""
echo "To rollback if needed:"
echo "  cp -r $BACKUP_DIR/lib /home/es/lab/"
echo "  cp -r $BACKUP_DIR/src /home/es/lab/"
echo "  cp -r $BACKUP_DIR/cfg /home/es/lab/"
