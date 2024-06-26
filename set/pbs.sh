#!/bin/bash

# Sourcing
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"
echo "Variable ( *.sh ) DIR_SH = $DIR_SH"
echo "Variable ( *.sh ) FILE_SH = $FILE_SH"
echo "Variable ( *.sh ) BASE_SH = $BASE_SH"
source "$DIR_SH/.up"
setup_source "$DIR_SH" "$FILE_SH" "$BASE_SH"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"

a_xall() {
	pbs-sgp
    	pbs-adr
    	pbs-puu
    	all-ipa "$PMAN_PBS" "$PAK1_PBS" "$PAK2_PBS"
}

b_xall() {
	pbs-rda "$DATASTORE_CONFIG" "$DATASTORE_NAME" "$DATASTORE_PATH"
}

setup_main "$@"
