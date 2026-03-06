#!/bin/bash
#######################################################################
# Reference Pipeline Parity Test
#######################################################################
# File: val/core/ref_pipeline_parity_test.sh
# Description: Validates parity between analyzer-cycle row outputs and
#              generated doc/ref markdown table rows.
#######################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/gen/aux"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/gen/ana"

export LAB_DIR="$LAB_ROOT"

TMP_ROOT="$(mktemp -d)"

cleanup_temp_root() {
    if [[ -n "${TMP_ROOT:-}" ]] && [[ -d "$TMP_ROOT" ]]; then
        rm -rf "$TMP_ROOT"
    fi
}

trap cleanup_temp_root EXIT

normalize_row_line() {
    local line="$1"
    printf "%s" "$line" | sed 's/[[:space:]]*$//'
}

extract_doc_rows() {
    local doc_file="$1"
    local header_row="$2"
    local out_file="$3"
    local in_auto_section=false

    : > "$out_file"

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"<!-- AUTO-GENERATED SECTION:"* ]]; then
            in_auto_section=true
            continue
        fi
        if [[ "$line" == *"<!-- END AUTO-GENERATED SECTION"* ]]; then
            in_auto_section=false
            continue
        fi

        if [[ "$in_auto_section" != "true" ]]; then
            continue
        fi

        if [[ "$line" != \|* ]]; then
            continue
        fi

        if [[ "$line" == "$header_row" ]]; then
            continue
        fi

        if [[ "$line" =~ ^\|[-[:space:]\|]+\|$ ]]; then
            continue
        fi

        normalize_row_line "$line" >> "$out_file"
        printf "\n" >> "$out_file"
    done < "$doc_file"
}

collect_laf_expected_rows() {
    local out_file="$1"
    local tmp_dir="$TMP_ROOT/laf"
    local target_directories=("lib/core" "lib/ops" "lib/gen" "utl")

    : > "$out_file"
    mkdir -p "$tmp_dir"

    for target_dir in "${target_directories[@]}"; do
        local full_path="$LAB_ROOT/$target_dir"
        local lib_name

        [[ -d "$full_path" ]] || continue

        lib_name="$(basename "$target_dir")"

        while IFS= read -r -d '' file; do
            ana_laf -j --json-dir "$tmp_dir" "$file" >/dev/null 2>&1 || true

            local rel_file="${file#$LAB_ROOT/}"
            rel_file="${rel_file#/}"
            local json_file="$tmp_dir/${rel_file//\//_}.json"
            local module_name

            [[ -f "$json_file" ]] || continue

            module_name="$(basename "$file")"

            jq -r --arg lib "$lib_name" --arg mod "$module_name" '
                .functions[]? |
                [
                    $lib,
                    $mod,
                    "`\(.name)`",
                    (.arguments // ""),
                    (.shortname // ""),
                    (.description // ""),
                    (.size // ""),
                    (.location // ""),
                    (.calls_in_file // "")
                ] |
                "| " + join(" | ") + " |"
            ' "$json_file" 2>/dev/null >> "$out_file"
        done < <(find "$full_path" -type f -print0 | LC_ALL=C sort -z)
    done
}

collect_laf_actual_rows() {
    extract_doc_rows \
        "$LAB_ROOT/doc/ref/functions.md" \
        "| Library | Module | Function | Arguments | Shortname | Description | Size | Loc | Calls (file) |" \
        "$1"
}

collect_acu_expected_rows() {
    local out_file="$1"
    local tmp_dir="$TMP_ROOT/acu"
    local config_directories=("cfg/core" "cfg/env")
    local target_paths=("$LAB_ROOT/lib" "$LAB_ROOT/src" "$LAB_ROOT/utl")

    : > "$out_file"
    mkdir -p "$tmp_dir"

    for config_dir in "${config_directories[@]}"; do
        local config_full="$LAB_ROOT/$config_dir"

        [[ -d "$config_full" ]] || continue

        while IFS= read -r -d '' conf_file; do
            ana_acu -j --json-dir "$tmp_dir" "$conf_file" "${target_paths[@]}" >/dev/null 2>&1 || true

            local rel_conf="${conf_file#$LAB_ROOT/}"
            rel_conf="${rel_conf#/}"
            local json_file="$tmp_dir/${rel_conf//\//_}.json"

            [[ -f "$json_file" ]] || continue

            jq -r --arg conf "$rel_conf" '
                .variables[]? |
                [
                    "`\(.name)`",
                    "`\(.value | gsub("`";"\\`") | gsub("\\|"; "\\|"))`",
                    (.total_occurrences | tostring),
                    ([.usage_by_folder[]? | "\(.path): \(.total_occurrences)"] | join(", ")),
                    $conf
                ] |
                "| " + join(" | ") + " |"
            ' "$json_file" 2>/dev/null >> "$out_file"
        done < <(find "$config_full" -type f ! -path '*/.*' ! -name '*.*' -print0 | LC_ALL=C sort -z)
    done
}

collect_acu_actual_rows() {
    extract_doc_rows \
        "$LAB_ROOT/doc/ref/variables.md" \
        "| Variable | Value | Total Occurrences | Usage Breakdown | Config Source |" \
        "$1"
}

collect_rdp_expected_rows() {
    local out_file="$1"
    local tmp_dir="$TMP_ROOT/rdp"
    local source_modules=("$LAB_ROOT/lib/core" "$LAB_ROOT/lib/gen" "$LAB_ROOT/lib/ops")

    : > "$out_file"
    mkdir -p "$tmp_dir"

    for dir in "${source_modules[@]}"; do
        [[ -d "$dir" ]] || continue

        while IFS= read -r -d '' file; do
            local callsites=()

            if [[ "$dir" == *"lib/core" ]]; then
                callsites=("$LAB_ROOT/bin" "$LAB_ROOT/lib" "$LAB_ROOT/utl")
            elif [[ "$dir" == *"lib/gen" ]]; then
                callsites=("$LAB_ROOT/bin" "$LAB_ROOT/lib" "$LAB_ROOT/src" "$LAB_ROOT/utl")
            else
                callsites=("$LAB_ROOT/lib" "$LAB_ROOT/src" "$LAB_ROOT/utl")
            fi

            ana_rdp -j --json-dir "$tmp_dir" "$file" "${callsites[@]}" >/dev/null 2>&1 || true

            local rel_file="${file#$LAB_ROOT/}"
            rel_file="${rel_file#/}"
            local json_file="$tmp_dir/${rel_file//\//_}.json"

            [[ -f "$json_file" ]] || continue

            jq -r '
                .target_file as $target |
                .dependencies[]? |
                [
                    $target,
                    "`\(.function)`",
                    (.total_calls | tostring),
                    ([.used_by[]? | select(.calls > 0) | "\(.file): \(.calls)"] | join(", "))
                ] |
                "| " + join(" | ") + " |"
            ' "$json_file" 2>/dev/null >> "$out_file"
        done < <(find "$dir" -type f -print0 | LC_ALL=C sort -z)
    done
}

collect_rdp_actual_rows() {
    extract_doc_rows \
        "$LAB_ROOT/doc/ref/reverse-dependecies.md" \
        "| Target Module | Dependent Function | Total Calls | Dependent Files |" \
        "$1"
}

_dep_append_rows_from_json() {
    local json_file="$1"
    local out_file="$2"

    jq -r --arg root "$LAB_ROOT/" '
        .target_file as $target |
        [
            ($target | sub("^" + $root; "")),
            ((.dependencies.scripts // []) | if length == 0 then "-" else (map("`" + . + "`") | join(", ")) end),
            ((.dependencies.commands // []) | if length == 0 then "-" else (map("`" + . + "`") | join(", ")) end)
        ] |
        "| " + join(" | ") + " |"
    ' "$json_file" 2>/dev/null >> "$out_file"
}

collect_dep_expected_rows() {
    local out_file="$1"
    local tmp_dir="$TMP_ROOT/dep"
    local target_directories=("bin" "lib/core" "lib/gen" "lib/ops" "src" "utl")

    : > "$out_file"
    mkdir -p "$tmp_dir"

    local go_file="$LAB_ROOT/go"
    if [[ -f "$go_file" ]]; then
        ana_dep -j --json-dir "$tmp_dir" "$go_file" >/dev/null 2>&1 || true

        local go_rel="${go_file#$LAB_ROOT/}"
        go_rel="${go_rel#/}"
        local go_json="$tmp_dir/${go_rel//\//_}.json"

        if [[ -f "$go_json" ]]; then
            _dep_append_rows_from_json "$go_json" "$out_file"
        fi
    fi

    for target_dir in "${target_directories[@]}"; do
        local full_path="$LAB_ROOT/$target_dir"

        [[ -d "$full_path" ]] || continue

        while IFS= read -r -d '' file; do
            ana_dep -j --json-dir "$tmp_dir" "$file" >/dev/null 2>&1 || true

            local rel_file="${file#$LAB_ROOT/}"
            rel_file="${rel_file#/}"
            local json_file="$tmp_dir/${rel_file//\//_}.json"

            if [[ -f "$json_file" ]]; then
                _dep_append_rows_from_json "$json_file" "$out_file"
            fi
        done < <(find "$full_path" -type f ! -name "*.md" -print0 | LC_ALL=C sort -z)
    done
}

collect_dep_actual_rows() {
    extract_doc_rows \
        "$LAB_ROOT/doc/ref/module-dependencies.md" \
        "| Module File | Script Imports | Host Commands |" \
        "$1"
}

_tst_collect_rows() {
    local target_file="$1"
    local raw_rows_file="$2"
    local tmp_dir="$TMP_ROOT/tst"

    ana_tst -j --json-dir "$tmp_dir" "$target_file" >/dev/null 2>&1 || true

    local rel_file="${target_file#$LAB_ROOT/}"
    rel_file="${rel_file#/}"
    local json_file="$tmp_dir/${rel_file//\//_}.json"

    if [[ -f "$json_file" ]]; then
        jq -r '
            .target as $target |
            if ((.test_suites // []) | length) == 0 then
                [$target, "-", "0", "-", "No tests"] | @tsv
            else
                (.test_suites[] | [$target, .file, (.count|tostring), .type, .status] | @tsv)
            end
        ' "$json_file" 2>/dev/null >> "$raw_rows_file"
    fi
}

collect_tst_expected_rows() {
    local out_file="$1"
    local tmp_dir="$TMP_ROOT/tst"
    local target_directories=("bin" "lib/core" "lib/gen" "lib/ops" "src" "utl")
    local raw_rows

    : > "$out_file"
    mkdir -p "$tmp_dir"
    raw_rows="$(mktemp)"

    local go_file="$LAB_ROOT/go"
    if [[ -f "$go_file" ]]; then
        _tst_collect_rows "$go_file" "$raw_rows"
    fi

    for target_dir in "${target_directories[@]}"; do
        local full_path="$LAB_ROOT/$target_dir"

        [[ -d "$full_path" ]] || continue

        while IFS= read -r -d '' file; do
            _tst_collect_rows "$file" "$raw_rows"
        done < <(find "$full_path" -type f -print0 | LC_ALL=C sort -z)
    done

    if [[ -s "$raw_rows" ]]; then
        while IFS=$'\t' read -r target test_file count test_type status; do
            local target_cell="\`$target\`"
            local test_cell="-"

            if [[ "$test_file" != "-" ]]; then
                test_cell="\`$test_file\`"
            fi

            echo "| $target_cell | $test_cell | $count | $test_type | $status |" >> "$out_file"
        done < <(LC_ALL=C sort -t $'\t' -k1,1 -k2,2 "$raw_rows")
    fi

    rm -f "$raw_rows"
}

collect_tst_actual_rows() {
    extract_doc_rows \
        "$LAB_ROOT/doc/ref/test-coverage.md" \
        "| Target Module | Test File | Count | Type | Status |" \
        "$1"
}

_scp_collect_rows() {
    local target_file="$1"
    local raw_rows_file="$2"
    local tmp_dir="$TMP_ROOT/scp"

    ana_scp -j --json-dir "$tmp_dir" "$target_file" >/dev/null 2>&1 || true

    local rel_file="${target_file#$LAB_ROOT/}"
    rel_file="${rel_file#/}"
    local json_file="$tmp_dir/${rel_file//\//_}_scp.json"

    if [[ -f "$json_file" ]]; then
        jq -r --arg target "$rel_file" '
            if ((.scope_analysis // []) | length) == 0 then
                [$target, "-", "-", "-", "No findings"] | @tsv
            else
                (.scope_analysis[] | [$target, .type, .variable, (.line|tostring), .context] | @tsv)
            end
        ' "$json_file" 2>/dev/null >> "$raw_rows_file"
    fi
}

collect_scp_expected_rows() {
    local out_file="$1"
    local tmp_dir="$TMP_ROOT/scp"
    local target_directories=("bin" "lib/core" "lib/gen" "lib/ops" "src" "utl")
    local raw_rows

    : > "$out_file"
    mkdir -p "$tmp_dir"
    raw_rows="$(mktemp)"

    local go_file="$LAB_ROOT/go"
    if [[ -f "$go_file" ]]; then
        _scp_collect_rows "$go_file" "$raw_rows"
    fi

    for target_dir in "${target_directories[@]}"; do
        local full_path="$LAB_ROOT/$target_dir"

        [[ -d "$full_path" ]] || continue

        while IFS= read -r -d '' file; do
            _scp_collect_rows "$file" "$raw_rows"
        done < <(find "$full_path" -type f -print0 | LC_ALL=C sort -z)
    done

    if [[ -s "$raw_rows" ]]; then
        while IFS=$'\t' read -r target scope_type variable line context; do
            local target_cell="\`$target\`"
            local variable_cell="-"
            local context_cell="-"

            if [[ "$variable" != "-" ]]; then
                variable_cell="\`$variable\`"
            fi
            if [[ "$context" != "-" ]]; then
                context_cell="\`$context\`"
            fi

            echo "| $target_cell | $scope_type | $variable_cell | $line | $context_cell |" >> "$out_file"
        done < <(LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3 -k4,4n "$raw_rows")
    fi

    rm -f "$raw_rows"
}

collect_scp_actual_rows() {
    extract_doc_rows \
        "$LAB_ROOT/doc/ref/scope-integrity.md" \
        "| Target Module | Type | Variable | Line | Context |" \
        "$1"
}

_err_collect_rows() {
    local target_file="$1"
    local raw_rows_file="$2"
    local tmp_dir="$TMP_ROOT/err"

    ana_err -j --json-dir "$tmp_dir" "$target_file" >/dev/null 2>&1 || true

    local rel_file="${target_file#$LAB_ROOT/}"
    rel_file="${rel_file#/}"
    local json_file="$tmp_dir/${rel_file//\//_}.err.json"

    if [[ -f "$json_file" ]]; then
        jq -r --arg target "$rel_file" '
            if ((.errors // []) | length) == 0 then
                [$target, "-", "-", "-", "No findings"] | @tsv
            else
                (.errors[] | [$target, .function, .type, (.location|tostring), (.message // "-")] | @tsv)
            end
        ' "$json_file" 2>/dev/null >> "$raw_rows_file"
    fi
}

collect_err_expected_rows() {
    local out_file="$1"
    local tmp_dir="$TMP_ROOT/err"
    local target_directories=("bin" "lib/core" "lib/gen" "lib/ops" "src" "utl")
    local raw_rows

    : > "$out_file"
    mkdir -p "$tmp_dir"
    raw_rows="$(mktemp)"

    local go_file="$LAB_ROOT/go"
    if [[ -f "$go_file" ]]; then
        _err_collect_rows "$go_file" "$raw_rows"
    fi

    for target_dir in "${target_directories[@]}"; do
        local full_path="$LAB_ROOT/$target_dir"

        [[ -d "$full_path" ]] || continue

        while IFS= read -r -d '' file; do
            _err_collect_rows "$file" "$raw_rows"
        done < <(find "$full_path" -type f -print0 | LC_ALL=C sort -z)
    done

    if [[ -s "$raw_rows" ]]; then
        while IFS=$'\t' read -r target func_name err_type line message; do
            local target_cell="\`$target\`"
            local func_cell="-"
            local msg_cell="-"
            local safe_type="$err_type"

            if [[ "$func_name" != "-" ]]; then
                func_cell="\`$func_name\`"
            fi
            if [[ "$message" != "-" ]]; then
                msg_cell="\`$message\`"
            fi

            safe_type="${safe_type//|/\\|}"

            echo "| $target_cell | $func_cell | $safe_type | $line | $msg_cell |" >> "$out_file"
        done < <(LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3 -k4,4n "$raw_rows")
    fi

    rm -f "$raw_rows"
}

collect_err_actual_rows() {
    extract_doc_rows \
        "$LAB_ROOT/doc/ref/error-handling.md" \
        "| Target Module | Function | Type | Line | Message/Code |" \
        "$1"
}

report_row_diff_sample() {
    local label="$1"
    local file="$2"
    local limit=5

    [[ -s "$file" ]] || return 0

    echo "  $label"
    local idx=0
    while IFS= read -r line; do
        echo "    - $line"
        idx=$((idx + 1))
        if [[ "$idx" -ge "$limit" ]]; then
            break
        fi
    done < "$file"
}

run_pipeline_parity_check() {
    local pipeline_label="$1"
    local expected_collector="$2"
    local actual_collector="$3"
    local expected_file
    local actual_file
    local expected_sorted
    local actual_sorted
    local missing_file
    local extra_file

    expected_file="$(mktemp)"
    actual_file="$(mktemp)"
    expected_sorted="$(mktemp)"
    actual_sorted="$(mktemp)"
    missing_file="$(mktemp)"
    extra_file="$(mktemp)"

    "$expected_collector" "$expected_file"
    "$actual_collector" "$actual_file"

    LC_ALL=C sort "$expected_file" > "$expected_sorted"
    LC_ALL=C sort "$actual_file" > "$actual_sorted"

    LC_ALL=C comm -23 "$expected_sorted" "$actual_sorted" > "$missing_file" || true
    LC_ALL=C comm -13 "$expected_sorted" "$actual_sorted" > "$extra_file" || true

    local expected_count
    local actual_count
    local missing_count
    local extra_count

    expected_count="$(wc -l < "$expected_sorted" | tr -d ' ')"
    actual_count="$(wc -l < "$actual_sorted" | tr -d ' ')"
    missing_count="$(wc -l < "$missing_file" | tr -d ' ')"
    extra_count="$(wc -l < "$extra_file" | tr -d ' ')"

    ((FRAMEWORK_TESTS_RUN++))
    test_log "Checking parity: $pipeline_label"

    if [[ "$missing_count" -eq 0 ]] && [[ "$extra_count" -eq 0 ]]; then
        pass "Parity matched: $pipeline_label (rows=$actual_count)"
    else
        fail "Parity drift: $pipeline_label (expected=$expected_count actual=$actual_count missing=$missing_count extra=$extra_count)"
        report_row_diff_sample "Missing rows:" "$missing_file"
        report_row_diff_sample "Extra rows:" "$extra_file"
    fi

    rm -f "$expected_file" "$actual_file" "$expected_sorted" "$actual_sorted" "$missing_file" "$extra_file"
}

test_laf_pipeline_parity() {
    describe "ffl-laf_cycle parity"
    run_pipeline_parity_check \
        "ffl-laf_cycle <-> doc/ref/functions.md" \
        collect_laf_expected_rows \
        collect_laf_actual_rows
}

test_acu_pipeline_parity() {
    describe "ffl-acu_cycle parity"
    run_pipeline_parity_check \
        "ffl-acu_cycle <-> doc/ref/variables.md" \
        collect_acu_expected_rows \
        collect_acu_actual_rows
}

test_rdp_pipeline_parity() {
    describe "ffl-rdp_cycle parity"
    run_pipeline_parity_check \
        "ffl-rdp_cycle <-> doc/ref/reverse-dependecies.md" \
        collect_rdp_expected_rows \
        collect_rdp_actual_rows
}

test_dep_pipeline_parity() {
    describe "ffl-dep_cycle parity"
    run_pipeline_parity_check \
        "ffl-dep_cycle <-> doc/ref/module-dependencies.md" \
        collect_dep_expected_rows \
        collect_dep_actual_rows
}

test_tst_pipeline_parity() {
    describe "ffl-tst_cycle parity"
    run_pipeline_parity_check \
        "ffl-tst_cycle <-> doc/ref/test-coverage.md" \
        collect_tst_expected_rows \
        collect_tst_actual_rows
}

test_scp_pipeline_parity() {
    describe "ffl-scp_cycle parity"
    run_pipeline_parity_check \
        "ffl-scp_cycle <-> doc/ref/scope-integrity.md" \
        collect_scp_expected_rows \
        collect_scp_actual_rows
}

test_err_pipeline_parity() {
    describe "ffl-err_cycle parity"
    run_pipeline_parity_check \
        "ffl-err_cycle <-> doc/ref/error-handling.md" \
        collect_err_expected_rows \
        collect_err_actual_rows
}

test_header "Reference Pipeline Parity"

run_test "jq command is available" command -v jq

run_test_group "Reference parity" \
    test_laf_pipeline_parity \
    test_acu_pipeline_parity \
    test_rdp_pipeline_parity \
    test_dep_pipeline_parity \
    test_tst_pipeline_parity \
    test_scp_pipeline_parity \
    test_err_pipeline_parity

test_footer
