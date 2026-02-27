#!/bin/bash

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

readonly TEST_LAB_DIR="$LAB_ROOT"
readonly COL_LIB="$TEST_LAB_DIR/lib/core/col"

test_col_library_exists() {
    test_file_exists "$COL_LIB" "Color core library exists"
}

test_col_library_sourceable() {
    test_source "$COL_LIB" "Color core library can be sourced"
}

main() {
    run_test_suite "CORE COLOR LIBRARY TESTS" \
        test_col_library_exists \
        test_col_library_sourceable
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
