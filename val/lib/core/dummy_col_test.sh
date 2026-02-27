#!/bin/bash

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

test_dummy_col_placeholder() {
    run_test "dummy col placeholder test" true
}

main() {
    run_test_suite "DUMMY CORE COLOR TESTS" \
        test_dummy_col_placeholder
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
