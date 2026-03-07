#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
LAB_ROOT_DEFAULT="$(cd "${SCRIPT_DIR}/../.." >/dev/null 2>&1 && pwd)"
LAB_ROOT="${LAB_ROOT:-${LAB_ROOT_DEFAULT}}"

show_usage() {
    cat <<'EOF'
Usage: val/lib/confidence_gate.sh --risk <low|medium|high> [options] <changed-file>...

Confidence gate for architecture-sensitive lib changes.

Options:
  --risk <level>   Required. low, medium, or high.
  --file <path>    Add one changed file path (repeatable).
  --dry-run        Print required checks without executing them.
  -h, --help       Show this help text.

Examples:
  val/lib/confidence_gate.sh --risk low --dry-run lib/ops/ssh
  val/lib/confidence_gate.sh --risk medium --file lib/gen/aux --file lib/ops/pve
  val/lib/confidence_gate.sh --risk high lib/gen/aux lib/ops/dev
EOF
}

resolve_abs_path() {
    local path="$1"
    if [[ "$path" == /* ]]; then
        printf '%s\n' "$path"
    else
        printf '%s\n' "${LAB_ROOT}/${path}"
    fi
}

to_rel_path() {
    local abs_path="$1"
    if [[ "$abs_path" == "${LAB_ROOT}/"* ]]; then
        printf '%s\n' "${abs_path#"${LAB_ROOT}/"}"
    else
        printf '%s\n' "$abs_path"
    fi
}

should_syntax_check() {
    local rel_path="$1"
    [[ "$rel_path" == *.md ]] && return 1
    [[ "$rel_path" == *.json ]] && return 1
    [[ "$rel_path" == *.txt ]] && return 1
    [[ "$rel_path" == *.log ]] && return 1
    return 0
}

add_command() {
    local command="$1"
    if [[ -z "${SEEN_COMMANDS[$command]:-}" ]]; then
        COMMANDS+=("$command")
        SEEN_COMMANDS[$command]=1
    fi
}

add_module_test_command() {
    local rel_path="$1"
    local library="$2"
    local module="$3"
    local test_script="val/lib/${library}/${module}_test.sh"

    [[ "$module" == *.* ]] && return 0

    if [[ -f "${LAB_ROOT}/${test_script}" ]]; then
        add_command "bash ${test_script}"
        FOUND_MODULE_TEST=1
    fi
}

risk=""
dry_run=0
declare -a input_paths=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --risk)
            [[ $# -lt 2 ]] && {
                printf 'Error: --risk requires a value.\n' >&2
                show_usage
                exit 1
            }
            risk="$2"
            shift 2
            ;;
        --file)
            [[ $# -lt 2 ]] && {
                printf 'Error: --file requires a path.\n' >&2
                show_usage
                exit 1
            }
            input_paths+=("$2")
            shift 2
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do
                input_paths+=("$1")
                shift
            done
            ;;
        *)
            input_paths+=("$1")
            shift
            ;;
    esac
done

if [[ -z "$risk" ]]; then
    printf 'Error: missing required --risk <low|medium|high>.\n' >&2
    show_usage
    exit 1
fi

case "$risk" in
    low|medium|high)
        ;;
    *)
        printf 'Error: invalid risk level: %s\n' "$risk" >&2
        show_usage
        exit 1
        ;;
esac

if [[ ${#input_paths[@]} -eq 0 ]]; then
    printf 'Error: provide at least one changed file path.\n' >&2
    show_usage
    exit 1
fi

declare -a changed_rel_paths=()
for path in "${input_paths[@]}"; do
    abs_path="$(resolve_abs_path "$path")"
    if [[ ! -f "$abs_path" ]]; then
        printf 'Error: changed file not found: %s\n' "$path" >&2
        exit 1
    fi
    changed_rel_paths+=("$(to_rel_path "$abs_path")")
done

declare -a COMMANDS=()
declare -A SEEN_COMMANDS=()
FOUND_MODULE_TEST=0

for rel_path in "${changed_rel_paths[@]}"; do
    if should_syntax_check "$rel_path"; then
        add_command "bash -n ${rel_path}"
    fi

    case "$rel_path" in
        lib/ops/*)
            module="${rel_path#lib/ops/}"
            module="${module%%/*}"
            add_module_test_command "$rel_path" "ops" "$module"
            ;;
        lib/gen/*)
            module="${rel_path#lib/gen/}"
            module="${module%%/*}"
            add_module_test_command "$rel_path" "gen" "$module"
            ;;
        lib/core/*)
            module="${rel_path#lib/core/}"
            module="${module%%/*}"
            add_module_test_command "$rel_path" "core" "$module"
            ;;
    esac
done

if [[ "$risk" == "low" ]]; then
    if [[ $FOUND_MODULE_TEST -eq 0 ]]; then
        add_command "bash val/run_all_tests.sh lib --quick"
    fi
fi

if [[ "$risk" == "medium" || "$risk" == "high" ]]; then
    add_command "bash val/run_all_tests.sh lib"
fi

if [[ "$risk" == "high" ]]; then
    add_command "bash val/run_all_tests.sh"
fi

printf 'Confidence Gate\n'
printf 'Risk level: %s\n' "$risk"
printf 'Changed files (%d):\n' "${#changed_rel_paths[@]}"
for rel_path in "${changed_rel_paths[@]}"; do
    printf '  - %s\n' "$rel_path"
done

printf 'Required checks (%d):\n' "${#COMMANDS[@]}"
for command in "${COMMANDS[@]}"; do
    printf '  - %s\n' "$command"
done

if [[ $dry_run -eq 1 ]]; then
    printf 'Dry run only; no commands executed.\n'
    exit 0
fi

failures=0
for command in "${COMMANDS[@]}"; do
    printf '[gate] run: %s\n' "$command"
    if ! (cd "$LAB_ROOT" && bash -c "$command"); then
        printf '[gate] fail: %s\n' "$command"
        failures=$((failures + 1))
    fi
done

if ((failures > 0)); then
    printf 'Confidence gate failed (%d command failures).\n' "$failures"
    exit 1
fi

printf 'Confidence gate passed.\n'
