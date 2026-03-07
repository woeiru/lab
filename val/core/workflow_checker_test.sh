#!/bin/bash
#######################################################################
# Workflow Checker Regression Tests
#######################################################################
# File: val/core/workflow_checker_test.sh
# Description: Validates completed-folder timestamp behavior in
#              wow/check-workflow.sh, including historical root moves
#              and chronology enforcement.
#######################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"

create_checker_fixture_repo() {
    local test_env="$1"
    local repo_dir="$test_env/repo"

    mkdir -p "$repo_dir"
    mkdir -p "$repo_dir/wow"/{inbox,queue,active,completed,dismissed,experiments}
    cp "$LAB_ROOT/wow/check-workflow.sh" "$repo_dir/wow/check-workflow.sh"
    chmod +x "$repo_dir/wow/check-workflow.sh"

    git -C "$repo_dir" init >/dev/null 2>&1
    printf '%s\n' "$repo_dir"
}

git_commit_all() {
    local repo_dir="$1"
    local commit_date="$2"
    local message="$3"

    git -C "$repo_dir" add -A >/dev/null 2>&1
    GIT_AUTHOR_DATE="$commit_date" GIT_COMMITTER_DATE="$commit_date" \
        git -C "$repo_dir" -c user.name='test-bot' -c user.email='test-bot@example.com' commit -m "$message" >/dev/null 2>&1
}

assert_checker_passes_after_completed_root_move() {
    local test_env
    local repo_dir

    test_env="$(create_test_env "workflow_checker_root_move")"
    repo_dir="$(create_checker_fixture_repo "$test_env")" || {
        cleanup_test_env "$test_env"
        return 1
    }

    mkdir -p "$repo_dir/doc/pro/completed/20260301-1200_topic"
    cat > "$repo_dir/doc/pro/completed/20260301-1200_topic/20260301-1000_topic-plan.md" <<'EOF'
# Historical Topic Plan
EOF
    git_commit_all "$repo_dir" "2026-03-01T12:00:00" "seed historical completed item" || {
        cleanup_test_env "$test_env"
        return 1
    }

    mkdir -p "$repo_dir/wow/completed"
    git -C "$repo_dir" mv "doc/pro/completed/20260301-1200_topic" "wow/completed/20260301-1200_topic" >/dev/null 2>&1 || {
        cleanup_test_env "$test_env"
        return 1
    }
    git_commit_all "$repo_dir" "2026-03-07T09:08:00" "move completed tree to wow root" || {
        cleanup_test_env "$test_env"
        return 1
    }

    if ! bash "$repo_dir/wow/check-workflow.sh" >/dev/null 2>&1; then
        cleanup_test_env "$test_env"
        return 1
    fi

    cleanup_test_env "$test_env"
    return 0
}

assert_checker_fails_when_file_is_newer_than_folder() {
    local test_env
    local repo_dir
    local output=""

    test_env="$(create_test_env "workflow_checker_chronology")"
    repo_dir="$(create_checker_fixture_repo "$test_env")" || {
        cleanup_test_env "$test_env"
        return 1
    }

    mkdir -p "$repo_dir/wow/completed/20260301-0900_topic"
    cat > "$repo_dir/wow/completed/20260301-0900_topic/20260301-0910_topic-plan.md" <<'EOF'
# Chronology Violation Topic
EOF
    git_commit_all "$repo_dir" "2026-03-01T09:12:00" "add chronology-violating completed item" || {
        cleanup_test_env "$test_env"
        return 1
    }

    if output="$(bash "$repo_dir/wow/check-workflow.sh" 2>&1)"; then
        cleanup_test_env "$test_env"
        return 1
    fi

    if [[ "$output" != *"FAIL completed folder chronology"* ]]; then
        cleanup_test_env "$test_env"
        return 1
    fi

    cleanup_test_env "$test_env"
    return 0
}

test_completed_root_move_regression() {
    run_test "Checker passes after completed-tree root move" \
        assert_checker_passes_after_completed_root_move
}

test_completed_folder_chronology_guard() {
    run_test "Checker rejects file newer than completed folder timestamp" \
        assert_checker_fails_when_file_is_newer_than_folder
}

test_header "Workflow Checker Regression"

run_test_group "Completed Timestamp Rules" \
    test_completed_root_move_regression \
    test_completed_folder_chronology_guard

test_footer
