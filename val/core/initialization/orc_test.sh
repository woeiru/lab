#!/bin/bash
#######################################################################
# Core Module Tests - Component Orchestrator
#######################################################################
# File: val/core/initialization/orc_test.sh
# Description: Focused tests for the component orchestrator (bin/orc)
#              behavior used during bootstrap.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="$LAB_ROOT"
readonly ORC_SCRIPT="$TEST_LAB_DIR/bin/orc"

test_orc_script_exists() {
    test_file_exists "$ORC_SCRIPT" "Component orchestrator script exists"
}

test_source_directory_skips_hidden_files() {
    local test_env
    test_env=$(create_test_env "orc_hidden_files")

    cat > "$test_env/test_orc_hidden_files.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

temp_module_dir=$(mktemp -d)
trap 'rm -rf "$temp_module_dir"' EXIT

printf 'ORC_VISIBLE_WAS_SOURCED=1\n' > "$temp_module_dir/visible_module"
printf 'ORC_HIDDEN_WAS_SOURCED=1\n' > "$temp_module_dir/.hidden_spec"

unset ORC_VISIBLE_WAS_SOURCED ORC_HIDDEN_WAS_SOURCED

if ! source_directory "$temp_module_dir" "*" "orc test modules" >/dev/null 2>&1; then
    exit 1
fi

[[ "${ORC_VISIBLE_WAS_SOURCED:-}" == "1" ]] || exit 1
[[ -z "${ORC_HIDDEN_WAS_SOURCED:-}" ]] || exit 1
EOF
    chmod +x "$test_env/test_orc_hidden_files.sh"

    run_test "Orchestrator loader skips hidden files" "$test_env/test_orc_hidden_files.sh"
    cleanup_test_env "$test_env"
}

main() {
    run_test_suite "COMPONENT ORCHESTRATOR TESTS" \
        test_orc_script_exists \
        test_source_directory_skips_hidden_files
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
