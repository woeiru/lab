#!/bin/bash

# Simple test to trace the JSON parsing
echo "Testing JSON parsing..."

json_file="/home/es/lab/.tmp/doc/lib_ops_sys.json"
lib_name="ops"
module_name="sys"

echo "Processing $json_file..."

# Parse JSON and extract function information
in_functions=false
in_function=false
func_name=""
func_desc=""

while IFS= read -r line; do
    # Remove leading/trailing whitespace
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ "$line" == '"functions": [' ]]; then
        echo "Found functions array"
        in_functions=true
        continue
    fi
    
    if [[ "$in_functions" == true && "$line" == "{" ]]; then
        echo "Starting new function object"
        in_function=true
        func_name=""
        func_desc=""
        continue
    fi
    
    if [[ "$in_function" == true ]]; then
        if [[ "$line" =~ \"name\":[[:space:]]*\"([^\"]+)\" ]]; then
            func_name="${BASH_REMATCH[1]}"
            echo "Extracted function name: '$func_name'"
        elif [[ "$line" =~ \"description\":[[:space:]]*\"([^\"]*)\" ]]; then
            func_desc="${BASH_REMATCH[1]}"
            echo "Extracted description: '$func_desc'"
        elif [[ "$line" == "}" ]]; then
            # End of function object - output the row
            if [[ -n "$func_name" ]]; then
                echo "==> OUTPUT: | $lib_name | $module_name | $func_name | $func_desc |"
            fi
            in_function=false
        fi
    fi
    
    if [[ "$line" == "]" && "$in_functions" == true ]]; then
        echo "End of functions array"
        in_functions=false
        break
    fi
done < "$json_file"
