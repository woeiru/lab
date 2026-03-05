#!/bin/bash

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
LAB_ROOT="$(cd "${TEST_DIR}/../../.." >/dev/null 2>&1 && pwd)"

MENU_FILE="${LAB_ROOT}/src/set/.menu"
RUNBOOKS=(
    "${LAB_ROOT}/src/set/h1"
    "${LAB_ROOT}/src/set/c1"
    "${LAB_ROOT}/src/set/c2"
    "${LAB_ROOT}/src/set/c3"
    "${LAB_ROOT}/src/set/t1"
    "${LAB_ROOT}/src/set/t2"
)

fail_count=0

fail() {
    local message="$1"
    printf 'FAIL: %s\n' "$message"
    fail_count=$((fail_count + 1))
}

check_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    if ! grep -Fq "$pattern" "$file"; then
        fail "$description ($file)"
    fi
}

check_not_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    if grep -Fq "$pattern" "$file"; then
        fail "$description ($file)"
    fi
}

printf 'Running src/set bootstrap/logging contract test\n'

check_contains "$MENU_FILE" 'menu_runtime_setup() {' 'menu runtime setup helper missing'
check_contains "$MENU_FILE" 'clean_exit() {' 'clean_exit compatibility helper missing'
check_contains "$MENU_FILE" 'LAB_MENU_AUTO_SOURCE_ON_SOURCE' 'source-time compatibility toggle missing'
check_not_contains "$MENU_FILE" 'echo "DEBUG:' 'legacy debug echo remains in .menu'

for runbook in "${RUNBOOKS[@]}"; do
    check_contains "$runbook" 'menu_runtime_setup "${BASE_SH}_bootstrap" || exit 2' 'runbook missing explicit runtime setup call'
    check_not_contains "$runbook" '[DEBUG] Sourcing:' 'legacy startup debug print remains in runbook'
    if ! bash -n "$runbook"; then
        fail "syntax check failed ($runbook)"
    fi
done

if ! bash -n "$MENU_FILE"; then
    fail "syntax check failed ($MENU_FILE)"
fi

if [[ "$fail_count" -ne 0 ]]; then
    printf 'Contract test failed with %s issue(s)\n' "$fail_count"
    exit 1
fi

printf 'Contract test passed\n'
exit 0
