#!/bin/bash
#######################################################################
# AGENTS.md Verification Test
#######################################################################
# File: val/core/agents_md_test.sh
# Description: Validates that claims made in AGENTS.md match the actual
#              repository state. Catches drift when files are renamed,
#              moved, deleted, or conventions change.
#
# Run: ./val/core/agents_md_test.sh
#######################################################################

# Test configuration
TEST_NAME="AGENTS.md Verification"
TEST_CATEGORY="core"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../val/helpers/test_framework.sh"

# =====================================================================
# Section 1: Entrypoints and Scripts
# =====================================================================

test_entrypoints() {
    echo
    echo -e "${CYAN}--- Entrypoints ---${NC}"

    test_file_exists "${LAB_ROOT}/go" "Entrypoint ./go exists"
    run_test "Entrypoint ./go is executable" test -x "${LAB_ROOT}/go"
    test_file_exists "${LAB_ROOT}/bin/ini" "Entrypoint bin/ini exists"
    test_dir_exists "${LAB_ROOT}/val" "Entrypoint directory val/ exists"
}

test_go_subcommands() {
    echo
    echo -e "${CYAN}--- ./go subcommands ---${NC}"

    local go_file="${LAB_ROOT}/go"
    local subcommands=("init" "setup" "on" "off" "status" "validate" "test")

    for cmd in "${subcommands[@]}"; do
        ((FRAMEWORK_TESTS_RUN++))
        test_log "Checking: ./go supports '$cmd' subcommand"
        if grep -qE "(^[[:space:]]*${cmd}[|)]|[|]${cmd}[|)]|[|]${cmd}[)])" "$go_file" 2>/dev/null; then
            test_success "./go handles '$cmd' subcommand"
        else
            test_failure "./go does NOT handle '$cmd' subcommand"
        fi
    done
}

# =====================================================================
# Section 2: Lint and Test Scripts
# =====================================================================

test_lint_scripts() {
    echo
    echo -e "${CYAN}--- Lint scripts ---${NC}"

    test_file_exists "${LAB_ROOT}/val/core/config/cfg_test.sh" \
        "Lint: cfg_test.sh exists"
    test_file_exists "${LAB_ROOT}/val/lib/ops/std_compliance_test.sh" \
        "Lint: std_compliance_test.sh exists"
}

test_runner_exists() {
    echo
    echo -e "${CYAN}--- Test runners ---${NC}"

    test_file_exists "${LAB_ROOT}/val/run_all_tests.sh" \
        "Main test runner exists"
    run_test "Main test runner is executable" \
        test -x "${LAB_ROOT}/val/run_all_tests.sh"

    test_file_exists "${LAB_ROOT}/val/lib/run_all_tests.sh" \
        "Library suite runner exists"
    run_test "Library suite runner is executable" \
        test -x "${LAB_ROOT}/val/lib/run_all_tests.sh"
}

test_runner_categories() {
    echo
    echo -e "${CYAN}--- Test runner categories ---${NC}"

    local runner="${LAB_ROOT}/val/run_all_tests.sh"
    local categories=("core" "lib" "integration" "src" "dic" "legacy")

    for cat in "${categories[@]}"; do
        ((FRAMEWORK_TESTS_RUN++))
        test_log "Checking: run_all_tests.sh supports category '$cat'"
        if grep -q "\"$cat\"" "$runner" 2>/dev/null; then
            test_success "Category '$cat' defined in runner"
        else
            test_failure "Category '$cat' NOT found in runner"
        fi
    done
}

test_runner_options() {
    echo
    echo -e "${CYAN}--- Test runner options ---${NC}"

    local runner="${LAB_ROOT}/val/run_all_tests.sh"
    local options=("--list" "--quick" "--verbose" "--help")

    for opt in "${options[@]}"; do
        ((FRAMEWORK_TESTS_RUN++))
        test_log "Checking: run_all_tests.sh supports '$opt'"
        if grep -q -- "$opt" "$runner" 2>/dev/null; then
            test_success "Option '$opt' found in runner"
        else
            test_failure "Option '$opt' NOT found in runner"
        fi
    done
}

test_lib_runner_options() {
    echo
    echo -e "${CYAN}--- Library runner options ---${NC}"

    local runner="${LAB_ROOT}/val/lib/run_all_tests.sh"
    local options=("--core" "--ops" "--gen" "--integration" "--help")

    for opt in "${options[@]}"; do
        ((FRAMEWORK_TESTS_RUN++))
        test_log "Checking: lib/run_all_tests.sh supports '$opt'"
        if grep -q -- "$opt" "$runner" 2>/dev/null; then
            test_success "Lib runner option '$opt' found"
        else
            test_failure "Lib runner option '$opt' NOT found"
        fi
    done
}

test_example_test_scripts() {
    echo
    echo -e "${CYAN}--- Example test scripts ---${NC}"

    test_file_exists "${LAB_ROOT}/val/core/config/cfg_test.sh" \
        "Example test: cfg_test.sh exists"
    test_file_exists "${LAB_ROOT}/val/lib/ops/sys_test.sh" \
        "Example test: sys_test.sh exists"
    test_file_exists "${LAB_ROOT}/val/src/dic/dic_integration_test.sh" \
        "Example test: dic_integration_test.sh exists"
}

# =====================================================================
# Section 3: Directory Structure
# =====================================================================

test_directory_structure() {
    echo
    echo -e "${CYAN}--- Directory structure ---${NC}"

    local dirs=(
        "lib/core"
        "lib/ops"
        "lib/gen"
        "src/dic"
        "val"
        "doc"
    )

    for dir in "${dirs[@]}"; do
        test_dir_exists "${LAB_ROOT}/${dir}" "Directory ${dir}/ exists"
    done
}

# =====================================================================
# Section 4: Convention and Reference Files
# =====================================================================

test_convention_files() {
    echo
    echo -e "${CYAN}--- Convention files ---${NC}"

    test_file_exists "${LAB_ROOT}/lib/ops/.spec" \
        "Ops spec file exists"
    test_file_exists "${LAB_ROOT}/lib/ops/.guide" \
        "Ops guide file exists"
    test_file_exists "${LAB_ROOT}/lib/ops/README.md" \
        "Ops README exists"
    test_file_exists "${LAB_ROOT}/bin/orc" \
        "Orchestrator bin/orc exists"
    test_file_exists "${LAB_ROOT}/val/helpers/test_framework.sh" \
        "Test framework exists"
    test_file_exists "${LAB_ROOT}/lib/gen/aux" \
        "Logging helper lib/gen/aux exists"
    test_file_exists "${LAB_ROOT}/lib/gen/sec" \
        "Security utility lib/gen/sec exists"
}

# =====================================================================
# Section 5: Naming Convention Spot-Checks
# =====================================================================

test_naming_conventions() {
    echo
    echo -e "${CYAN}--- Naming conventions ---${NC}"

    # Check that ops modules have module-prefixed functions
    local ops_dir="${LAB_ROOT}/lib/ops"
    local modules=("gpu" "pve" "sys" "ssh" "net")
    local conventions_ok=true

    for mod in "${modules[@]}"; do
        local mod_file="${ops_dir}/${mod}"
        ((FRAMEWORK_TESTS_RUN++))
        test_log "Checking: ${mod} uses ${mod}_ function prefix"
        if [[ -f "$mod_file" ]] && grep -qE "^${mod}_[a-z_]+\(\)" "$mod_file" 2>/dev/null; then
            test_success "Module ${mod} uses ${mod}_ prefix"
        elif [[ ! -f "$mod_file" ]]; then
            test_failure "Module file ${mod} not found"
            conventions_ok=false
        else
            test_failure "Module ${mod} missing ${mod}_ prefixed functions"
            conventions_ok=false
        fi
    done

    # Check snake_case (no CamelCase function names)
    ((FRAMEWORK_TESTS_RUN++))
    test_log "Checking: no CamelCase function names in lib/ops"
    local camel_count
    camel_count=$(grep -rE '^[A-Z][a-zA-Z]+\(\)' "${ops_dir}/" 2>/dev/null | wc -l)
    if [[ "$camel_count" -eq 0 ]]; then
        test_success "No CamelCase functions in lib/ops (snake_case enforced)"
    else
        test_failure "Found ${camel_count} CamelCase function names in lib/ops"
    fi
}

# =====================================================================
# Section 6: AGENTS.md Self-Consistency
# =====================================================================

test_agents_md_exists() {
    echo
    echo -e "${CYAN}--- AGENTS.md file ---${NC}"

    test_file_exists "${LAB_ROOT}/AGENTS.md" "AGENTS.md exists at repo root"

    # Check it references key sections
    local agents_md="${LAB_ROOT}/AGENTS.md"
    local sections=(
        "Build, Lint, and Test Commands"
        "Code Style and Implementation Guidelines"
        "Cursor and Copilot Rules"
    )

    for section in "${sections[@]}"; do
        ((FRAMEWORK_TESTS_RUN++))
        test_log "Checking: AGENTS.md contains section '$section'"
        if grep -qF "$section" "$agents_md" 2>/dev/null; then
            test_success "Section '$section' present"
        else
            test_failure "Section '$section' missing from AGENTS.md"
        fi
    done
}

# =====================================================================
# Main
# =====================================================================

test_header "$TEST_NAME"

run_test_group "Entrypoints" \
    test_entrypoints \
    test_go_subcommands

run_test_group "Lint and Test Infrastructure" \
    test_lint_scripts \
    test_runner_exists \
    test_runner_categories \
    test_runner_options \
    test_lib_runner_options \
    test_example_test_scripts

run_test_group "Directory Structure" \
    test_directory_structure

run_test_group "Convention and Reference Files" \
    test_convention_files

run_test_group "Naming Conventions" \
    test_naming_conventions

run_test_group "AGENTS.md Self-Consistency" \
    test_agents_md_exists

test_footer
