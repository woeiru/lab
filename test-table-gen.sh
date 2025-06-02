#!/bin/bash

# Set up environment
LAB_DIR="/home/es/lab"
source "$LAB_DIR/lib/gen/aux"

# Define library directories
LIB_CORE_DIR="$LAB_DIR/lib/core"
LIB_OPS_DIR="$LAB_DIR/lib/ops"
LIB_GEN_DIR="$LAB_DIR/lib/gen"

# Test just the sys library functions
echo "Testing process_library_functions for ops/sys..."

# Copy the process_library_functions function from doc-func
process_library_functions() {
    local lib_name="$1"
    local lib_dir="$2"
    
    # Use centralized .tmp/doc directory
    local tmp_dir="$LAB_DIR/.tmp/doc"
    mkdir -p "$tmp_dir"
    
    # Process each file in the library directory
    for file in "$lib_dir"/*; do
        if [[ -f "$file" && "$(basename "$file")" == "sys" ]]; then
            echo "Processing file: $file"
            
            # Generate JSON output using aux_laf with -j flag
            aux_laf -j "$file" >/dev/null 2>&1
            
            # Generate JSON filename based on file path structure
            local relative_path="${file#$LAB_DIR/}"
            local json_filename="${relative_path//\//_}.json"
            local json_file="$tmp_dir/$json_filename"
            
            echo "Looking for JSON file: $json_file"
            
            if [[ -f "$json_file" ]]; then
                echo "JSON file found, processing..."
                local module_name=$(basename "$file")
                
                # Parse JSON and extract function information
                local in_functions=false
                local in_function=false
                local func_name=""
                local func_desc=""
                
                while IFS= read -r line; do
                    # Remove leading/trailing whitespace
                    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    
                    if [[ "$line" == '"functions": [' ]]; then
                        in_functions=true
                        continue
                    fi
                    
                    if [[ "$in_functions" == true && "$line" == "{" ]]; then
                        in_function=true
                        func_name=""
                        func_desc=""
                        continue
                    fi
                    
                    if [[ "$in_function" == true ]]; then
                        if [[ "$line" =~ \"name\":[[:space:]]*\"([^\"]+)\" ]]; then
                            func_name="${BASH_REMATCH[1]}"
                            echo "Found function name: $func_name"
                        elif [[ "$line" =~ \"description\":[[:space:]]*\"([^\"]*)\" ]]; then
                            func_desc="${BASH_REMATCH[1]}"
                        elif [[ "$line" == "}" ]]; then
                            # End of function object - output the row
                            if [[ -n "$func_name" ]]; then
                                echo "OUTPUT: | $lib_name | $module_name | $func_name | $func_desc |"
                            fi
                            in_function=false
                        fi
                    fi
                    
                    if [[ "$line" == "]" && "$in_functions" == true ]]; then
                        in_functions=false
                        break
                    fi
                done < "$json_file"
            else
                echo "JSON file not found!"
            fi
        fi
    done
}

# Test the function
process_library_functions "ops" "$LIB_OPS_DIR"
