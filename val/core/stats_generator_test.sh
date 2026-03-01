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

readonly STATS_GENERATOR="$LAB_ROOT/utl/doc/generators/stats"

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
}

test_update_outputs() {
    echo
    echo -e "${CYAN}--- Output generation ---${NC}"

    run_test "Stats update command succeeds" bash -c \
        "LAB_DIR='$LAB_ROOT' '$STATS_GENERATOR' --update >/dev/null"

    test_file_exists "$LAB_ROOT/STATS.md" "STATS.md is generated"
    test_file_exists "$LAB_ROOT/doc/ref/stats.json" "doc/ref/stats.json is generated"
    test_dir_exists "$LAB_ROOT/doc/ref/stats-history" "stats history directory exists"

    run_test "stats.json has quality gate block" grep -q '"quality_gates"' "$LAB_ROOT/doc/ref/stats.json"
    run_test "stats.json has churn block" grep -q '"churn"' "$LAB_ROOT/doc/ref/stats.json"
    run_test "stats.json has hotspots block" grep -q '"hotspots_90d"' "$LAB_ROOT/doc/ref/stats.json"
    run_test "stats.json has complexity block" grep -q '"complexity"' "$LAB_ROOT/doc/ref/stats.json"
    run_test "stats.json has risk_signals block" grep -q '"risk_signals"' "$LAB_ROOT/doc/ref/stats.json"
    run_test "stats.json has top_longest block" grep -q '"top_longest"' "$LAB_ROOT/doc/ref/stats.json"
    run_test "stats.json has risk deltas block" grep -q '"delta_vs_previous"' "$LAB_ROOT/doc/ref/stats.json"
    run_test "STATS.md has churn section" grep -q '^## Change Velocity and Churn' "$LAB_ROOT/STATS.md"
    run_test "STATS.md has complexity and risk section" grep -q '^## Complexity and Risk Signals' "$LAB_ROOT/STATS.md"
    run_test "STATS.md has quality gates section" grep -q '^## Quality Gates Status' "$LAB_ROOT/STATS.md"
}

test_history_snapshot_created() {
    echo
    echo -e "${CYAN}--- Snapshot history ---${NC}"

    local snapshot_count
    snapshot_count="$(find "$LAB_ROOT/doc/ref/stats-history" -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
    snapshot_count="${snapshot_count:-0}"

    ((FRAMEWORK_TESTS_RUN++))
    test_log "Checking: stats-history has at least one snapshot"
    if [[ "$snapshot_count" -ge 1 ]]; then
        test_success "stats-history contains snapshots"
    else
        test_failure "stats-history is empty"
    fi
}

test_header "Stats Generator Validation"

run_test_group "Stats Generator" \
    test_generator_exists \
    test_stdout_formats \
    test_update_outputs \
    test_history_snapshot_created

test_footer
