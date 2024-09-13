# cats the three lines above each function as usage,shortname,description
# list all functions
# <file name>
all-laf() {
    local full_output=false
    local file_name

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--full)
                full_output=true
                shift
                ;;
            *)
                file_name="$1"
                shift
                ;;
        esac
    done

    if [ -z "$file_name" ]; then
        all-use
        return 1
    fi

    # Column width parameters
    local col_width_1=7
    local col_width_2=20
    local col_width_3=20
    local col_width_4=30
    local col_width_5=4
    local col_width_6=4
    local col_width_7=4
    local col_width_8=4
    local col_width_9=4

    # Function to truncate and pad strings
    truncate_and_pad() {
        local str="$1"
        local width="$2"
        if $full_output; then
            printf "%-${width}s" "$str"
        else
            if [ ${#str} -gt $width ]; then
                echo "${str:0:$((width-2))}.."
            else
                printf "%-${width}s" "$str"
            fi
        fi
    }

    # Function to print a row (including header and data rows)
    print_row() {
        printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
            "$(truncate_and_pad "$1" $col_width_1)" \
            "$(truncate_and_pad "$2" $col_width_2)" \
            "$(truncate_and_pad "$3" $col_width_3)" \
            "$(truncate_and_pad "$4" $col_width_4)" \
            "$(truncate_and_pad "$5" $col_width_5)" \
            "$(truncate_and_pad "$6" $col_width_6)" \
            "$(truncate_and_pad "$7" $col_width_7)" \
            "$(truncate_and_pad "$8" $col_width_8)" \
            "$(truncate_and_pad "$9" $col_width_9)"
    }

    # Function to print a separator line
    print_separator() {
        local total_width=$((col_width_1 + col_width_2 + col_width_3 + col_width_4 + col_width_5 + col_width_6 + col_width_7 + col_width_8 + col_width_9 + 26))
        printf "+%s+\n" "$(printf '%*s' $total_width '' | tr ' ' '-')"
    }

    local line_number=0
    declare -a comments=()

    # Read all comments into an array
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[[:space:]]*# ]]; then
            comments[$line_number]="${line#"${line%%[![:space:]]*}"}"  # Remove leading whitespace
            comments[$line_number]="${comments[$line_number]#\# }"    # Remove leading '# '
            comments[$line_number]="${comments[$line_number]#\#}"     # Remove leading '#' if there's no space after it
        fi
    done < "$file_name"

    # Counts all function calls
    count_calls() {
        local func_name="$1"
        local count=$(awk -v func_name="$func_name" '{ for (i=1; i<=NF; i++) if ($i == func_name) count++ } END { print count }' "$file_name")
        echo "${count}"
    }

    # Counts all function calls in a folder, excluding a specific file
    count_calls_folder() {
        local func_name="$1"
        local folder_name="$2"
        local exclude_file="$3"
        local count=$(find "$folder_name" -type f ! -name "$(basename "$exclude_file")" -exec awk -v func_name="$func_name" '{ for (i=1; i<=NF; i++) if ($i == func_name) count++ } END { print count }' {} + | awk '{sum += $1} END {if (sum == 0) print ""; else print sum}')
        echo "${count}"
    }

    # Function to get comment or empty string
    get_comment() {
        local line_num=$1
        local comment="${comments[$line_num]:-}"
        # Return empty string if comment is just whitespace
        if [[ -z "${comment// }" ]]; then
            echo ""
        else
            echo "$comment"
        fi
    }

    # Print table header
    print_separator
    print_row "Function" "Arguments" "Shortname" "Description" "Size" "Loc" "Cfil" "Clib" "Cset"
    print_separator

    # Loop through all lines in the file again
    line_number=0
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_-]*\(\) ]]; then
            # Extract function name without parentheses
            func_name=$(echo "$line" | awk -F '[(|)]' '{print $1}')
            # Calculate function size
            func_start_line=$line_number
            func_size=0
            while IFS= read -r func_line; do
                ((func_size++))
                if [[ $func_line == *} ]]; then
                    break
                fi
            done < <(tail -n +$func_start_line "$file_name")
            # Count the number of calls to the function
            func_calls=$(count_calls "$func_name")
            callslib=$(count_calls_folder "$func_name" "/root/lab/lib" "$file_name")
            callsset=$(count_calls_folder "$func_name" "/root/lab/set" "$file_name")
            
            # Get comments for arguments, shortname, and description
            description=$(get_comment $((line_number-3)))
            shortname=$(get_comment $((line_number-2)))
            arguments=$(get_comment $((line_number-1)))

            # Print function information
            print_row "$func_name" "$arguments" "$shortname" "$description" "$func_size" "$line_number" "$func_calls" "$callslib" "$callsset"
        fi
    done < "$file_name"

    print_separator
    echo ""
}
