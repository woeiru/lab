#!/bin/bash
#######################################################################
# Stats Generator Validation Test
#######################################################################
# File: val/core/stats_generator_test.sh
# Description: Validates stats generator outputs and schema shape.
#
# Run: ./val/core/stats_generator_test.sh
#######################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../../val/helpers/test_framework.sh"

readonly STATS_GENERATOR="$LAB_ROOT/utl/ref/generators/stats"

test_generator_exists() {
    echo
    echo -e "${CYAN}--- Generator availability ---${NC}"

    test_file_exists "$STATS_GENERATOR" "Stats generator exists"
    run_test "Stats generator is executable" test -x "$STATS_GENERATOR"
}

test_stdout_formats() {
    echo
    echo -e "${CYAN}--- Stdout formats ---${NC}"

    run_test "Markdown stdout includes heading" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --markdown | grep -q '^# Repository Metrics'"

    run_test "Raw stdout is numeric" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --raw | grep -Eq '^[0-9]+$'"

    run_test "JSON stdout includes metric version" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --json | grep -q '\"metric_version\"'"

    run_test "Help includes ci gate option" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --help | grep -q -- '--ci-gate'"

    run_test "Help includes sample-tests option" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --help | grep -q -- '--sample-tests'"

    run_test "Help includes ci-gate-flaky option" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --help | grep -q -- '--ci-gate-flaky'"

    run_test "Help includes flaky-suite-budget option" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --help | grep -q -- '--flaky-suite-budget'"

    run_test "Help includes flaky-budget-profile option" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --help | grep -q -- '--flaky-budget-profile'"

    run_test "Invalid flaky-suite-budget fails" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --json --flaky-suite-budget=invalid >/dev/null 2>&1; test \$? -ne 0"

    run_test "Invalid flaky-budget-profile fails" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --json --flaky-budget-profile=invalid >/dev/null 2>&1; test \$? -ne 0"

    run_test "Flaky budget profile from env applies" bash -c \
        "LAB_DIR='$LAB_ROOT' STATS_FLAKY_BUDGET_PROFILE=balanced '$STATS_GENERATOR' --json | grep -q '\"budget_profile\": \"balanced\"'"

    run_test "Flaky budget profile defaults can be overridden" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --json --flaky-budget-profile=balanced --flaky-suite-budget=val/core/agents_md_test.sh:3:4 | grep -q '\"status_oscillation_budget\": 3'"
}

test_update_outputs() {
    echo
    echo -e "${CYAN}--- Output generation ---${NC}"

    run_test "Stats update command succeeds" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --update >/dev/null"

    test_file_exists "$LAB_ROOT/STATS.md" "STATS.md is generated"
    test_file_exists "$LAB_ROOT/doc/ref/stats/actual.md" "doc/ref/stats/actual.md is generated"
    test_dir_exists "$LAB_ROOT/doc/ref/stats" "stats directory exists"

    run_test "stats machine snapshot has quality gate block" grep -q '"quality_gates"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has churn block" grep -q '"churn"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has hotspots block" grep -q '"hotspots_90d"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has complexity block" grep -q '"complexity"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has risk_signals block" grep -q '"risk_signals"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has test_health block" grep -q '"test_health"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has flaky_candidates block" grep -q '"flaky_candidates"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has flaky policy block" grep -q '"flaky_policy"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has suite_budgets block" grep -q '"suite_budgets"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has over-budget summary" grep -q '"over_budget_total"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has budget profile" grep -q '"budget_profile"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has test_health quality gate" grep -q '"test_health"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has top_longest block" grep -q '"top_longest"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "stats machine snapshot has risk deltas block" grep -q '"delta_vs_previous"' "$LAB_ROOT/doc/ref/stats/actual.md"
    run_test "STATS.md has total line count metric" grep -q '^| Total line count |' "$LAB_ROOT/STATS.md"
    run_test "STATS.md has churn section" grep -q '^## Change Velocity and Churn' "$LAB_ROOT/STATS.md"
    run_test "STATS.md has complexity and risk section" grep -q '^## Complexity and Risk Signals' "$LAB_ROOT/STATS.md"
    run_test "STATS.md has test health section" grep -q '^## Test Health' "$LAB_ROOT/STATS.md"
    run_test "STATS.md has quality gates section" grep -q '^## Quality Gates Status' "$LAB_ROOT/STATS.md"
}

test_history_snapshot_created() {
    echo
    echo -e "${CYAN}--- Snapshot history ---${NC}"

    local snapshot_count
    snapshot_count="$(find "$LAB_ROOT/doc/ref/stats" -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
    snapshot_count="${snapshot_count:-0}"

    ((FRAMEWORK_TESTS_RUN++))
    test_log "Checking: stats directory has at least one snapshot"
    if [[ "$snapshot_count" -ge 1 ]]; then
        test_success "stats directory contains snapshots"
    else
        test_failure "stats directory has no snapshots"
    fi
}

test_header "Stats Generator Validation"

run_test_group "Stats Generator" \
    test_generator_exists \
    test_stdout_formats \
    test_update_outputs \
    test_history_snapshot_created

test_footer
