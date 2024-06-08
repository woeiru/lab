#!/bin/bash

findpath="$1"
depth="$2"

# Function to manage aliases
manage_aliases() {
	read -p "Do you want to manage aliases for editing files with VIM or executing files with BASH (v/b): " manage_type
    case $manage_type in
        "b")
            manage_aliases_with_command "bash"
            ;;
        "v")
            manage_aliases_with_command "vim"
            ;;
        *)
            echo "Invalid choice. Please try again."
            manage_aliases
            ;;
    esac
}

# Function to manage aliases with specified command
manage_aliases_with_command() {
    local command="$1"  # Command to be used (bash or vim)
    echo "Select the .bashrc file to edit:"
    select bashrc_file in "$HOME/.bashrc" "/etc/bash.bashrc"; do
        case $bashrc_file in
            "$HOME/.bashrc")
                echo "User's .bashrc file selected"
                ;;
            "/etc/bash.bashrc")
                echo "System-wide .bashrc file selected"
                ;;
            *)
                echo "Invalid selection"
                return
                ;;
        esac
        while true; do
            echo "Choose an action:"
            select action in "Add alias" "Delete alias" "Exit"; do
                case $action in
                    "Add alias")
                        add_alias "$command" "$bashrc_file" 
                        ;;
                    "Delete alias")
                        delete_alias "$bashrc_file"
                        ;;
                    "Exit")
                        return
                        ;;
                    *)
                        echo "Invalid selection"
                        ;;
                esac
                break
            done
        done
    done
}

# Function to add alias
add_alias() {
    local command="$1"
    local bashrc_file="$2"
    echo "Select the file to alias:"
    IFS=$'\n'  # Set the Internal Field Separator to newline
    script_list=($(find $findpath -maxdepth $depth -type d -name '.git' -prune -o -type f -print))
    for ((i=0; i<${#script_list[@]}; i++)); do
        echo "$((i+1))) ${script_list[$i]}"
    done
    read -p "Enter the number corresponding to the file you want to alias (or 0 to cancel): " selection
    echo "Enter the alias name:"
    read -p "Alias name: " alias_name
    if [[ $selection =~ ^[0-9]+$ && $selection -ge 0 && $selection -le ${#script_list[@]} ]]; then
        selected_file="${script_list[$((selection-1))]}"
        if [[ -n $selected_file ]]; then
            absolute_path=$(realpath "$selected_file")
            echo "alias $alias_name='$command \"$absolute_path\"'" >> "$bashrc_file"
            echo "Alias '$alias_name' added to '$bashrc_file'"
        else
            echo "Invalid selection."
        fi
    else
        echo "Invalid input. Please enter a valid number."
    fi
}

# Function to delete alias
delete_alias() {
    local bashrc_file="$1"
    echo "Select the alias to delete:"
    IFS=$'\n'  # Set the Internal Field Separator to newline
    alias_list=($(grep -oP "(?<=alias ).*(?==)" "$bashrc_file"))
    for ((i=0; i<${#alias_list[@]}; i++)); do
        echo "$((i+1))) ${alias_list[$i]}"
    done
    read -p "Enter the number corresponding to the alias you want to delete (or 0 to cancel): " selection
    if [[ $selection =~ ^[0-9]+$ && $selection -ge 0 && $selection -le ${#alias_list[@]} ]]; then
        selected_alias="${alias_list[$((selection-1))]}"
        if [[ -n $selected_alias ]]; then
            sed -i "/alias $selected_alias=/d" "$bashrc_file"
            echo "Alias '$selected_alias' deleted from '$bashrc_file'"
        else
            echo "Invalid selection."
        fi
    else
        echo "Invalid input. Please enter a valid number."
    fi
}

# Main function
main() {
    # Call the function to manage aliases
    manage_aliases
}

# Execute main function
main

exec bash
