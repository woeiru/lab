#!/bin/bash

# Set up variables
dir=/etc/corosync/qnetd
db="$dir/nssdb"

# Exit immediately if a command exits with a non-zero status
set -e

# Set file creation mask (umask)
umask ${UMASK:-022}

# Check if Corosync database directory exists and create it if not
if [ ! -d "$db" ]; then
        echo "Creating corosync database dir: $db"
        mkdir -p "$db"
fi

# Check if certificate database file exists
if [ ! -f "$db/cert9.db" ]; then
        # If an older certificate database file exists, upgrade it
        if [ -f "$db/cert8.db" ]; then
                echo "Upgrading corosync certificate database"
                # If the password file is empty, add a newline so it's accepted
                if [ -f "$db/pwdfile.txt" -a ! -s "$db/pwdfile.txt" ]; then
                        echo > "$db/pwdfile.txt"
                fi

                # Upgrade to SQLite database
                certutil -N -d "sql:$db" -f "$db/pwdfile.txt" -@ "$db/pwdfile.txt"
                # Make cert9.db and key4.db permissions the same as cert8.db's perms
                chmod --reference="$db/cert8.db" "$db/cert9.db" "$db/key4.db"
        else
                echo "Creating corosync certificates"
                corosync-qnetd-certutil -i -G
        fi
fi

# Start Corosync-qnetd with specified options
if [ -n "$COROSYNC_QNETD_OPTIONS$*" ]; then
        echo "Starting corosync-qnetd with args: $COROSYNC_QNETD_OPTIONS $*"
else
        echo "Starting corosync-qnetd"
fi

# Start Corosync-qnetd and handle errors
error=0
exec /usr/bin/corosync-qnetd -f $COROSYNC_QNETD_OPTIONS "$@" || error=$?

# Output error message if Corosync-qnetd fails to start
echo "Failed to start corosync-qnetd: $error" >&2
exit $error
