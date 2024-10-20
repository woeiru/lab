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

# Shows a summary of specific functions in the script, displaying their usage, shortname, and description
# overview functions
#
gen-fun() {
    # Pass all arguments directly to all-laf
    all-laf "$FILEPATH_gen" "$@"
}

# Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
#
gen-var() {
    all-acu -o "$CONFIG_gen" "$DIR_LIB/.."
}

# Manages git operations, ensuring the local repository syncs with the remote.
# Performs status check, pull, commit, and push operations as needed.
# gen-gio [commit message]
gen-gio() {
    local dir="${DIR_LIB:-.}/.."
    local branch="${GIT_BRANCH:-master}"
    local commit_message=""

    # If arguments are provided, use them as the commit message
    if [ $# -gt 0 ]; then
        commit_message="$*"
    fi

    # Navigate to the git folder
    cd "$dir" || { echo "Failed to change directory to $dir"; return 1; }

    # Fetch updates from remote
    git fetch origin "$branch" || { echo "Failed to fetch from remote"; return 1; }

    # Get the current status
    local status_output
    status_output=$(git status --porcelain)
    if [[ -z "$status_output" ]]; then
        echo "Working tree clean. Checking for updates..."
        if git rev-list HEAD...origin/"$branch" --count | grep -q "^0$"; then
            echo "Local branch is up to date with origin/$branch."
        else
            echo "Updates available. Pulling changes..."
            git pull origin "$branch" || { echo "Failed to pull changes"; return 1; }
        fi
    else
        echo "Changes detected. Committing and pushing..."
        git add . || { echo "Failed to stage changes"; return 1; }
        if [[ -n "$commit_message" ]]; then
            git commit -m "$commit_message" || { echo "Failed to commit changes"; return 1; }
        else
            git commit --allow-empty-message -m "" || { echo "Failed to commit changes"; return 1; }
        fi
        git push origin "$branch" || { echo "Failed to push changes"; return 1; }
    fi

    # Return to the previous directory
    cd - > /dev/null || { echo "Failed to return to previous directory"; return 1; }
}

# Installs specified packages using the system's package manager (apt, dnf, yum, or zypper). Performs update, upgrade, and installation operations
# install packages
# <pak1> <pak2> ...
gen-ipa() {
    local function_name="${FUNCNAME[0]}"

    echo "Debug: gen-ipa function called with arguments: $@"

    if [ $# -lt 1 ]; then
        all-use
        return 1
    fi

    # Function to detect the package manager
    detect_package_manager() {
        if command -v apt &> /dev/null; then
            echo "apt"
        elif command -v dnf &> /dev/null; then
            echo "dnf"
        elif command -v yum &> /dev/null; then
            echo "yum"
        elif command -v zypper &> /dev/null; then
            echo "zypper"
        else
            echo "unknown"
        fi
    }

    # Detect the package manager
    local pman=$(detect_package_manager)
    echo "Debug: Detected package manager: $pman"

    if [ "$pman" = "unknown" ]; then
        all-nos "$function_name" "Could not detect a supported package manager"
        return 1
    fi

    # Define commands based on package manager
    case "$pman" in
        apt)
            local update_cmd="update"
            local upgrade_cmd="upgrade -y"
            local install_cmd="install -y"
            ;;
        dnf|yum)
            local update_cmd="check-update"
            local upgrade_cmd="upgrade -y"
            local install_cmd="install -y"
            ;;
        zypper)
            local update_cmd="refresh"
            local upgrade_cmd="update -y"
            local install_cmd="install -y"
            ;;
        *)
            all-nos "$function_name" "Unsupported package manager: $pman"
            return 1
            ;;
    esac

    echo "Debug: Update command: $pman $update_cmd"
    echo "Debug: Upgrade command: $pman $upgrade_cmd"
    echo "Debug: Install command: $pman $install_cmd"

    # Execute update command
    echo "Debug: Executing: $pman $update_cmd"
    $pman $update_cmd > /tmp/update_output.log 2>&1
    update_exit_code=$?

    if [ $update_exit_code -eq 0 ]; then
        echo "No updates available."
    elif [ $update_exit_code -eq 100 ]; then
        echo "Updates are available."
    else
        echo "Debug: $pman $update_cmd exited with code $update_exit_code"
        echo "Full command output:"
        cat /tmp/update_output.log
        all-nos "$function_name" "Failed to check for updates. Exit code: $update_exit_code"
        return 1
    fi

    echo "Debug: Update check completed successfully"

    # Execute upgrade command
    echo "Debug: Executing: $pman $upgrade_cmd"
    if ! $pman $upgrade_cmd > /tmp/upgrade_output.log 2>&1; then
        local exit_code=$?
        echo "Debug: $pman $upgrade_cmd exited with code $exit_code"
        echo "Full command output:"
        cat /tmp/upgrade_output.log
        all-nos "$function_name" "Failed to upgrade packages. Exit code: $exit_code"
        return 1
    fi

    echo "Debug: Upgrade command completed successfully"

    # Install all provided packages
    echo "Debug: Executing: $pman $install_cmd $*"
    if ! $pman $install_cmd $* > /tmp/install_output.log 2>&1; then
        local exit_code=$?
        echo "Debug: $pman $install_cmd $* exited with code $exit_code"
        echo "Full command output:"
        cat /tmp/install_output.log
        all-nos "$function_name" "Failed to install packages ( $* ). Exit code: $exit_code"
        return 1
    fi

    echo "Debug: Install command completed successfully"

    all-nos "$function_name" "Successfully executed ( $pman $install_cmd $* )"
}

# Configures git globally with a specified username and email, essential for proper commit attribution
# git set config
# <username> <usermail>
gen-gst() {
    local function_name="${FUNCNAME[0]}"
    local username="$1"
    local usermail="$2"

    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi

    git config --global user.name "$username"
    git config --global user.email "$usermail"

    all-nos "$function_name" "executed ( $1 $2 )"
}

# Installs, enables, and starts the sysstat service for system performance monitoring. Modifies the configuration to ensure it's enabled
# setup sysstat
#
gen-sst() {
  # Step 1: Install sysstat
  install_pakages sysstat

  # Step 2: Enable sysstat
  sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat

  # Step 3: Start the sysstat service
  systemctl enable sysstat
  systemctl start sysstat

  echo "sysstat has been installed, enabled, and started."
}

# Creates a new user with a specified username and password, prompting for input if not provided. Verifies successful user creation
# user setup
# <username> <password>
gen-ust() {
    local function_name="${FUNCNAME[0]}"
    local username="$1"
    local password="$2"

    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi

    # Prompt for user details
    all-mev "username" "Enter new username" "$username"
    while [ -z "$password" ]; do
        all-mev "password" "Enter password for $username" "$password"
    done

    # Create the user
    useradd -m "$username"
    echo "$username:$password" | chpasswd

    # Check if user creation was successful
    if id -u "$username" > /dev/null 2>&1; then
        all-nos "$function_name" "User $username created successfully"
    else
        all-nos "$function_name" "Failed to create user $username"
        return 1
    fi
}

# Enables and starts a specified systemd service. Checks if the service is active and prompts for continuation if it's not
# systemd setup service
# <service>
gen-sdc() {
    local function_name="${FUNCNAME[0]}"
    local service="$1"

    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi

    # Enable and start smbd service
    systemctl enable "$service"
    systemctl start "$service"

    # Check if service is active
    systemctl is-active --quiet "$service"
    if [ $? -eq 0 ]; then
        all-nos "$function_name" "$service is active"
    else
        read -p "$service is not active. Do you want to continue anyway? [Y/n] " choice
        case "$choice" in
            [yY]|[yY][eE][sS])
                all-nos "$function_name" "$service is not active"
                ;;
            *)
                all-nos "$function_name" "$service is not active. Exiting."
                return 1
                ;;
        esac
    fi
}

# Uploads an SSH key from a plugged-in device to a specified folder (default: /root/.ssh). Handles mounting, file copying, and unmounting of the device
# ssh upload keyfile
# <device_path> <mount_point> <subfolder_path> <upload_path> <file_name>
gen-suk() {
    local device_path="$1"
    local mount_point="$2"
    local subfolder_path="$3"
    local upload_path="$4"
    local file_name="$5"

    if [ $# -ne 5 ]; then
	all-use
        return 1
    fi

    local full_path
    local upload_full_path

    echo ""
    lsblk
    echo ""
    echo "ls /mnt output :"
    ls /mnt
    echo ""

    # Evaluate and confirm variables
    all-mev "device_path" "Enter the device path" $device_path
    all-mev "mount_point" "Enter the mount point" $mount_point
    all-mev "subfolder_path" "Enter the subfolder(s) on the device" $subfolder_path
    all-mev "file_name" "Enter the file name" $file_name
    all-mev "upload_path" "Enter the upload path" $upload_path

    full_path="$mount_point/$subfolder_path/$file_name"
    upload_full_path="$upload_path/$file_name"

    # Check if mount point exists
    if [ ! -d "$mount_point" ]; then
        echo "Mount Point $mount_point will be created."
	mkdir -p $mount_point
    fi

    # Mount the device
    mount $device_path $mount_point

    # Check if mount was successful
    if [ $? -ne 0 ]; then
        echo "Failed to mount $device_path at $mount_point"
        return 1
    fi

    # Copy the SSH key to the upload path
    cp $full_path $upload_full_path

    # Check if copy was successful
    if [ $? -ne 0 ]; then
        echo "Failed to copy $full_path to $upload_path"
        umount $mount_point
        return 1
    fi

    # Unmount the device
    umount $mount_point

    echo "SSH key successfully uploaded to $upload_path"
}

# Appends a private SSH key identifier to the SSH config file for a specified user. Creates the .ssh directory and config file if they don't exist
# ssh private identifier
# <user> <keyname>
gen-spi() {
    local keyname=$2
    local user=$2
    local ssh_dir
    local config_file
    local user_home

    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi


    if [ "$user" == "root" ]; then
        ssh_dir="/root/.ssh"
        user_home="/root"
    else
        ssh_dir="/home/$user/.ssh"
        user_home="/home/$user"
    fi

    config_file="$ssh_dir/config"

    # Create the .ssh directory if it doesn't exist
    mkdir -p $ssh_dir

    # Define the configuration line to add
    identity_file_line="    IdentityFile $user_home/.ssh/$keyname"

    # Check if the IdentityFile line already exists
    if ! grep -qx "$identity_file_line" "$config_file" 2>/dev/null; then
        # Append the configuration to the config file
        echo -e "\nHost *\n$identity_file_line" >> $config_file

        # Set the correct permissions
        chown $user:$user $config_file
        chmod 600 $config_file

        echo "SSH config file updated at $config_file"
    else
        echo "Configuration already exists in $config_file"
    fi
}

# Generates an SSH key pair and handles the transfer process
# ssh key swap
# client-side generation: gen-sks -c [-d] <server_address> <key_name> [encryption_type] / server-side generation: gen-sks -s [-d] <client_address> <key_name> [encryption_type]
gen-sks() {
    local mode=""
    local deduplicate=false
    local remote_address=""
    local key_name=""
    local encryption_type="ed25519"  # Default to ed25519
    local ssh_dir="/root/.ssh"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|-s) mode="$1" ;;
            -d) deduplicate=true ;;
            *)
                if [[ -z "$remote_address" ]]; then
                    remote_address="$1"
                elif [[ -z "$key_name" ]]; then
                    key_name="$1"
                else
                    encryption_type="$1"
                fi
                ;;
        esac
        shift
    done

    # Check if required arguments are provided
    if [[ -z "$mode" || -z "$remote_address" || -z "$key_name" ]]; then
        echo "Usage: gen-sks -s [-d] <client_address> <key_name> [encryption_type] # for server-side generation"
        echo "       gen-sks -c [-d] <server_address> <key_name> [encryption_type] # for client-side generation"
        echo "       -d: Optional. If provided, removes the original key after successful transfer."
        echo "If encryption_type is not specified, ed25519 will be used by default."
        return 1
    fi

    # Function to generate SSH key
    generate_key() {
        local key_path="$1"
        case "$encryption_type" in
            rsa)
                ssh-keygen -t rsa -b 4096 -f "$key_path" -N ""
                ;;
            dsa)
                ssh-keygen -t dsa -f "$key_path" -N ""
                ;;
            ecdsa)
                ssh-keygen -t ecdsa -b 521 -f "$key_path" -N ""
                ;;
            ed25519|*)
                ssh-keygen -t ed25519 -f "$key_path" -N ""
                ;;
        esac
    }

    case "$mode" in
        -s) # Server-side generation
            mkdir -p "$ssh_dir"
            chmod 700 "$ssh_dir"
            generate_key "$ssh_dir/$key_name"
            if [ $? -ne 0 ]; then
                echo "Failed to generate SSH key pair."
                return 1
            fi
            echo "SSH key pair generated on server using $encryption_type encryption."
            echo "Transferring private key to client..."
            scp "$ssh_dir/$key_name" "${remote_address}:~/.ssh/"
            if [ $? -ne 0 ]; then
                echo "Failed to transfer private key to client."
                return 1
            fi
            echo "Private key transferred to client successfully."
            if $deduplicate; then
                rm "$ssh_dir/$key_name"
                echo "Private key removed from server (deduplication)."
            fi
            echo "Public key file: $ssh_dir/${key_name}.pub"
            ;;
        -c) # Client-side generation
            generate_key "$HOME/.ssh/$key_name"
            if [ $? -ne 0 ]; then
                echo "Failed to generate SSH key pair."
                return 1
            fi
            echo "SSH key pair generated on client using $encryption_type encryption."
            echo "Transferring public key to server..."
            scp "$HOME/.ssh/${key_name}.pub" "${remote_address}:/tmp/"
            if [ $? -ne 0 ]; then
                echo "Failed to transfer public key to server."
                return 1
            fi
            ssh "$remote_address" "mkdir -p $ssh_dir && mv /tmp/${key_name}.pub $ssh_dir/"
            if [ $? -ne 0 ]; then
                echo "Failed to move public key on server."
                return 1
            fi
            echo "Public key transferred to server and saved in $ssh_dir/${key_name}.pub"
            echo "Private key file on client: $HOME/.ssh/$key_name"

            if $deduplicate; then
                rm "$HOME/.ssh/${key_name}.pub"
                echo "Public key removed from client's .ssh folder (deduplication)."
            fi
            ;;
        *)
            echo "Invalid mode. Use -s for server-side or -c for client-side generation."
            return 1
            ;;
    esac
    echo "SSH key generation and transfer completed successfully."
}

# Appends the content of a specified public SSH key file to the authorized_keys file.
# Provides informational output and restarts the SSH service.
# Usage: gen-sak -c <server_address> <key_name> *for client-side operation /// gen-sak -s <client_address> <key_name> *for server-side operation
gen-sak() {
    local mode="$1"
    local remote_address="$2"
    local key_name="$3"
    local ssh_dir="/root/.ssh"
    local authorized_keys_path="$ssh_dir/authorized_keys"
    if [ $# -ne 3 ]; then
        echo "Usage: gen-sak -c <server_address> <key_name> # for client-side operation"
        echo "       gen-sak -s <client_address> <key_name> # for server-side operation"
        return 1
    fi
    case "$mode" in
        -c) # Client-side operation
            local public_key_path="$HOME/.ssh/${key_name}.pub"
            # Check if the public key exists
            if [ ! -f "$public_key_path" ]; then
                echo "Error: Public key '$public_key_path' does not exist."
                return 1
            fi
            # Transfer and append the public key on the server
            ssh "$remote_address" "mkdir -p $ssh_dir && cat >> $authorized_keys_path" < "$public_key_path"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to append public key to authorized_keys on the server."
                return 1
            fi
            echo "Public key appended to authorized_keys on the server."
            ;;
        -s) # Server-side operation
            local public_key_path="$ssh_dir/${key_name}.pub"
            # Check if the public key exists
            if [ ! -f "$public_key_path" ]; then
                echo "Error: Public key '$public_key_path' does not exist on the server."
                return 1
            fi
            # Append the public key to authorized_keys
            cat "$public_key_path" >> "$authorized_keys_path"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to append public key to authorized_keys."
                return 1
            fi
            echo "Public key appended to authorized_keys on the server."
            ;;
        *)
            echo "Invalid mode. Use -c for client-side or -s for server-side operation."
            return 1
            ;;
    esac
    # Ensure correct permissions
    chmod 600 "$authorized_keys_path"
    # Restart SSH service
    echo "Restarting SSH service..."
    if systemctl restart sshd; then
        echo "SSH service restarted successfully."
    else
        echo "Error: Failed to restart SSH service. Please check the service manually."
        return 1
    fi
    echo "SSH key append operation completed successfully."
}

# Loops a specified SSH operation (bypass StrictHostKeyChecking or refresh known_hosts) through a range of IPs defined in the configuration
# loop operation ip
# <ip array: hy,ct> <operation: bypass = Perform initial SSH login to bypass StrictHostKeyChecking / refresh = Remove the SSH key for the given IP from known_hosts>
gen-loi() {
    local ip_type=$1
    local operation=$2
    local ip_array_name="${ip_type^^}_IPS"

    # Ensure both parameters are provided
    if [ -z "$ip_type" ] || [ -z "$operation" ]; then
	  all-use
	  return 1
    fi

    # Ensure the array exists
    if ! declare -p "$ip_array_name" >/dev/null 2>&1; then
        echo "Invalid IP type: $ip_type"
        return 1
    fi

    # Get the associative array
    declare -n IP_ARRAY="$ip_array_name"

    for KEY in "${!IP_ARRAY[@]}"; do
        IP=${IP_ARRAY[$KEY]}

        if [ -n "$IP" ]; then
            if [ "$operation" == "bypass" ]; then
                echo "Performing SSH login to bypass StrictHostKeyChecking for $IP"
                ssh -o StrictHostKeyChecking=no root@"$IP" "exit"
                if [ $? -ne 0 ]; then
                    echo "Failed to SSH into $IP"
                fi
            elif [ "$operation" == "refresh" ]; then
                echo "Removing SSH key for $IP from known_hosts"
                ssh-keygen -R "$IP"
                if [ $? -ne 0 ]; then
                    echo "Failed to remove SSH key for $IP"
                fi
            else
                echo "Invalid operation: $operation"
                return 1
            fi
        else
            echo "IP is empty for key $KEY"
        fi
    done
}

# Resolves custom SSH aliases using the configuration file. Supports connecting to single or multiple servers, executing commands remotely
# ssh custom aliases
# <usershortcut> <servershortcut: single or csv or all or array> [command]
gen-sca() {
    echo "Debug: Number of arguments: $#"
    echo "Debug: All arguments: $*"

    if [ $# -lt 2 ]; then
        all-use
        return 1
    fi

    local user_shortcut=$1
    local server_shortcuts=$2
    shift 2
    local command="$*"

    echo "Debug: User shortcut: $user_shortcut"

    # Resolve user name from shortcut
    local user_name="${SSH_USERS[$user_shortcut]}"
    echo "Debug: Resolved user name: $user_name"

    if [[ -z $user_name ]]; then
        echo "Error: Unknown user shortcut '$user_shortcut'"
	echo "Debug: SSH_USERS array contents: ${SSH_USERS[@]}"
  	echo "Debug: SSH_USERS keys: ${!SSH_USERS[@]}"
        return 1
    fi

    echo "Debug: Server shortcuts (raw): $server_shortcuts"
    echo "Debug: ALL_IP_ARRAYS: ${ALL_IP_ARRAYS[*]}"

    # Function to handle an array of servers
    handle_server_array() {
        local array_name=$1
        declare -n server_array=$array_name
        echo "Debug: Processing array: $array_name"
        echo "Debug: Array contents: ${!server_array[*]}"
        for server_shortcut in "${!server_array[@]}"; do
            local server_ip=${server_array[$server_shortcut]}
            echo "Debug: Resolved server IP for $server_shortcut: $server_ip"
            # Construct the SSH command
            local ssh_command="ssh ${user_name}@${server_ip}"
            if [[ -n $command ]]; then
                ssh_command+=" \"$command\""
            fi
            # Execute the SSH command
            echo "Executing: $ssh_command"
            eval $ssh_command
        done
    }

    # Function to normalize server shortcuts
    normalize_shortcut() {
        local input=$1
        local normalized=$input

        # Check if input matches any array name or alias (case-insensitive)
        for array in "${!ARRAY_ALIASES[@]}"; do
            local aliases=(${ARRAY_ALIASES[$array]})
            for alias in "${aliases[@]}"; do
                if [[ ${input,,} == ${alias,,} ]]; then
                    normalized=$array
                    echo "Debug: Match found, normalized '$input' to '$normalized'" >&2
                    break 2
                fi
            done
        done

        echo "Debug: Normalized '$input' to '$normalized'" >&2
        echo "$normalized"
    }

    # Function to find server IP
    find_server_ip() {
        local shortcut=$1
        local ip=""
        local array_name=""
        for array in "${ALL_IP_ARRAYS[@]}"; do
            echo "Debug: Searching for '$shortcut' in '$array'" >&2
            declare -n current_array=$array
            echo "Debug: $array contents: ${!current_array[*]}" >&2
            if [[ -n ${current_array[$shortcut]} ]]; then
                ip=${current_array[$shortcut]}
                array_name=$array
                echo "Debug: Found '$shortcut' in '$array'" >&2
                break
            fi
        done
        echo "Debug: Found IP for $shortcut: $ip (from $array_name)" >&2
        echo "$ip"
    }

    # Function to check if input is an array name
    is_array_name() {
        local input=$1
        echo "Debug: Checking if '$input' is an array name" >&2
        if [[ $input == "all" ]]; then
            echo "Debug: '$input' is 'all'" >&2
            return 0
        fi
        for array in "${ALL_IP_ARRAYS[@]}"; do
            if [[ $input == $array ]]; then
                echo "Debug: '$input' matches array '$array'" >&2
                return 0
            fi
        done
        echo "Debug: '$input' is not an array name" >&2
        return 1
    }

    # Normalize the server shortcuts
    local normalized_shortcuts=$(normalize_shortcut "$server_shortcuts")
    echo "Debug: Normalized server shortcuts: $normalized_shortcuts"

    # Handle server_shortcuts
    if is_array_name "$normalized_shortcuts"; then
        echo "Debug: Processing as array name"
        if [[ $normalized_shortcuts == "all" ]]; then
            echo "Debug: Processing all servers"
            for array in "${ALL_IP_ARRAYS[@]}"; do
                handle_server_array $array
            done
        else
            echo "Debug: Processing specific IP array: $normalized_shortcuts"
            handle_server_array $normalized_shortcuts
        fi
    else
        echo "Debug: Processing as individual server(s)"
        IFS=',' read -ra servers <<< "$normalized_shortcuts"
        if [[ ${#servers[@]} -gt 1 && -z $command ]]; then
            echo "Error: No command provided for multiple servers"
            return 1
        fi
        for server_shortcut in "${servers[@]}"; do
            local server_ip=$(find_server_ip "$server_shortcut")
            if [[ -z $server_ip ]]; then
                echo "Error: Unknown server shortcut '$server_shortcut'"
                return 1
            fi
            local ssh_command="ssh ${user_name}@${server_ip}"
            if [[ -n $command ]]; then
                ssh_command+=" \"$command\""
            fi
            echo "Executing: $ssh_command"
            eval $ssh_command
        done
    fi
    echo "Debug: Raw command: $command"
}

# An interactive Bash function that guides users through Git history navigation, offering options for reset type and subsequent actions, with built-in safeguards and explanations.
# GRE: Git Reset Explorer
# Usage: gen-gre  # Then follow prompts, e.g., enter '2' for commits, '3' for hard reset, '2' to create new branch 'feat
gen-gre() {
    echo "Welcome to the Git Reset Explorer (gen-gre)!"
    echo "This function will guide you through the process of moving back in Git history."
    echo

    # Step 1: Determine how many commits to go back
    read -p "How many commits do you want to go back? " num_commits

    # Step 2: Determine the reset type
    echo
    echo "What type of reset do you want to perform?"
    echo "1. Soft (move HEAD but leave staging and working directory unchanged)"
    echo "2. Mixed (move HEAD and reset staging, but leave working directory unchanged)"
    echo "3. Hard (move HEAD, reset staging, and reset working directory)"
    read -p "Enter your choice (1/2/3): " reset_type

    # Construct the reset command
    case $reset_type in
        1) reset_cmd="git reset --soft HEAD~$num_commits" ;;
        2) reset_cmd="git reset HEAD~$num_commits" ;;
        3) reset_cmd="git reset --hard HEAD~$num_commits" ;;
        *) echo "Invalid choice. Exiting."; return 1 ;;
    esac

    # Execute the reset command
    echo
    echo "Executing: $reset_cmd"
    eval $reset_cmd

    # Step 3: Handle the new state
    echo
    echo "Reset complete. What would you like to do with this new state?"
    echo "1. Keep this state (do nothing further)"
    echo "2. Create a new branch at this point"
    echo "3. Force push this state to the remote (caution: rewrites history)"
    echo "4. Create a new commit with this state"
    read -p "Enter your choice (1/2/3/4): " state_choice

    case $state_choice in
        1)
            echo "Keeping the current state. No further action needed."
            ;;
        2)
            read -p "Enter the name for the new branch: " branch_name
            git checkout -b $branch_name
            echo "Created and switched to new branch: $branch_name"
            ;;
        3)
            read -p "Enter the name of the remote branch to force push to: " remote_branch
            git push -f origin HEAD:$remote_branch
            echo "Force pushed to $remote_branch. Remote history has been rewritten."
            ;;
        4)
            read -p "Enter a commit message: " commit_message
            git commit -m "$commit_message"
            echo "Created a new commit with the message: $commit_message"
            ;;
        *)
            echo "Invalid choice. No further action taken."
            ;;
    esac

    echo
    echo "Gen-gre process complete. Your repository is now in the following state:"
    git status
    echo
    echo "Current commit:"
    git log -1 --oneline
}
