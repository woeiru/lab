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

test_source_lib_ops_lazy_stub_loads_on_first_call() {
    local test_env
    test_env=$(create_test_env "orc_lazy_ops")

    cat > "$test_env/test_orc_lazy_ops.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_OPS_LAZY_LOAD=1
export LAB_OPS_LAZY_MODULES="ssh"

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

stub_def="$(declare -f ssh_fun 2>/dev/null)"
[[ "$stub_def" == *"_orc_lazy_dispatch"* ]] || exit 1

if ! ssh_fun --help >/dev/null 2>&1; then
    exit 1
fi

real_def="$(declare -f ssh_fun 2>/dev/null)"
[[ "$real_def" == *"_orc_lazy_dispatch"* ]] && exit 1

module_path="$LAB_DIR/lib/ops/ssh"
[[ "${ORC_LAZY_MODULE_LOADED[$module_path]:-0}" == "1" ]] || exit 1
EOF
    chmod +x "$test_env/test_orc_lazy_ops.sh"

    run_test "Orchestrator lazy-loads selected ops module on first use" "$test_env/test_orc_lazy_ops.sh"
    cleanup_test_env "$test_env"
}

test_source_lib_ops_dev_reconcile_stub_is_lazy_loadable() {
    local test_env
    test_env=$(create_test_env "orc_lazy_dev_reconcile")

    cat > "$test_env/test_orc_lazy_dev_reconcile.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_OPS_LAZY_LOAD=1
export LAB_OPS_LAZY_MODULES="dev"

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

stub_def="$(declare -f dev_oac 2>/dev/null)"
[[ "$stub_def" == *"_orc_lazy_dispatch"* ]] || exit 1

if ! dev_oac --help >/dev/null 2>&1; then
    exit 1
fi

real_def="$(declare -f dev_oac 2>/dev/null)"
[[ "$real_def" == *"_orc_lazy_dispatch"* ]] && exit 1

module_path="$LAB_DIR/lib/ops/dev"
[[ "${ORC_LAZY_MODULE_LOADED[$module_path]:-0}" == "1" ]] || exit 1
EOF
    chmod +x "$test_env/test_orc_lazy_dev_reconcile.sh"

    run_test "Orchestrator lazy-loads dev_oac reconcile trigger" "$test_env/test_orc_lazy_dev_reconcile.sh"
    cleanup_test_env "$test_env"
}

test_source_lib_gen_lazy_stub_loads_on_first_call() {
    local test_env
    test_env=$(create_test_env "orc_lazy_gen")

    cat > "$test_env/test_orc_lazy_gen.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_GEN_LAZY_LOAD=1
export LAB_GEN_LAZY_MODULES="ana"

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

stub_def="$(declare -f ana_laf 2>/dev/null)"
[[ "$stub_def" == *"_orc_lazy_dispatch"* ]] || exit 1

ana_laf >/dev/null 2>&1 || true

real_def="$(declare -f ana_laf 2>/dev/null)"
[[ "$real_def" == *"_orc_lazy_dispatch"* ]] && exit 1

module_path="$LAB_DIR/lib/gen/ana"
[[ "${ORC_LAZY_MODULE_LOADED[$module_path]:-0}" == "1" ]] || exit 1
EOF
    chmod +x "$test_env/test_orc_lazy_gen.sh"

    run_test "Orchestrator lazy-loads selected gen module on first use" "$test_env/test_orc_lazy_gen.sh"
    cleanup_test_env "$test_env"
}

test_shared_loader_deduplicates_cross_path_sourcing() {
    local test_env
    test_env=$(create_test_env "orc_shared_loader")

    cat > "$test_env/test_orc_shared_loader.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_OPS_LAZY_LOAD=0
export LAB_GEN_LAZY_LOAD=0

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

if ! type lab_source_module >/dev/null 2>&1; then
    exit 1
fi

tmp_module=$(mktemp)
trap 'rm -f "$tmp_module"' EXIT
printf 'LAB_TEST_SOURCE_COUNTER=$((LAB_TEST_SOURCE_COUNTER + 1))\n' > "$tmp_module"

LAB_TEST_SOURCE_COUNTER=0

lab_source_module "test:registry" "$tmp_module" "test_seed" >/dev/null 2>&1 || exit 1

if ! source src/dic/ops >/dev/null 2>&1; then
    exit 1
fi
ops_source_module "test:registry" "$tmp_module" "dic_test" >/dev/null 2>&1 || exit 1

export LAB_MENU_AUTO_SOURCE=0
if ! source src/set/.menu >/dev/null 2>&1; then
    exit 1
fi
_menu_source_module "test:registry" "$tmp_module" "menu_test" >/dev/null 2>&1 || exit 1

[[ "${LAB_TEST_SOURCE_COUNTER}" -eq 1 ]] || exit 1
[[ "${LAB_MODULE_SOURCE_STATE[test:registry]:-0}" == "1" ]] || exit 1
EOF
    chmod +x "$test_env/test_orc_shared_loader.sh"

    run_test "Shared loader deduplicates sourcing across orc/dic/menu" "$test_env/test_orc_shared_loader.sh"
    cleanup_test_env "$test_env"
}

test_deployment_profile_uses_deployment_components() {
    local test_env
    test_env=$(create_test_env "orc_deployment_profile")

    cat > "$test_env/test_orc_deployment_profile.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_BOOTSTRAP_PROFILE=deployment

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

declare -f setup_deployment_components >/dev/null 2>&1 || exit 1

# Deployment profile should avoid interactive-only bootstrap artifacts.
if declare -f _ffl_laf_core >/dev/null 2>&1; then
    exit 1
fi

if declare -f ssh_fun >/dev/null 2>&1; then
    exit 1
fi
EOF
    chmod +x "$test_env/test_orc_deployment_profile.sh"

    run_test "Deployment profile routes through deployment component set" "$test_env/test_orc_deployment_profile.sh"
    cleanup_test_env "$test_env"
}

main() {
    run_test_suite "COMPONENT ORCHESTRATOR TESTS" \
        test_orc_script_exists \
        test_source_directory_skips_hidden_files \
        test_source_lib_ops_lazy_stub_loads_on_first_call \
        test_source_lib_ops_dev_reconcile_stub_is_lazy_loadable \
        test_source_lib_gen_lazy_stub_loads_on_first_call \
        test_shared_loader_deduplicates_cross_path_sourcing \
        test_deployment_profile_uses_deployment_components
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
