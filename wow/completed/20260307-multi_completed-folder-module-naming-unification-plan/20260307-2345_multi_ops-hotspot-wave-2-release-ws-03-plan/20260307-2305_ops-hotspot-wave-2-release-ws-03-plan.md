# Ops Hotspot Wave 2 Release WS-03 Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 23:45
- Links: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2345_multi_ops-hotspot-wave-2-release-program-plan/20260307-2048_ops-hotspot-wave-2-release-program-plan.md, val/run_all_tests.sh, doc/ref/functions.md, doc/ref/test-coverage.md

## Goal

Integrate Wave 2 workstream outputs, run convergence validation gates, and
prepare the explicit release decision for the parent program plan.

## Context

1. WS-03 depends on completion of WS-01 and WS-02.
2. This workstream owns integration-gate evidence and release posture framing.
3. Documentation alignment is required for function and coverage references.
4. WS-01 completed render-path seam extraction and recorded interface notes for
   TSV row boundaries.
5. WS-02 completed device-flow discovery boundary extraction and refreshed
   dependency reference inputs.
6. Integration validation and reference-doc refresh are the final gate inputs
   before the parent release decision can be finalized.

## Scope

1. Aggregate child outputs and resolve integration-level boundary issues.
2. Run integration-oriented validation evidence for Wave 2 readiness.
3. Draft release decision inputs (`release now` or `hold`) for parent closeout.

## Triage Decision

- Why now: release gating cannot complete until integration evidence is
  consolidated in one workstream.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: integration and release decision framing determine whether Wave
  2 can safely proceed or must hold.

## Documentation Impact

Docs: required

## Orchestration Metadata

- Program: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2345_multi_ops-hotspot-wave-2-release-program-plan/20260307-2048_ops-hotspot-wave-2-release-program-plan.md
- Workstream-ID: WS-03
- Depends-On: WS-01,WS-02
- Touch-Set: wow/active/20260307-2048_ops-hotspot-wave-2-release-program-plan.md::release-decision; val/run_all_tests.sh::lib-category; doc/ref/functions.md; doc/ref/test-coverage.md
- Merge-Gate: integration
- Branch: ws/ops-hotspot-wave2-ws-03-integration
- Worktree: /home/es/lab

## Execution Plan

1. Step 1 (completed): collect WS-01 and WS-02 checkpoints and integration
   deltas.
   Completion criterion: upstream checkpoints are summarized with overlap and
   blocker status.
2. Step 2 (completed): execute integration-gate validation and capture
   evidence.
   Completion criterion: `bash -n` checks, `./val/run_all_tests.sh lib`, and
   docs regeneration outcomes are recorded.
3. Step 3 (completed): draft and record release decision recommendations for
   parent convergence.
   Completion criterion: parent item has explicit release recommendation input
   with owner actions and blocker posture.

## Verification Plan

1. Run `bash -n` on edited Bash files.
2. Run `./val/run_all_tests.sh lib` for integration-level library confidence.
3. Verify documentation updates are recorded for `doc/ref/functions.md` and
   `doc/ref/test-coverage.md`.
4. Run `./utl/ref/run_all_doc.sh` when structural/public surfaces change and
   record the result in evidence.

## Exit Criteria

- Integration validation evidence is complete and captured.
- Release recommendation input is ready for parent convergence decision.
- Documentation updates and checkpoint evidence are recorded.

## Integration Findings

1. WS-01 delta: render-path decomposition in `lib/ops/dev` introduced
   `_dev_osv_collect_rows_tsv` and `_dev_osv_render_table_from_tsv`, with
   `_dev_osv_render` reduced to orchestration behavior.
2. WS-02 delta: device-flow decomposition introduced
   `_dev_prepare_device_flow_context`, with `dev_oaa`, `dev_oas`, `dev_oar`,
   and `dev_oad` consuming shared discovery/preflight logic.
3. Integration boundary outcome: no scope collision was observed between WS-01
   render-path seams and WS-02 device-flow seams; both streams preserve
   command signatures for downstream compatibility.
4. Validation evidence: `bash -n lib/ops/dev`,
   `bash -n val/lib/ops/dev_test.sh`, and `./val/run_all_tests.sh lib`
   completed successfully (28/28 lib suites passed).
5. Documentation evidence: `./utl/ref/run_all_doc.sh` completed successfully,
   and references now include updated function metadata and coverage mapping in
   `doc/ref/functions.md` and `doc/ref/test-coverage.md`.

## Release Recommendation Input

- Recommendation: release now.
- Rationale: all dependent workstreams completed, integration validation passed,
  and required documentation artifacts were refreshed in the same execution
  window.
- Blockers: none.
- Owner actions for parent convergence:
  1. Mark WS-03 state as `done` in the parent workstream table.
  2. Finalize parent release decision language as `release now`.
  3. Proceed to parent close/converge workflow if no new regressions appear.

## Progress Checkpoint

### Done

- Collected WS-01 and WS-02 completion checkpoints and integration deltas.
- Verified integration boundaries are non-overlapping and signature-compatible.
- Ran integration validation gates:
  `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
  `./val/run_all_tests.sh lib` (suite result: 28 passed, 0 failed).
- Regenerated reference docs with `./utl/ref/run_all_doc.sh` and confirmed
  required references (`doc/ref/functions.md`, `doc/ref/test-coverage.md`)
  were updated.
- Recorded `release now` recommendation input for parent convergence.

### In-flight

- None.

### Blockers

- None.

### Next steps

1. Run `wow/task/active-sync` to roll WS-03 completion evidence into the
   parent program item.
2. Finalize parent `release now` decision block and close/converge when ready.

## What changed

1. Closed this WS-03 item from `wow/active/` to
   `wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2345_multi_ops-hotspot-wave-2-release-ws-03-plan/`.
2. Preserved finalized integration findings and release recommendation input
   (`release now`) for parent convergence evidence.
3. Documentation files updated in this workstream:
   `doc/ref/functions.md`, `doc/ref/test-coverage.md`.

## What was verified

1. Integration validation evidence remained green from WS-03 checkpoint:
   `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
   `./val/run_all_tests.sh lib` (`28/28 suites passed`, `0 failed`).
2. Structural/reference doc regeneration completed with
   `./utl/ref/run_all_doc.sh` and outputs recorded in WS-03 findings.
3. Docs: updated (`doc/ref/functions.md`, `doc/ref/test-coverage.md`).

## What remains

1. No WS-03-local follow-up is required.
2. Parent close workflow archives wave-level release decision evidence.
