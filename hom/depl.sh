#!/bin/bash

# Check if a username is provided
if [ $# -eq 0 ]; then
    echo "Error: No username provided."
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC_FILE="/home/$USERNAME/.bashrc"
CONTENT_FILE="$SCRIPT_DIR/bashrc"
FUNC_FILE="$SCRIPT_DIR/func.sh"

# Injection markers
START_MARKER="#START_INJECTED_LINES"
END_MARKER="#END_INJECTED_LINES"

# Check if the .bashrc file exists
if [ ! -f "$BASHRC_FILE" ]; then
    echo "Error: .bashrc file not found for user $USERNAME."
    exit 1
fi

# Check if the content file exists
if [ ! -f "$CONTENT_FILE" ]; then
    echo "Error: 'bashrc' file not found in the script directory."
    exit 1
fi

# Check if the func.sh file exists
if [ ! -f "$FUNC_FILE" ]; then
    echo "Error: 'func.sh' file not found in the script directory."
    exit 1
fi

# Remove existing injected section if present
sed -i "/$START_MARKER/,/$END_MARKER/d" "$BASHRC_FILE"

# Read the content from the bashrc file
INJECT_CONTENT=$(cat <<EOF

$START_MARKER
$(cat "$CONTENT_FILE")
$END_MARKER
EOF
)

# Inject the new content into the .bashrc file
echo "$INJECT_CONTENT" >> "$BASHRC_FILE"

# Copy func.sh to the user's home directory
cp "$FUNC_FILE" "/home/$USERNAME/"

echo "Content from 'bashrc' successfully injected into $BASHRC_FILE"
echo "func.sh copied to /home/$USERNAME/"
