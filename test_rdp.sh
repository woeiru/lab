#!/bin/bash
target_file="lib/core/tme"
lab_dir="/home/es/lab"

exported_funcs=()
while IFS= read -r line; do
    if [[ $line =~ ^([a-zA-Z][a-zA-Z0-9_-]*)\(\) ]]; then
        func_name="${BASH_REMATCH[1]}"
        if [[ "$func_name" != _* && "$func_name" != ana_* ]]; then
            exported_funcs+=("$func_name")
        fi
    fi
done < "$target_file"

declare -A file_calls

for func in "${exported_funcs[@]}"; do
    while IFS=: read -r file_path match_count; do
        if [[ -n "$file_path" && "$match_count" -gt 0 ]]; then
            # Ignore self references
            if [[ "$lab_dir/$file_path" == $(realpath "$target_file") ]]; then
                continue
            fi
            
            key="${file_path}::${func}"
            file_calls["$key"]=$match_count
        fi
    done < <(grep -rcE "\b${func}\b" "$lab_dir/lib/ops/" "$lab_dir/src/set/" "$lab_dir/bin/" 2>/dev/null | grep -v ":0$")
done

for key in "${!file_calls[@]}"; do
    echo "$key: ${file_calls[$key]}"
done
