# Lib Confidence Gate Implementation Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 11:03
- Links: wow/task/completed-close, wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, doc/ref/test-coverage.md, doc/ref/stats/actual.md, val/run_all_tests.sh, val/lib/confidence_gate.sh, val/core/confidence_gate_test.sh, AGENTS.md, wow/README.md, doc/man/09-wow-workflow-board.md, wow/queue/20260307-1047_gen-aux-helper-contract-stabilization-plan.md, wow/inbox/20260307-1047_ops-hotspot-decomposition-wave-plan.md, wow/inbox/20260307-1047_ops-bootstrap-boundary-decoupling-plan.md

## Goal

Define and implement a confidence gate for architecture-sensitive `lib/`
changes so release decisions have explicit verification criteria.

## Context

1. The architecture review identified a gap between mapped test traceability and
   explicit confidence/run-status gating.
2. High-fan-in and high-complexity modules require stronger acceptance rules to
   reduce regression risk.
3. This follow-up is selected for immediate execution as a dedicated active
   track.

## Scope

1. Define minimum required checks by change risk class.
2. Specify pass/fail gate semantics and waiver handling.
3. Integrate gate expectations into workflow/docs and validation practice.
4. Add targeted regression checks for the confidence-gate policy.

## Triage Decision

- Why now: confidence gating is a prerequisite for safely executing the next
  architecture-hardening wave.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: There are multiple gating models and thresholds, and the
  selected model affects acceptance policy across all future lib changes.

## Next Step

Run the confidence gate on upcoming architecture-sensitive `lib/` work items and
close this item once adoption guidance is captured.

## Phase 1 Design Deliverable

### Interfaces

1. Input interface: `./val/lib/confidence_gate.sh --risk <low|medium|high> <changed-file>...`.
2. Output interface: deterministic required-check list and explicit pass/fail
   process result (or dry-run preview).

### Constraints

1. Gate behavior must be non-destructive and rely on existing repository
   validation entrypoints.
2. Policy must be deterministic from risk class plus changed file set.
3. Guidance must be documented in both operator workflow and agent operating
   instructions.

### Trade-offs

1. Stricter gate levels increase confidence but increase cycle time.
2. Module-targeted checks are faster but may miss cross-module regressions.
3. Full-suite enforcement is strongest for safety but should be reserved for
   high-risk changes.

### Chosen policy

1. `low`: syntax checks + nearest module tests (or quick lib-suite fallback).
2. `medium`: `low` + full `lib` category suite.
3. `high`: `medium` + full repository suite.
4. Waivers are temporary and must be tracked via `wow/active/waivers/` with
   owner, expiry, and removal criteria.

## Progress Checkpoint

### Done

1. Added confidence-gate runner `val/lib/confidence_gate.sh` with risk-class
   command selection, dry-run support, and pass/fail execution semantics.
2. Added targeted regression tests in `val/core/confidence_gate_test.sh` for
   argument validation and risk matrix behavior.
3. Documented confidence-gate usage and risk levels in `AGENTS.md`.
4. Added operator workflow guidance in `wow/README.md` and
   `doc/man/09-wow-workflow-board.md`.
5. Ran verification: `bash -n val/lib/confidence_gate.sh val/core/confidence_gate_test.sh`,
   `bash val/core/confidence_gate_test.sh`, `bash val/core/agents_md_test.sh`,
   and `bash wow/check-workflow.sh` (all passed).
6. Ran dry-run acceptance previews across risk classes:
   `bash val/lib/confidence_gate.sh --risk low|medium|high --dry-run lib/ops/ssh`.

### In-flight

1. Adoption follow-through on subsequent active `lib/` hardening items.

### Blockers

1. None.

### Next steps

1. Apply `./val/lib/confidence_gate.sh` to the next `lib/` architecture item
   before closeout.
2. Capture any practical friction as follow-up calibration items.

## Execution Plan

1. Phase 1 (Design) [complete]: Define confidence-gate interfaces, constraints, trade-offs,
   and chosen policy before implementation; completion criterion: a concrete
   design brief is documented with risk classes, mandatory checks, waiver model,
   and pass/fail semantics.
2. Phase 2 (Implementation) [complete]: Apply the chosen gate policy to workflow and
   validation surfaces; completion criterion: policy logic and documentation are
   updated in-repo and aligned to the Phase 1 design.
3. Phase 3 (Verification) [complete]: Validate gate behavior with targeted tests/checks and
   sample acceptance scenarios; completion criterion: verification evidence
   confirms expected pass/fail outcomes across defined risk classes.

## Verification Plan

1. Verify policy/docs consistency across workflow guidance and validation entrypoints.
2. Run syntax checks and targeted validation tests for edited scripts/docs.
3. Run `bash wow/check-workflow.sh` and confirm workflow artifacts remain valid.

## Exit Criteria

1. [met] Confidence-gate policy is explicitly defined and documented.
2. [met] Gate behavior is implemented and validated for architecture-sensitive changes.
3. [met] Contributors can determine go/no-go decisions from clear, repeatable criteria.

## What changed

1. Added confidence-gate runner `val/lib/confidence_gate.sh` with risk-class matrix (`low|medium|high`), dry-run preview mode, and deterministic pass/fail execution flow.
2. Added regression coverage in `val/core/confidence_gate_test.sh` for argument validation and risk-class command selection behavior.
3. Updated guidance in `AGENTS.md`, `wow/README.md`, and `doc/man/09-wow-workflow-board.md` so contributors and operators can apply the gate consistently.

## What was verified

1. `bash -n val/lib/confidence_gate.sh val/core/confidence_gate_test.sh` passed.
2. `bash val/core/confidence_gate_test.sh` passed (4 tests, 0 failures).
3. `bash val/core/agents_md_test.sh` passed (59 tests, 0 failures).
4. `bash wow/check-workflow.sh` passed.
5. Dry-run acceptance previews produced expected risk-class command sets:
   - `bash val/lib/confidence_gate.sh --risk low --dry-run lib/ops/ssh`
   - `bash val/lib/confidence_gate.sh --risk medium --dry-run lib/ops/ssh`
   - `bash val/lib/confidence_gate.sh --risk high --dry-run lib/ops/ssh`

## What remains

1. Mandatory queued follow-up: `wow/queue/20260307-1047_gen-aux-helper-contract-stabilization-plan.md`.
2. Routing: queue (mandatory follow-up)
3. Rationale: helper-contract stabilization is the highest-risk dependency surface and should consume the new confidence gate immediately.
4. Additional follow-ups in inbox: `wow/inbox/20260307-1047_ops-hotspot-decomposition-wave-plan.md` and `wow/inbox/20260307-1047_ops-bootstrap-boundary-decoupling-plan.md`.
