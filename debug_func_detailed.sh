#!/bin/bash

# Debug version of the func script logic
LAB_DIR="/home/es/lab"
LIB_CORE_DIR="$LAB_DIR/lib/core"

lib_name="core"
lib_dir="$LIB_CORE_DIR"

echo "=== DEBUG: Processing library: $lib_name ==="
echo "Library directory: $lib_dir"

# Use centralized .tmp/doc directory
tmp_dir="$LAB_DIR/.tmp/doc"
mkdir -p "$tmp_dir"

# Process each file in the library directory
for file in "$lib_dir"/*; do
    if [[ -f "$file" ]]; then
        echo ""
        echo "Processing file: $file"
        
        # Generate JSON output using ana_laf with -j flag
        echo "Running: ana_laf -j \"$file\""
        source "$LAB_DIR/lib/gen/ana"
        ana_laf -j "$file" >/dev/null 2>&1
        
        # Generate JSON filename based on file path structure
        relative_path="${file#$LAB_DIR/}"
        json_filename="${relative_path//\//_}.json"
        json_file="$tmp_dir/$json_filename"
        
        echo "Expected JSON file: $json_file"
        echo "JSON file exists: $(test -f "$json_file" && echo "YES" || echo "NO")"
        
        if [[ -f "$json_file" ]]; then
            module_name=$(basename "$file")
            echo "Module name: $module_name"
            
            # Parse JSON and extract function information
            # Using a simple approach since we control the JSON format
            in_functions=false
            in_function=false
            func_name=""
            func_desc=""
            functions_found=0
            
            while IFS= read -r line; do
                # Remove leading/trailing whitespace
                line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                if [[ "$line" == '"functions": [' ]]; then
                    in_functions=true
                    echo "  Found functions array start"
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
                    elif [[ "$line" =~ \"description\":[[:space:]]*\"([^\"]*)\" ]]; then
                        func_desc="${BASH_REMATCH[1]}"
                    elif [[ "$line" == "}" ]]; then
                        # End of function object - output the row
                        if [[ -n "$func_name" ]]; then
                            echo "  FUNCTION ROW: | $lib_name | $module_name | $func_name | $func_desc |"
                            functions_found=$((functions_found + 1))
                        fi
                        in_function=false
                    fi
                fi
                
                if [[ "$line" == "]" && "$in_functions" == true ]]; then
                    in_functions=false
                    break
                fi
            done < "$json_file"
            
            echo "  Functions found in $module_name: $functions_found"
        else
            echo "  ERROR: JSON file not found!"
        fi
    fi
done
