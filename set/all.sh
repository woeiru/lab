
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
MENU_OPTIONS[x]="x_xall"

a_xall() {
	all-ipa "$PAK1_ALL" "$PAK2_ALL" "$PAK3_ALL"
    	all-gst "$GIT_USERNAME" "$GIT_USERMAIL"
	all-cap "$DOT_FILE1" "$DOT_SOURCE1"
	exec bash
}

b_xall() {
	all-usk \
    		"$DEVICE_PATH" \
    		"$MOUNT_POINT" \
    		"$SUBFOLDER_PATH" \
    		"$UPLOAD_PATH" \
    		"$PRIVATE_KEY"
}

x_xall() {
  local hostname=$(hostname)
  local script_path="/root/lab/set/${hostname}.sh a"
  
  if [[ -f "$script_path" ]]; then
    bash "$script_path" a
  else
    echo "Script $script_path does not exist."
  fi
}

setup_main "$@"
