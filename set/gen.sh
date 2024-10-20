#!/bin/bash

# Enable error handling and logging
set -e
exec 2>>/tmp/gen_error.log
set -x

log_error() {
    echo "ERROR: $1" >&2
}

log_info() {
    echo "INFO: $1"
}

log_info "Starting gen.sh"

# Sourcing
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"

log_info "Sourcing .up file"
source "$DIR_SH/.up" || log_error "Failed to source .up file"

log_info "Calling setup_source"
setup_source "$DIR_SH" "$FILE_SH" "$BASE_SH" || log_error "setup_source failed"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"
MENU_OPTIONS[x]="x_xall"

a_xall() {
    log_info "Executing a_xall"
    gen-ipa "$PACKAGES_ALL" || log_error "gen-ipa failed"
    gen-gst "$GIT_USERNAME" "$GIT_USERMAIL" || log_error "gen-gst failed"
}

b_xall() {
    log_info "Executing b_xall"
    gen-suk \
        "$DEVICE_PATH" \
        "$MOUNT_POINT" \
        "$SUBFOLDER_PATH" \
        "$UPLOAD_PATH" \
        "$PRIVATE_KEY" || log_error "gen-suk failed"
}

log_info "Calling setup_main"
setup_main "$@" || log_error "setup_main failed"

log_info "End of gen.sh reached"
