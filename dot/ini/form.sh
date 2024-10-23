#!/bin/bash

# form.sh - Formatting functions for shell scripts

# Default indentation if not set
BASE_INDENT="${BASE_INDENT:-          }"  # 10 spaces default

print_message() {
    local message="$1"
    # Print to both console and log file
    printf "%s┃ %-68s \n" "$BASE_INDENT" "$message" | tee -a "$DEPLOY_LOG_FILE"
}

# Function to print box-style messages
print_box() {
    local message="$1"
    printf "\n"
    printf "%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n" "$BASE_INDENT"
    printf "%s┃ %-68s ┃\n" "$BASE_INDENT" "$message"
    printf "%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n" "$BASE_INDENT"
}

# Function to print section headers
print_section() {
    local message="$1"
    printf "\n"
    printf "%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n" "$BASE_INDENT"
    printf "%s┃ %-68s ┃\n" "$BASE_INDENT" "$message"
    printf "%s┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\n" "$BASE_INDENT"
}

# Function to print normal box line
print_boxline() {
    local message="$1"
    printf "%s┃ %-68s \n" "$BASE_INDENT" "$message"
}

# Function to print box footer
print_boxfooter() {
    printf "%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n" "$BASE_INDENT"
}
