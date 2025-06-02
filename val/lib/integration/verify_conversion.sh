#!/bin/bash

echo "🔍 Comprehensive Function Conversion Verification"
echo "=================================================="

# Count functions with hyphens
echo "1. Checking for remaining hyphenated functions:"
HYPHEN_COUNT=0
for file in /home/es/lab/lib/gen/aux /home/es/lab/lib/ops/{gpu,net,pve,srv,sto,sys,usr,pbs,ssh}; do
    if [[ -f "$file" ]]; then
        count=$(grep -c "^[a-z]*-[a-z]" "$file" 2>/dev/null || echo 0)
        if [[ $count -gt 0 ]]; then
            echo "  ⚠ $file: $count hyphenated functions found"
            grep "^[a-z]*-[a-z]" "$file" | head -3
            HYPHEN_COUNT=$((HYPHEN_COUNT + count))
        fi
    fi
done

if [[ $HYPHEN_COUNT -eq 0 ]]; then
    echo "  ✓ No hyphenated functions found!"
else
    echo "  ⚠ Total hyphenated functions remaining: $HYPHEN_COUNT"
fi

# Count functions with underscores
echo ""
echo "2. Checking for underscore functions:"
UNDERSCORE_COUNT=0
for file in /home/es/lab/lib/gen/aux /home/es/lab/lib/ops/{gpu,net,pve,srv,sto,sys,usr,pbs,ssh}; do
    if [[ -f "$file" ]]; then
        count=$(grep -c "^[a-z]*_[a-z]" "$file" 2>/dev/null || echo 0)
        if [[ $count -gt 0 ]]; then
            echo "  ✓ $file: $count underscore functions"
            UNDERSCORE_COUNT=$((UNDERSCORE_COUNT + count))
        fi
    fi
done

echo "  Total underscore functions: $UNDERSCORE_COUNT"

# Test library loading
echo ""
echo "3. Testing library loading:"
cd /home/es/lab
if source lib/ops/loader >/dev/null 2>&1; then
    echo "  ✓ Library loads successfully"
else
    echo "  ⚠ Library loading failed"
fi

echo ""
echo "📊 Summary:"
echo "  Hyphenated functions remaining: $HYPHEN_COUNT"
echo "  Underscore functions found: $UNDERSCORE_COUNT"
echo "  Expected total: 111 (11 aux + 100 ops)"

if [[ $HYPHEN_COUNT -eq 0 && $UNDERSCORE_COUNT -eq 111 ]]; then
    echo "  🎉 CONVERSION COMPLETE!"
else
    echo "  🔄 Conversion needs attention"
fi
