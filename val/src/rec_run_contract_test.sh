#!/bin/bash

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
LAB_ROOT="$(cd "${TEST_DIR}/../.." >/dev/null 2>&1 && pwd)"

REC_OPS="${LAB_ROOT}/src/rec/ops"
RUN_DISPATCH="${LAB_ROOT}/src/run/dispatch"
RUN_GATE_EVIDENCE="${LAB_ROOT}/src/run/gate-evidence"
REC_RUN_BRIDGE="${LAB_ROOT}/src/dic/run"
SET_H1="${LAB_ROOT}/src/set/h1"

fail_count=0

fail() {
    local message="$1"
    printf 'FAIL: %s\n' "$message"
    fail_count=$((fail_count + 1))
}

expect_success() {
    local description="$1"
    shift
    if ! "$@" >/dev/null 2>&1; then
        fail "$description"
    fi
}

expect_failure() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$description"
    fi
}

printf 'Running src/rec + src/run scaffolding contract test\n'

expect_success "src/rec/ops is present" test -f "$REC_OPS"
expect_success "src/run/dispatch is present" test -f "$RUN_DISPATCH"
expect_success "src/run/gate-evidence is present" test -f "$RUN_GATE_EVIDENCE"
expect_success "src/dic/run is present" test -f "$REC_RUN_BRIDGE"
expect_success "src/set/h1 is present" test -f "$SET_H1"

expect_success "src/rec/ops syntax is valid" bash -n "$REC_OPS"
expect_success "src/run/dispatch syntax is valid" bash -n "$RUN_DISPATCH"
expect_success "src/run/gate-evidence syntax is valid" bash -n "$RUN_GATE_EVIDENCE"
expect_success "src/dic/run syntax is valid" bash -n "$REC_RUN_BRIDGE"

rec_help_output="$("$REC_OPS" --help 2>&1 || true)"
if [[ "$rec_help_output" != *"Usage: src/rec/ops"* ]]; then
    fail "src/rec/ops help output missing usage header"
fi

expect_success "src/rec/ops validate succeeds on scaffolded cfg/dcl" "$REC_OPS" validate

tmpdir="$(mktemp -d)"
artifact_path="${tmpdir}/compile.plan"
if ! "$REC_OPS" compile --output "$artifact_path" >/dev/null 2>&1; then
    fail "src/rec/ops compile failed"
fi
expect_success "compile artifact was written" test -f "$artifact_path"

artifact_content="$(<"$artifact_path")"
if [[ "$artifact_content" != *"format=rec-plan-v0"* ]]; then
    fail "compile artifact missing format marker"
fi
if [[ "$artifact_content" != *"target_count="* ]]; then
    fail "compile artifact missing target metadata"
fi
if [[ "$artifact_content" != *"_mode="* ]]; then
    fail "compile artifact missing target mode metadata"
fi
if [[ "$artifact_content" != *"_preconditions="* ]]; then
    fail "compile artifact missing target preconditions metadata"
fi
if [[ "$artifact_content" != *"_order="* ]]; then
    fail "compile artifact missing target order metadata"
fi
if [[ "$artifact_content" != *"_depends_on="* ]]; then
    fail "compile artifact missing target dependency metadata"
fi
if [[ "$artifact_content" != *"_policy_gates="* ]]; then
    fail "compile artifact missing target policy gate metadata"
fi
if [[ "$artifact_content" != *"enforcement_stage_default="* ]]; then
    fail "compile artifact missing enforcement stage default metadata"
fi
if [[ "$artifact_content" != *"_enforcement_stage="* ]]; then
    fail "compile artifact missing target enforcement stage metadata"
fi

gate_evidence_h1_path="${tmpdir}/gate-evidence-h1"
cat > "$gate_evidence_h1_path" <<'EOF'
format=gate-evidence-v0
target=h1
approved_gates=gate_network gate_storage
EOF

gate_evidence_t2_path="${tmpdir}/gate-evidence-t2"
cat > "$gate_evidence_t2_path" <<'EOF'
format=gate-evidence-v0
target=t2
approved_gate_1=gate_network
approved_gate_2=gate_access
EOF

invalid_gate_evidence_format_path="${tmpdir}/gate-evidence-invalid-format"
cat > "$invalid_gate_evidence_format_path" <<'EOF'
target=h1
approved_gates=gate_network gate_storage
EOF

invalid_gate_evidence_target_path="${tmpdir}/gate-evidence-invalid-target"
cat > "$invalid_gate_evidence_target_path" <<'EOF'
format=gate-evidence-v0
target=t2
approved_gates=gate_network gate_storage
EOF

invalid_gate_evidence_token_path="${tmpdir}/gate-evidence-invalid-token"
cat > "$invalid_gate_evidence_token_path" <<'EOF'
format=gate-evidence-v0
target=h1
approved_gates=gate_network gate@invalid
EOF

run_help_output="$("$RUN_DISPATCH" --help 2>&1 || true)"
if [[ "$run_help_output" != *"Usage: src/run/dispatch"* ]]; then
    fail "src/run/dispatch help output missing usage header"
fi

run_gate_help_output="$("$RUN_GATE_EVIDENCE" --help 2>&1 || true)"
if [[ "$run_gate_help_output" != *"Usage: src/run/gate-evidence"* ]]; then
    fail "src/run/gate-evidence help output missing usage header"
fi

produced_gate_evidence_h1_path="${tmpdir}/gate-evidence-produced-h1"
expect_success "src/run/gate-evidence produces artifact for h1" "$RUN_GATE_EVIDENCE" h1 --plan "$artifact_path" --allow-gate gate_network --allow-gate gate_storage --output "$produced_gate_evidence_h1_path"
expect_failure "src/run/gate-evidence rejects missing required plan gate" "$RUN_GATE_EVIDENCE" h1 --plan "$artifact_path" --allow-gate gate_network --output "${tmpdir}/gate-evidence-missing-gate"
expect_success "src/run/gate-evidence uses env approved gates" env LAB_RUN_ALLOWED_POLICY_GATES="gate_network gate_storage" "$RUN_GATE_EVIDENCE" h1 --plan "$artifact_path" --output "${tmpdir}/gate-evidence-produced-env-h1"

expect_failure "src/run/dispatch should fail on unknown target" "$RUN_DISPATCH" unknown-target
expect_success "src/run/dispatch accepts valid plan artifact" "$RUN_DISPATCH" h1 --plan "$artifact_path"
expect_failure "src/run/dispatch rejects plan without matching target" "$RUN_DISPATCH" unknown-target --plan "$artifact_path"
expect_failure "src/run/dispatch rejects section not allowed by plan" "$RUN_DISPATCH" h1 --plan "$artifact_path" -x invalid-section
expect_failure "src/run/dispatch rejects missing section value after -x" "$RUN_DISPATCH" h1 --plan "$artifact_path" -x
expect_failure "src/run/dispatch rejects enforcement flags without plan" "$RUN_DISPATCH" h1 --enforce-deps
expect_failure "src/run/dispatch rejects gate evidence without plan" "$RUN_DISPATCH" h1 --gate-evidence "$gate_evidence_h1_path"
expect_failure "src/run/dispatch rejects invalid enforcement stage" "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforcement-stage invalid
expect_failure "src/run/dispatch enforce-deps fails without completion context" "$RUN_DISPATCH" t2 --plan "$artifact_path" --enforce-deps
expect_success "src/run/dispatch enforce-deps accepts completed dependency set" "$RUN_DISPATCH" t2 --plan "$artifact_path" --enforce-deps --completed-target h1 --completed-target c1 --completed-target c2 --completed-target c3 --completed-target t1
expect_failure "src/run/dispatch enforce-policy-gates fails without approvals" "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforce-policy-gates
expect_success "src/run/dispatch enforce-policy-gates accepts approved gates" "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforce-policy-gates --allow-gate gate_network --allow-gate gate_storage
expect_success "src/run/dispatch enforce-policy-gates accepts env approved gates" env LAB_RUN_ALLOWED_POLICY_GATES="gate_network gate_storage" "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforce-policy-gates
expect_failure "src/run/dispatch rejects invalid gate evidence format" "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforcement-stage strict --gate-evidence "$invalid_gate_evidence_format_path"
expect_failure "src/run/dispatch rejects gate evidence target mismatch" "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforcement-stage strict --gate-evidence "$invalid_gate_evidence_target_path"
expect_failure "src/run/dispatch rejects invalid gate evidence token" "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforcement-stage strict --gate-evidence "$invalid_gate_evidence_token_path"
expect_success "src/run/dispatch consumes producer gate evidence in strict stage" env LAB_RUN_ENFORCEMENT_STAGE=strict "$RUN_DISPATCH" h1 --plan "$artifact_path" --gate-evidence "$produced_gate_evidence_h1_path"
expect_success "src/run/dispatch enforce-order accepts valid ordering" "$RUN_DISPATCH" t2 --plan "$artifact_path" --enforce-order --completed-target h1 --completed-target c1 --completed-target c2 --completed-target c3 --completed-target t1
expect_failure "src/run/dispatch guarded stage fails without completed targets" env LAB_RUN_ENFORCEMENT_STAGE=guarded "$RUN_DISPATCH" t2 --plan "$artifact_path"
expect_success "src/run/dispatch guarded stage uses env completed targets" env LAB_RUN_ENFORCEMENT_STAGE=guarded LAB_RUN_COMPLETED_TARGETS="h1 c1 c2 c3 t1" "$RUN_DISPATCH" t2 --plan "$artifact_path"
expect_failure "src/run/dispatch strict stage fails without approved gates" env LAB_RUN_ENFORCEMENT_STAGE=strict LAB_RUN_COMPLETED_TARGETS="h1 c1 c2 c3 t1" "$RUN_DISPATCH" h1 --plan "$artifact_path"
expect_success "src/run/dispatch strict stage passes with approved gates" env LAB_RUN_ENFORCEMENT_STAGE=strict LAB_RUN_COMPLETED_TARGETS="h1 c1 c2 c3 t1" LAB_RUN_ALLOWED_POLICY_GATES="gate_network gate_storage" "$RUN_DISPATCH" h1 --plan "$artifact_path"
expect_success "src/run/dispatch strict stage passes with gate evidence" env LAB_RUN_ENFORCEMENT_STAGE=strict "$RUN_DISPATCH" h1 --plan "$artifact_path" --gate-evidence "$gate_evidence_h1_path"
expect_success "src/run/dispatch strict stage loads env gate evidence" env LAB_RUN_ENFORCEMENT_STAGE=strict LAB_RUN_GATE_EVIDENCE_FILE="$gate_evidence_h1_path" "$RUN_DISPATCH" h1 --plan "$artifact_path"
expect_failure "src/run/dispatch strict stage on t2 requires dependency context" env LAB_RUN_ENFORCEMENT_STAGE=strict "$RUN_DISPATCH" t2 --plan "$artifact_path" --gate-evidence "$gate_evidence_t2_path"
expect_success "src/run/dispatch strict stage on t2 passes with evidence and dependency context" env LAB_RUN_ENFORCEMENT_STAGE=strict LAB_RUN_COMPLETED_TARGETS="h1 c1 c2 c3 t1" "$RUN_DISPATCH" t2 --plan "$artifact_path" --gate-evidence "$gate_evidence_t2_path"
expect_failure "src/run/dispatch uses plan guarded stage for t2 by default" "$RUN_DISPATCH" t2 --plan "$artifact_path"
expect_success "src/run/dispatch plan guarded stage passes with env completion context" env LAB_RUN_COMPLETED_TARGETS="h1 c1 c2 c3 t1" "$RUN_DISPATCH" t2 --plan "$artifact_path"

artifact_strict_stage_path="${tmpdir}/compile-stage-strict.plan"
while IFS= read -r line; do
    case "$line" in
        target_1_enforcement_stage=*)
            printf 'target_1_enforcement_stage=strict\n' >> "$artifact_strict_stage_path"
            ;;
        *)
            printf '%s\n' "$line" >> "$artifact_strict_stage_path"
            ;;
    esac
done < "$artifact_path"
expect_failure "src/run/dispatch honors plan target enforcement stage" "$RUN_DISPATCH" h1 --plan "$artifact_strict_stage_path"
expect_success "src/run/dispatch plan target enforcement stage passes with gates" "$RUN_DISPATCH" h1 --plan "$artifact_strict_stage_path" --allow-gate gate_network --allow-gate gate_storage
expect_success "src/run/dispatch env stage overrides plan stage" env LAB_RUN_ENFORCEMENT_STAGE=compat "$RUN_DISPATCH" h1 --plan "$artifact_strict_stage_path"
expect_failure "src/run/dispatch cli stage overrides env stage" env LAB_RUN_ENFORCEMENT_STAGE=compat "$RUN_DISPATCH" h1 --plan "$artifact_path" --enforcement-stage strict

artifact_missing_sections_path="${tmpdir}/compile-missing-sections.plan"
while IFS= read -r line; do
    case "$line" in
        target_*_sections=*)
            continue
            ;;
    esac
    printf '%s\n' "$line" >> "$artifact_missing_sections_path"
done < "$artifact_path"
expect_failure "src/run/dispatch rejects artifact without section metadata" "$RUN_DISPATCH" h1 --plan "$artifact_missing_sections_path" -x a

artifact_order_violation_path="${tmpdir}/compile-order-violation.plan"
while IFS= read -r line; do
    case "$line" in
        target_1_order=*)
            printf 'target_1_order=999\n' >> "$artifact_order_violation_path"
            ;;
        *)
            printf '%s\n' "$line" >> "$artifact_order_violation_path"
            ;;
    esac
done < "$artifact_path"
expect_failure "src/run/dispatch enforce-order rejects dependency order violations" "$RUN_DISPATCH" t2 --plan "$artifact_order_violation_path" --enforce-order

invalid_dcl_unknown_dep="${tmpdir}/dcl-unknown-dep"
mkdir -p "$invalid_dcl_unknown_dep"
cat > "${invalid_dcl_unknown_dep}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1" "c1")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
    ["c1"]="a_xall"
)
declare -A -g DCL_TARGET_DEPENDS_ON=(
    ["h1"]=""
    ["c1"]="missing-target"
)
EOF
expect_failure "src/rec/ops validate rejects unknown dependency target" "$REC_OPS" validate --dcl-root "$invalid_dcl_unknown_dep"

invalid_dcl_cycle="${tmpdir}/dcl-cycle"
mkdir -p "$invalid_dcl_cycle"
cat > "${invalid_dcl_cycle}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1" "c1")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
    ["c1"]="a_xall"
)
declare -A -g DCL_TARGET_DEPENDS_ON=(
    ["h1"]="c1"
    ["c1"]="h1"
)
EOF
expect_failure "src/rec/ops validate rejects dependency cycles" "$REC_OPS" validate --dcl-root "$invalid_dcl_cycle"

invalid_dcl_order="${tmpdir}/dcl-duplicate-order"
mkdir -p "$invalid_dcl_order"
cat > "${invalid_dcl_order}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1" "c1")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
    ["c1"]="a_xall"
)
declare -A -g DCL_TARGET_ORDER=(
    ["h1"]="10"
    ["c1"]="10"
)
EOF
expect_failure "src/rec/ops validate rejects duplicate target order" "$REC_OPS" validate --dcl-root "$invalid_dcl_order"

invalid_dcl_default_stage="${tmpdir}/dcl-invalid-default-stage"
mkdir -p "$invalid_dcl_default_stage"
cat > "${invalid_dcl_default_stage}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
DCL_ENFORCEMENT_STAGE_DEFAULT="invalid"
declare -a -g DCL_TARGETS=("h1")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
)
EOF
expect_failure "src/rec/ops validate rejects invalid default enforcement stage" "$REC_OPS" validate --dcl-root "$invalid_dcl_default_stage"

invalid_dcl_target_stage="${tmpdir}/dcl-invalid-target-stage"
mkdir -p "$invalid_dcl_target_stage"
cat > "${invalid_dcl_target_stage}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
)
declare -A -g DCL_TARGET_ENFORCEMENT_STAGE=(
    ["h1"]="invalid"
)
EOF
expect_failure "src/rec/ops validate rejects invalid target enforcement stage" "$REC_OPS" validate --dcl-root "$invalid_dcl_target_stage"

invalid_dcl_strict_missing_gates="${tmpdir}/dcl-strict-missing-gates"
mkdir -p "$invalid_dcl_strict_missing_gates"
cat > "${invalid_dcl_strict_missing_gates}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1" "t2")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
    ["t2"]="a_xall"
)
declare -A -g DCL_TARGET_ORDER=(
    ["h1"]="10"
    ["t2"]="20"
)
declare -A -g DCL_TARGET_DEPENDS_ON=(
    ["h1"]=""
    ["t2"]="h1"
)
declare -A -g DCL_TARGET_POLICY_GATES=(
    ["h1"]="gate_network"
)
declare -A -g DCL_TARGET_ENFORCEMENT_STAGE=(
    ["h1"]="compat"
    ["t2"]="strict"
)
EOF
expect_failure "src/rec/ops validate rejects strict target without policy gates" "$REC_OPS" validate --dcl-root "$invalid_dcl_strict_missing_gates"

invalid_dcl_strict_missing_depends="${tmpdir}/dcl-strict-missing-depends"
mkdir -p "$invalid_dcl_strict_missing_depends"
cat > "${invalid_dcl_strict_missing_depends}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1" "t2")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
    ["t2"]="a_xall"
)
declare -A -g DCL_TARGET_ORDER=(
    ["h1"]="10"
    ["t2"]="20"
)
declare -A -g DCL_TARGET_DEPENDS_ON=(
    ["h1"]=""
    ["t2"]=""
)
declare -A -g DCL_TARGET_POLICY_GATES=(
    ["h1"]="gate_network"
    ["t2"]="gate_network gate_access"
)
declare -A -g DCL_TARGET_ENFORCEMENT_STAGE=(
    ["h1"]="compat"
    ["t2"]="strict"
)
EOF
expect_failure "src/rec/ops validate rejects strict target without dependency context" "$REC_OPS" validate --dcl-root "$invalid_dcl_strict_missing_depends"

invalid_dcl_strict_missing_order="${tmpdir}/dcl-strict-missing-order"
mkdir -p "$invalid_dcl_strict_missing_order"
cat > "${invalid_dcl_strict_missing_order}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1" "t2")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
    ["t2"]="a_xall"
)
declare -A -g DCL_TARGET_DEPENDS_ON=(
    ["h1"]=""
    ["t2"]="h1"
)
declare -A -g DCL_TARGET_POLICY_GATES=(
    ["h1"]="gate_network"
    ["t2"]="gate_network gate_access"
)
declare -A -g DCL_TARGET_ENFORCEMENT_STAGE=(
    ["h1"]="compat"
    ["t2"]="strict"
)
EOF
expect_failure "src/rec/ops validate rejects strict target without order metadata" "$REC_OPS" validate --dcl-root "$invalid_dcl_strict_missing_order"

valid_dcl_strict_target="${tmpdir}/dcl-strict-valid"
mkdir -p "$valid_dcl_strict_target"
cat > "${valid_dcl_strict_target}/site" <<'EOF'
#!/bin/bash
DCL_SITE_NAME="test"
DCL_PROFILE="base"
declare -a -g DCL_TARGETS=("h1" "t2")
declare -A -g DCL_TARGET_SECTIONS=(
    ["h1"]="a_xall"
    ["t2"]="a_xall"
)
declare -A -g DCL_TARGET_ORDER=(
    ["h1"]="10"
    ["t2"]="20"
)
declare -A -g DCL_TARGET_DEPENDS_ON=(
    ["h1"]=""
    ["t2"]="h1"
)
declare -A -g DCL_TARGET_POLICY_GATES=(
    ["h1"]="gate_network"
    ["t2"]="gate_network gate_access"
)
declare -A -g DCL_TARGET_ENFORCEMENT_STAGE=(
    ["h1"]="compat"
    ["t2"]="strict"
)
EOF
expect_success "src/rec/ops validate accepts strict target with promotion metadata" "$REC_OPS" validate --dcl-root "$valid_dcl_strict_target"

expect_success "ops reconcile preflight succeeds for declared target" env LAB_ROOT="$LAB_ROOT" OPS_EXECUTION_MODE=reconcile LAB_REC_TARGET=h1 bash -c 'source "$1"; ops_reconcile_preflight' _ "$LAB_ROOT/src/dic/ops"
expect_failure "ops reconcile preflight rejects undeclared target" env LAB_ROOT="$LAB_ROOT" OPS_EXECUTION_MODE=reconcile LAB_REC_TARGET=unknown-target bash -c 'source "$1"; ops_reconcile_preflight' _ "$LAB_ROOT/src/dic/ops"
expect_success "ops runtime flag enables reconcile mode" env LAB_ROOT="$LAB_ROOT" bash -c 'source "$1"; OPS_EXECUTION_MODE=direct; ops_main --reconcile --help >/dev/null 2>&1 && [[ "$OPS_EXECUTION_MODE" == "reconcile" ]]' _ "$LAB_ROOT/src/dic/ops"
expect_success "ops runtime flag enables direct mode" env LAB_ROOT="$LAB_ROOT" bash -c 'source "$1"; OPS_EXECUTION_MODE=reconcile; ops_main --direct --help >/dev/null 2>&1 && [[ "$OPS_EXECUTION_MODE" == "direct" ]]' _ "$LAB_ROOT/src/dic/ops"
expect_success "ops runtime flag sets reconcile target" env LAB_ROOT="$LAB_ROOT" bash -c 'source "$1"; unset OPS_REC_TARGET; ops_main --rec-target h1 --help >/dev/null 2>&1 && [[ "${OPS_REC_TARGET:-}" == "h1" ]]' _ "$LAB_ROOT/src/dic/ops"
expect_failure "ops runtime flag rejects missing reconcile target" env LAB_ROOT="$LAB_ROOT" bash -c 'source "$1"; ops_main --rec-target --help >/dev/null 2>&1' _ "$LAB_ROOT/src/dic/ops"

expect_success "src/dic/run bridge remains callable" "$REC_RUN_BRIDGE" h1
expect_failure "src/dic/run rejects missing gate evidence value" "$REC_RUN_BRIDGE" h1 --gate-evidence
expect_failure "src/dic/run applies plan guarded stage for t2" "$REC_RUN_BRIDGE" t2
expect_success "src/dic/run plan guarded stage passes with env completion context" env LAB_RUN_COMPLETED_TARGETS="h1 c1 c2 c3 t1" "$REC_RUN_BRIDGE" t2
expect_failure "src/dic/run forwards strict dependency enforcement failures" env -u LAB_RUN_COMPLETED_TARGETS "$REC_RUN_BRIDGE" t2 --enforce-deps
expect_success "src/dic/run forwards strict dependency enforcement inputs" "$REC_RUN_BRIDGE" t2 --enforce-deps --completed-target h1 --completed-target c1 --completed-target c2 --completed-target c3 --completed-target t1
expect_success "src/dic/run forwards strict gate evidence for h1" "$REC_RUN_BRIDGE" h1 --enforcement-stage strict --gate-evidence "$gate_evidence_h1_path"
expect_failure "src/dic/run strict gate evidence for t2 still requires dependency context" "$REC_RUN_BRIDGE" t2 --enforcement-stage strict --gate-evidence "$gate_evidence_t2_path"
expect_success "src/dic/run forwards strict gate evidence with dependency context" "$REC_RUN_BRIDGE" t2 --enforcement-stage strict --gate-evidence "$gate_evidence_t2_path" --completed-target h1 --completed-target c1 --completed-target c2 --completed-target c3 --completed-target t1
expect_success "src/set/h1 supports opt-in dic bridge" env LAB_USE_DIC_RUN_BRIDGE=1 "$SET_H1"
expect_success "legacy src/set/h1 entrypoint remains callable" "$SET_H1"

rm -rf "$tmpdir"

if [[ "$fail_count" -ne 0 ]]; then
    printf 'Contract test failed with %s issue(s)\n' "$fail_count"
    exit 1
fi

printf 'Contract test passed\n'
exit 0
