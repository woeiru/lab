# Define directory and file variables
DIR_LIB="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_LIB=$(basename "$BASH_SOURCE")
BASE_LIB="${FILE_LIB%.*}"
FILEPATH_LIB="${DIR_LIB}/${FILE_LIB}"
CONFIG_LIB="$DIR_LIB/../var/${BASE_LIB}.conf"

# Dynamically create variables based on the base name
eval "FILEPATH_${BASE_LIB}=\$FILEPATH_LIB"
eval "FILE_${BASE_LIB}=\$FILE_LIB"
eval "BASE_${BASE_LIB}=\$BASE_LIB"
eval "CONFIG_${BASE_LIB}=\$CONFIG_LIB"

# Source the configuration file
if [ -f "$CONFIG_LIB" ]; then
    source "$CONFIG_LIB"
else
    echo "Warning: Configuration file $CONFIG_LIB not found!"
    # Don't exit, just continue
fi

# Shows a summary of selected functions in the script, displaying their usage, shortname, and description
# overview functions
#
all-fun() {
    # Pass all arguments directly to all-laf
    all-laf "$FILEPATH_all" "$@"
}

# Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
#
all-var() {
    all-acu -o "$CONFIG_all" "$DIR_LIB/.."
}

# Logging function
all-log() {
    local log_level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$log_level] $message"
}

# Recursively processes files in a directory and its subdirectories using a specified function, allowing for additional arguments to be passed
# function folder loop
# <function> <flag> <path> [extra_args ..]
all-ffl() {
    local fnc
    local flag
    local folder
    local extra_args=()
    fnc="$1"
    flag="$2"
    folder="$3"
    shift 3
    # Collect remaining arguments as extra_args
    while [[ $# -gt 0 ]]; do
        extra_args+=("$1")
        shift
    done
    if [[ -d "$folder" ]]; then
        for file in "$folder"/{*,.[!.]*,..?*}; do
            if [[ -f "$file" ]]; then
                line_count=$(wc -l < "$file")
                # Get the actual filename without the path
                filename=$(basename "$file")
                # Get the real path of the file
                real_path=$(realpath "$file")
                echo -e "Processing file: \e[32m$real_path\e[0m - Total of \e[31m$line_count\e[0m Lines"
                "$fnc" "$flag" "$file" "${extra_args[@]}"
            elif [[ -d "$file" && "$file" != "$folder"/. && "$file" != "$folder"/.. ]]; then
                all-ffl "$fnc" "$flag" "$file" "${extra_args[@]}"
            fi
        done
    else
        echo "Invalid folder: $folder"
        return 1
    fi
}

# Lists all functions in a file, displaying their usage, shortname, and description. Supports truncation and line break options for better readability
# list all functions
# <file name> [-t] [-b]
all-laf() {
    local truncate_mode=false
    local break_mode=false
    local file_name

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t)
                truncate_mode=true
                shift
                ;;
            -b)
                break_mode=true
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
    local col_width_2=16
    local col_width_3=18
    local col_width_4=36
    local col_width_5=4
    local col_width_6=4
    local col_width_7=4
    local col_width_8=4
    local col_width_9=4

    # Function to truncate and pad strings
    truncate_and_pad() {
        local str="$1"
        local width="$2"
        if [ ${#str} -gt $width ]; then
            echo "${str:0:$((width-2))}.."
        else
            printf "%-${width}s" "$str"
        fi
    }

    # Function to wrap text
    wrap_text() {
        local text="$1"
        local width="$2"
        echo "$text" | fold -s -w "$width"
    }

    # Function to print a row (including header and data rows)
    print_row() {
        if $break_mode; then
            local col1=$(wrap_text "$1" $col_width_1)
            local col2=$(wrap_text "$2" $col_width_2)
            local col3=$(wrap_text "$3" $col_width_3)
            local col4=$(wrap_text "$4" $col_width_4)
            local col5=$(wrap_text "$5" $col_width_5)
            local col6=$(wrap_text "$6" $col_width_6)
            local col7=$(wrap_text "$7" $col_width_7)
            local col8=$(wrap_text "$8" $col_width_8)
            local col9=$(wrap_text "$9" $col_width_9)
            
            local IFS=$'\n'
            local lines1=($col1)
            local lines2=($col2)
            local lines3=($col3)
            local lines4=($col4)
            local lines5=($col5)
            local lines6=($col6)
            local lines7=($col7)
            local lines8=($col8)
            local lines9=($col9)
            
            local max_lines=$(( ${#lines1[@]} > ${#lines2[@]} ? ${#lines1[@]} : ${#lines2[@]} ))
            max_lines=$(( max_lines > ${#lines3[@]} ? max_lines : ${#lines3[@]} ))
            max_lines=$(( max_lines > ${#lines4[@]} ? max_lines : ${#lines4[@]} ))
            max_lines=$(( max_lines > ${#lines5[@]} ? max_lines : ${#lines5[@]} ))
            max_lines=$(( max_lines > ${#lines6[@]} ? max_lines : ${#lines6[@]} ))
            max_lines=$(( max_lines > ${#lines7[@]} ? max_lines : ${#lines7[@]} ))
            max_lines=$(( max_lines > ${#lines8[@]} ? max_lines : ${#lines8[@]} ))
            max_lines=$(( max_lines > ${#lines9[@]} ? max_lines : ${#lines9[@]} ))
            
            for i in $(seq 0 $((max_lines-1))); do
                printf "| %-${col_width_1}s | %-${col_width_2}s | %-${col_width_3}s | %-${col_width_4}s | %-${col_width_5}s | %-${col_width_6}s | %-${col_width_7}s | %-${col_width_8}s | %-${col_width_9}s |\n" \
                    "${lines1[$i]:-}" \
                    "${lines2[$i]:-}" \
                    "${lines3[$i]:-}" \
                    "${lines4[$i]:-}" \
                    "${lines5[$i]:-}" \
                    "${lines6[$i]:-}" \
                    "${lines7[$i]:-}" \
                    "${lines8[$i]:-}" \
                    "${lines9[$i]:-}"
            done
        elif $truncate_mode; then
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
        else
            printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
                "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
        fi
    }

    # Function to print a separator line
    print_separator() {
        local total_width=$((col_width_1 + col_width_2 + col_width_3 + col_width_4 + col_width_5 + col_width_6 + col_width_7 + col_width_8 + col_width_9 + 26))
        printf "+%s+\n" "$(printf '%*s' $total_width '' | tr ' ' '-')"
    }

    print_separator_2() {
        local total_width=$((col_width_1 + col_width_2 + col_width_3 + col_width_4 + col_width_5 + col_width_6 + col_width_7 + col_width_8 + col_width_9 + 26))
        printf "+%s+\n" "$(printf '%*s' $total_width '' | tr ' ' ' ')"
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
    print_row "Func" "Arguments" "Shortname" "Description" "Size" "Loc" "file" "libr" "sets"
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
            func_end_line=$(tail -n +$((func_start_line+1)) "$file_name" | grep -n '^}' | head -1 | cut -d: -f1)
            func_size=$((func_end_line + 1))  # +1 to include the closing brace
            
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
            if $break_mode; then
                print_separator_2
            fi
        fi
    done < "$file_name"

    if ! $break_mode; then
        print_separator
    fi
    echo ""
}

# Analyzes the usage of variables from a config file across a target folder, displaying variable names, values, and occurrence counts in various files
# analyze config usage
# <sort mode: o|a > <target folder> <config file>
all-acu() {
    local sort_mode=$1
    local conf_file=$2
    local target_folder=$3

    # Customizable column widths
    local tab_width_var_names=20
    local tab_width_var_values=18
    local tab_width_var_occurences=5

    if [ $# -ne 3 ]; then
        echo "Usage: all-acu <sort mode: -o|-a> <target folder> <config file>"
        return 1
    fi

    if [[ ! -f $conf_file ]]; then
        echo "Config file $conf_file does not exist."
        return 1
    fi

    if [[ ! -d $target_folder ]]; then
        echo "Target folder $target_folder does not exist."
        return 1
    fi

    declare -A config_vars
    declare -a var_order

    # Function to read config file and store variables and their values
    read_config_file() {
        local conf_file=$1
        while IFS='=' read -r var value; do
            config_vars[$var]=$value
            var_order+=("$var")
        done < <(grep -E -v '^(#|declare|[[:space:]]*\))' "$conf_file" | grep '=' | sed 's/[[:space:]]//g')
    }

    # Function to sort variables based on the sort mode
    sort_variables() {
        local sort_mode=$1
        if [[ $sort_mode == "-a" ]]; then
            IFS=$'\n' sorted_vars=($(sort <<<"${var_order[*]}"))
            unset IFS
        else
            sorted_vars=("${var_order[@]}")
        fi
    }


    list_target_files() {
        local target_folder=$1
        target_files=($(find "$target_folder" \( -name .git -o -name arc -o -name bar -o -name con -o -name dot -o -name fix -o -name var \) -prune -o -type f -name '*.*' -print | sort))
    }


    # Function to truncate strings that exceed the column width
    truncate_string() {
        local str=$1
        local max_length=$2
        if [ ${#str} -gt $max_length ]; then
            echo "${str:0:max_length-2}.."
        else
            echo "$str"
        fi
    }

    # Function to print header with borders
    print_header() {
       echo ""
       printf "| %-*s | %-*s |" "$tab_width_var_names" "Variable" "$tab_width_var_values" "Value"

       for sh_file in "${target_files[@]}"; do
           local truncated_filename=$(basename "$sh_file" | cut -c 1-$tab_width_var_occurences)
           printf " %-*s |" "$tab_width_var_occurences" "$truncated_filename"
        done
        echo

        # Print separator
        printf "| %s | %s | " "$(printf -- '-%.0s' $(seq $tab_width_var_names))" "$(printf -- '-%.0s' $(seq $tab_width_var_values))"
        for _ in "${target_files[@]}"; do
        printf "%s | " "$(printf -- '-%.0s' $(seq $tab_width_var_occurences))"
        done
        echo
}

    # Function to print variable usage across target files
    print_variables_usage() {
        for var in "${sorted_vars[@]}"; do
            local truncated_var=$(truncate_string "$var" "$tab_width_var_names")
            local truncated_value=$(truncate_string "${config_vars[$var]}" "$tab_width_var_values")
            printf "| %-*s | %-*s |" "$tab_width_var_names" "$truncated_var" "$tab_width_var_values" "$truncated_value"
            
            if [[ $var == *"["* ]]; then
                # Skip counting for array elements
                for sh_file in "${target_files[@]}"; do
                    printf " %-*s |" "$tab_width_var_occurences" ""
                done
            else
                for sh_file in "${target_files[@]}"; do
                    local count=$(grep -o "\b$var\b" "$sh_file" | wc -l)
                    if [[ $count -ne 0 ]]; then
                        printf " %-*s |" "$tab_width_var_occurences" "$count"
                    else
                        printf " %-*s |" "$tab_width_var_occurences" ""
                    fi
                done
            fi
            echo
        done

        echo ""
    }

    read_config_file "$conf_file"
    sort_variables "$sort_mode"
    list_target_files "$target_folder"
    print_header
    print_variables_usage
}

# Prompts the user to input or confirm a variable's value, allowing for easy customization of script parameters
# main eval variable
# <var_name> <prompt_message> <current_value>
all-mev() {
    local var_name=$1
    local prompt_message=$2
    local current_value=$3

    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

    read -p "$prompt_message [$current_value]: " input
    if [ -n "$input" ]; then
        eval "$var_name=\"$input\""
    else
        eval "$var_name=\"$current_value\""
    fi
}

# Logs a function's execution status with a timestamp, providing a simple way to track script progress and debugging information
# main display notification
# <function_name> <status>
all-nos() {
    local function_name="$1"
    local status="$2"


    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Displays the source code of a specified function from the library folder, including its description, shortname, and usage
# function library cat
# <function_name>
all-flc() {
    # Check if a function name is provided
    if [ -z "$1" ]; then
        all-use
        return 1
    fi

    # Extract the library prefix from the function name
    func_name="$1"
    lib_prefix="${func_name%%-*}"
    lib_file="/root/lab/lib/${lib_prefix}.bash"

    # Check if the library file exists
    if [ ! -f "$lib_file" ]; then
        echo "Library file $lib_file not found!"
        return 1
    fi

    # Search for the function definition in the library file
    start_line=$(grep -n "^[[:space:]]*${func_name}[[:space:]]*()" "$lib_file" | cut -d: -f1)
    start_line=$((start_line - 3))

    if [ -z "$start_line" ]; then
        echo "Function $func_name not found in $lib_file"
        return 1
    fi

    # Extract the function source code
    awk "NR >= $start_line { print; if (/^\}$/) exit }" "$lib_file"
}

# Displays the usage information, shortname, and description of the calling function, helping users understand how to use it
# function usage information
#
all-use() {
    local caller_line=$(caller 0)
    local caller_function=$(echo $caller_line | awk '{print $2}')
    local script_file="${BASH_SOURCE[1]}"

    # Use grep to locate the function's declaration line number
    local function_start_line=$(grep -n -m 1 "^[[:space:]]*${caller_function}()" "$script_file" | cut -d: -f1)

    if [ -z "$function_start_line" ]; then
        echo "Function not found."
        return
    fi

    # Calculate the line number of the comment
    local description_line=$((function_start_line - 3))
    local shortname_line=$((function_start_line - 2))
    local usage_line=$((function_start_line - 1))

    # Use sed to get the comment line and strip off leading "# "
    local description=$(sed -n "${description_line}s/^# //p" "$script_file")
    local shortname=$(sed -n "${shortname_line}s/^# //p" "$script_file")
    local usage=$(sed -n "${usage_line}s/^# //p" "$script_file")
    local funcname=${caller_function}

    # Display the comment
    echo "Description:    $description"
    echo "Shortname:      $shortname"
    echo "Usage:          $funcname" "$usage"

}
