#!/bin/bash

# Sourcing
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"
source "$DIR_SH/.up"
setup_source "$DIR_SH" "$FILE_SH" "$BASE_SH"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"

a_xall() {
	pbs-dav
    	pbs-adr
    	gen-ipa "$PBS_PACKAGES_ALL"
}

b_xall() {
	pbs-rda "$PBS_DATASTORE_CONFIG" "$PBS_DATASTORE_NAME" "$PBS_DATASTORE_PATH"
}

# Handle script execution
if [ $# -eq 0 ]; then
    print_usage
    clean_exit 0       # Exit cleanly with status 0
else
    setup_main "$@"
    clean_exit $?
fi
