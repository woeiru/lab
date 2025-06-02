#!/bin/bash

# Test script to debug aux_use function

# First check if aux module loads correctly
echo "=== Loading aux module ==="
if source /home/es/lab/lib/gen/aux; then
    echo "aux module loaded successfully"
else
    echo "Failed to load aux module"
    exit 1
fi

# Check if aux_use function is available
if declare -f aux_use >/dev/null; then
    echo "aux_use function is available"
else
    echo "aux_use function is NOT available"
    exit 1
fi

# Test function with proper comments (3 lines before function definition)
# example test function for debugging
# test shortname  
# no parameters
test_function() {
    echo "=== Testing aux_use function ==="
    echo "Current script: ${BASH_SOURCE[0]}"
    echo "Function name from caller: $(caller 0 | awk '{print $2}')"
    echo "Script file from BASH_SOURCE[1]: ${BASH_SOURCE[1]}"
    echo ""
    
    echo "=== Calling aux_use ==="
    aux_use
}

# Another test function to see if aux_use works with different function
# second test function for comparison
# test2 shortname
# param1 param2
another_test() {
    echo "=== Testing from another_test ==="
    echo "Caller info: $(caller 0)"
    aux_use
}

echo "Running test_function..."
test_function

echo ""
echo "Running another_test..."  
another_test

echo ""
echo "=== Manual debugging of aux_use internals ==="
# Manually test the aux_use logic
test_manual_aux_use() {
    # Manual debug of aux_use logic
    # manual test function
    # <no params>
    
    echo "Manual debugging..."
    local caller_line=$(caller 0)
    echo "caller_line: '$caller_line'"
    
    local caller_function=$(echo "$caller_line" | awk '{print $2}')
    echo "caller_function: '$caller_function'"
    
    local script_file="${BASH_SOURCE[1]}"
    echo "script_file: '$script_file'"
    
    if [[ -n "$script_file" && -f "$script_file" ]]; then
        echo "Script file exists and is readable"
        local function_start_line=$(grep -n -m 1 "^[[:space:]]*${caller_function}()" "$script_file" | cut -d: -f1)
        echo "function_start_line: '$function_start_line'"
        
        if [[ -n "$function_start_line" ]]; then
            local description_line=$((function_start_line - 3))
            local shortname_line=$((function_start_line - 2))
            local usage_line=$((function_start_line - 1))
            
            echo "Extracting comments from lines: $description_line, $shortname_line, $usage_line"
            
            local description=$(sed -n "${description_line}s/^# //p" "$script_file")
            local shortname=$(sed -n "${shortname_line}s/^# //p" "$script_file")
            local usage=$(sed -n "${usage_line}s/^# //p" "$script_file")
            
            echo "description: '$description'"
            echo "shortname: '$shortname'"
            echo "usage: '$usage'"
        else
            echo "Could not find function start line"
        fi
    else
        echo "Script file does not exist or is not readable"
    fi
}

test_manual_aux_use
