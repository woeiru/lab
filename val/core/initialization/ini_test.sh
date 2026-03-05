#!/bin/bash
#######################################################################
# Core Module Tests - Initialization System
#######################################################################
# File: val/core/initialization/ini_test.sh
# Description: Comprehensive tests for the system initialization
#              controller (bin/ini) including module loading,
#              dependency verification, and startup sequence.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="$LAB_ROOT"
readonly INI_SCRIPT="$TEST_LAB_DIR/bin/ini"

# Test functions
test_ini_script_exists() {
    test_file_exists "$INI_SCRIPT" "Initialization script exists"
}

test_ini_script_executable() {
    run_test "Initialization script is executable" test -x "$INI_SCRIPT"
}

test_ini_script_shebang() {
    local shebang
    if read -r shebang < "$INI_SCRIPT"; then
        run_test "Initialization script has correct shebang" test "$shebang" = "#!/bin/bash"
    else
        test_failure "Cannot read shebang from initialization script"
    fi
}

test_core_modules_loading() {
    # Test that ini can load core modules
    local test_env=$(create_test_env "ini_core_modules")
    
    cat > "$test_env/test_ini_modules.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

# Test sourcing ini (should load core modules)
if source bin/ini 2>/dev/null; then
    # Check if core modules are loaded
    if declare -f _log_write >/dev/null && declare -f err_process >/dev/null && declare -f lo1_log >/dev/null && declare -f tme_start_timer >/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_ini_modules.sh"
    
    run_test "Core modules loading via ini" "$test_env/test_ini_modules.sh"
    cleanup_test_env "$test_env"
}

test_dependency_verification() {
    # Test that ini properly verifies dependencies
    local test_env=$(create_test_env "ini_dependencies")
    
    cat > "$test_env/test_dependencies.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

# Source ini and check if verification functions are available
if source bin/ini 2>/dev/null; then
    if declare -f ver_verify_path >/dev/null && declare -f ver_verify_module >/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_dependencies.sh"
    
    run_test "Dependency verification system loaded" "$test_env/test_dependencies.sh"
    cleanup_test_env "$test_env"
}

test_environment_variables() {
    # Test that ini sets up required environment variables
    local test_env=$(create_test_env "ini_env_vars")
    
    cat > "$test_env/test_env_vars.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

if source bin/ini 2>/dev/null; then
    # Check for critical environment variables
    if [[ -n "${BASE_DIR:-}" ]] && [[ -n "${LOG_DIR:-}" ]] && [[ -n "${TMP_DIR:-}" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_env_vars.sh"
    
    run_test "Environment variables properly set" "$test_env/test_env_vars.sh"
    cleanup_test_env "$test_env"
}

test_logging_initialization() {
    # Test that logging system is properly initialized
    local test_env=$(create_test_env "ini_logging")
    
    cat > "$test_env/test_logging.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

if source bin/ini 2>/dev/null; then
    # Test if logging functions work
    if lo1_log "test" 2>/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_logging.sh"
    
    run_test "Logging system initialization" "$test_env/test_logging.sh"
    cleanup_test_env "$test_env"
}

test_source_directory_skips_hidden_files() {
    local test_env=$(create_test_env "ini_hidden_files")

    cat > "$test_env/test_hidden_files.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

temp_module_dir=$(mktemp -d)
trap 'rm -rf "$temp_module_dir"' EXIT

printf 'VISIBLE_WAS_SOURCED=1\n' > "$temp_module_dir/visible_module"
printf 'HIDDEN_WAS_SOURCED=1\n' > "$temp_module_dir/.hidden_spec"

if ! source_directory "$temp_module_dir" "*" "test modules" >/dev/null 2>&1; then
    exit 1
fi

[[ "${VISIBLE_WAS_SOURCED:-}" == "1" ]] || exit 1
[[ -z "${HIDDEN_WAS_SOURCED:-}" ]] || exit 1
EOF
    chmod +x "$test_env/test_hidden_files.sh"

    run_test "Directory loader skips hidden files" "$test_env/test_hidden_files.sh"
    cleanup_test_env "$test_env"
}

test_deployment_profile_skips_alias_bootstrap() {
    local test_env=$(create_test_env "ini_deployment_profile")

    cat > "$test_env/test_deployment_profile.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_BOOTSTRAP_PROFILE=deployment

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

# Deployment profile should skip alias sourcing.
if declare -f _ffl_laf_core >/dev/null 2>&1; then
    exit 1
fi

declare -f setup_deployment_components >/dev/null 2>&1 || exit 1
[[ "${RC_SOURCED:-0}" -eq 1 ]] || exit 1
EOF
    chmod +x "$test_env/test_deployment_profile.sh"

    run_test "Deployment profile skips interactive alias bootstrap" "$test_env/test_deployment_profile.sh"
    cleanup_test_env "$test_env"
}

test_default_bootstrap_mode_is_compact() {
    local test_env
    test_env=$(create_test_env "ini_default_compact")

    cat > "$test_env/test_default_compact.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

unset LAB_BOOTSTRAP_OUTPUT
unset LAB_BOOTSTRAP_VERBOSITY
export MASTER_TERMINAL_VERBOSITY=off

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

[[ "${LAB_BOOTSTRAP_OUTPUT:-}" == "compact" ]] || exit 1
[[ "${LAB_BOOTSTRAP_VERBOSITY:-}" == "compact" ]] || exit 1
EOF
    chmod +x "$test_env/test_default_compact.sh"

    run_test "Default bootstrap mode resolves to compact" "$test_env/test_default_compact.sh"
    cleanup_test_env "$test_env"
}

test_bootstrap_verbosity_verbose_forces_legacy() {
    local test_env
    test_env=$(create_test_env "ini_verbosity_verbose")

    cat > "$test_env/test_verbosity_verbose.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

unset LAB_BOOTSTRAP_OUTPUT
export LAB_BOOTSTRAP_VERBOSITY=verbose
export MASTER_TERMINAL_VERBOSITY=off

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

[[ "${LAB_BOOTSTRAP_OUTPUT:-}" == "legacy" ]] || exit 1
[[ "${LAB_BOOTSTRAP_VERBOSITY:-}" == "verbose" ]] || exit 1
EOF
    chmod +x "$test_env/test_verbosity_verbose.sh"

    run_test "Bootstrap verbosity=verbose forces legacy output" "$test_env/test_verbosity_verbose.sh"
    cleanup_test_env "$test_env"
}

test_bootstrap_verbosity_silent_disables_terminal_streams() {
    local test_env
    test_env=$(create_test_env "ini_verbosity_silent")

    cat > "$test_env/test_verbosity_silent.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

unset LAB_BOOTSTRAP_OUTPUT
export LAB_BOOTSTRAP_VERBOSITY=silent
export MASTER_TERMINAL_VERBOSITY=on

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

[[ "${LAB_BOOTSTRAP_OUTPUT:-}" == "compact" ]] || exit 1
[[ "${INI_LOG_TERMINAL_VERBOSITY:-}" == "off" ]] || exit 1
[[ "${LO1_LOG_TERMINAL_VERBOSITY:-}" == "off" ]] || exit 1
[[ "${ERR_TERMINAL_VERBOSITY:-}" == "off" ]] || exit 1
[[ "${TME_TERMINAL_VERBOSITY:-}" == "off" ]] || exit 1
EOF
    chmod +x "$test_env/test_verbosity_silent.sh"

    run_test "Bootstrap verbosity=silent disables terminal streams" "$test_env/test_verbosity_silent.sh"
    cleanup_test_env "$test_env"
}

test_compiled_bootstrap_cache_used_when_fresh() {
    local test_env=$(create_test_env "ini_compiled_cache_fresh")

    cat > "$test_env/test_compiled_cache_fresh.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_BOOTSTRAP_CACHE_ENABLED=1

if ! ./go compile >/dev/null 2>&1; then
    exit 1
fi

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

[[ "${INI_COMPILED_BOOTSTRAP_CACHE_USED:-0}" -eq 1 ]] || exit 1
EOF
    chmod +x "$test_env/test_compiled_cache_fresh.sh"

    run_test "Compiled bootstrap cache is used when fresh" "$test_env/test_compiled_cache_fresh.sh"
    cleanup_test_env "$test_env"
}

test_compiled_bootstrap_cache_stale_falls_back() {
    local test_env=$(create_test_env "ini_compiled_cache_stale")

    cat > "$test_env/test_compiled_cache_stale.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR" || exit 1

export MASTER_TERMINAL_VERBOSITY=off
export LAB_BOOTSTRAP_CACHE_ENABLED=1

if ! ./go compile >/dev/null 2>&1; then
    exit 1
fi

cache_dir=$(mktemp -d)
trap 'rm -rf "$cache_dir"' EXIT

cache_file="$cache_dir/ini_core.cache"
cache_meta="$cache_dir/ini_core.meta"

cp .tmp/bootstrap/ini_core.cache "$cache_file" || exit 1
cp .tmp/bootstrap/ini_core.meta "$cache_meta" || exit 1

stale_meta="$cache_meta.stale"
stale_written=0

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == source\|* ]] && [[ "$stale_written" -eq 0 ]]; then
        source_path="${line#source|}"
        source_path="${source_path%%|*}"
        printf 'source|%s|0:0\n' "$source_path" >> "$stale_meta"
        stale_written=1
    else
        printf '%s\n' "$line" >> "$stale_meta"
    fi
done < "$cache_meta"

mv "$stale_meta" "$cache_meta" || exit 1

export LAB_BOOTSTRAP_CACHE_FILE="$cache_file"
export LAB_BOOTSTRAP_CACHE_META="$cache_meta"

if ! source bin/ini >/dev/null 2>&1; then
    exit 1
fi

[[ "${INI_COMPILED_BOOTSTRAP_CACHE_USED:-0}" -eq 0 ]] || exit 1
declare -f err_process >/dev/null 2>&1 || exit 1
declare -f lo1_log >/dev/null 2>&1 || exit 1
declare -f tme_start_timer >/dev/null 2>&1 || exit 1
declare -f _log_write >/dev/null 2>&1 || exit 1
EOF
    chmod +x "$test_env/test_compiled_cache_stale.sh"

    run_test "Stale compiled bootstrap cache falls back to source modules" "$test_env/test_compiled_cache_stale.sh"
    cleanup_test_env "$test_env"
}

test_performance_init() {
    start_performance_test "ini sourcing performance"
    
    local test_env=$(create_test_env "ini_performance")
    cat > "$test_env/perf_test.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"
source bin/ini >/dev/null 2>&1
EOF
    chmod +x "$test_env/perf_test.sh"
    
    "$test_env/perf_test.sh"
    cleanup_test_env "$test_env"
    
    end_performance_test "ini sourcing performance" 5000  # 5 second threshold
}

# Main execution
main() {
    run_test_suite "INITIALIZATION CONTROLLER TESTS" \
        test_ini_script_exists \
        test_ini_script_executable \
        test_ini_script_shebang \
        test_core_modules_loading \
        test_dependency_verification \
        test_environment_variables \
        test_logging_initialization \
        test_source_directory_skips_hidden_files \
        test_deployment_profile_skips_alias_bootstrap \
        test_default_bootstrap_mode_is_compact \
        test_bootstrap_verbosity_verbose_forces_legacy \
        test_bootstrap_verbosity_silent_disables_terminal_streams \
        test_compiled_bootstrap_cache_used_when_fresh \
        test_compiled_bootstrap_cache_stale_falls_back \
        test_performance_init
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
