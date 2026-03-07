# Ops Hotspot Decomposition Wave Program Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 21:03
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1548_ops-hotspot-decomposition-wave-design.md, wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1630_ops-hotspot-gpu-ws-01-plan.md, wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1630_ops-hotspot-ana-ws-02-plan.md, wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1630_ops-hotspot-verification-ws-03-plan.md, wow/inbox/20260307-2048_ops-hotspot-wave-2-release-followup.md, lib/ops/gpu, val/lib/ops/gpu_test.sh, val/lib/ops/gpu_std_compliance_test.sh, doc/ref/functions.md, doc/ref/stats/actual.md, doc/ref/scope-integrity.md, doc/ref/test-coverage.md

## Goal

Decompose top `lib/ops` and `lib/gen` complexity hotspots into safer,
smaller units while preserving public behavior.

## Context

1. The architecture review highlighted concentrated complexity in modules such
   as `ops/dev`, `ops/gpu`, and `gen/ana`.
2. Large-function and mutation hotspots increase maintenance and regression
   risk during infrastructure automation changes.
3. A staged decomposition wave is needed but still requires detailed batching
   and sequencing design.
4. Current complexity telemetry shows the largest function concentration in
   `_dev_osv_render` (894 lines), `gpu_ptp` (549 lines), and `ana_acu`
   (531 lines), confirming hotspot-first decomposition priority.
5. Coverage mapping already provides nearest regression targets for these
   modules (`val/lib/ops/dev_test.sh`, `val/lib/ops/gpu_test.sh`,
   `val/lib/gen/ana_*_test.sh`), which can anchor phase-level compatibility
   gates.
6. Wave 1 Batch A has started in `lib/ops/gpu` with `gpu_ptp` decomposed into
   shared step helpers to reduce internal duplication while keeping external
   command interfaces stable.
7. Batch A verification snapshot: `bash -n lib/ops/gpu`,
   `./val/lib/ops/gpu_test.sh`, and `./val/lib/ops/gpu_std_compliance_test.sh`
   all passed after the first decomposition slice.

## Scope

1. Define hotspot decomposition batches and execution order.
2. Preserve externally visible function contracts during decomposition.
3. Add/expand targeted tests for decomposed areas.
4. Capture migration and rollback strategy for high-risk modules.

## Program Scope

1. Execute Wave 1 hotspot decomposition through parallelized module workstreams.
2. Preserve public contracts across `lib/ops/gpu` and `lib/gen/ana` while
   reducing hotspot complexity.
3. Converge all workstream outputs through compatibility verification and
   rollback hardening before closeout.

## Global Invariants

1. Public signatures in the Wave 1 baseline matrix remain unchanged.
2. Workstream `Touch-Set` boundaries remain non-overlapping within a wave.
3. Dependency ordering remains acyclic and explicit in `Depends-On`.
4. No workstream can be marked done without its declared merge-gate evidence.

## Workstreams

| Workstream-ID | Scope | Depends-On | Touch-Set | Merge-Gate | Child-Plan | State | Blocker Summary | Next Owner Action |
|---|---|---|---|---|---|---|---|---|
| WS-01 | Wave 1 Batch A GPU decomposition | none | lib/ops/gpu,val/lib/ops/gpu_test.sh,val/lib/ops/gpu_std_compliance_test.sh | module | wow/active/20260307-1630_ops-hotspot-gpu-ws-01-plan.md | done | none reported in child progress checkpoint; execution phases complete | keep closed at workstream level and include in program closeout evidence |
| WS-02 | Wave 1 Batch B analyzer decomposition | none | lib/gen/ana,val/lib/gen/ana_dep_test.sh,val/lib/gen/ana_err_test.sh,val/lib/gen/ana_rdp_test.sh,val/lib/gen/ana_scp_test.sh,val/lib/gen/ana_tst_test.sh | module | wow/active/20260307-1630_ops-hotspot-ana-ws-02-plan.md | done | none reported in child progress checkpoint; execution phases complete | keep closed at workstream level and include in program closeout evidence |
| WS-03 | Wave 1 compatibility verification and rollback hardening | WS-01,WS-02 | wow/active/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md,val/lib/confidence_gate.sh | integration | wow/active/20260307-1630_ops-hotspot-verification-ws-03-plan.md | done | no pending dependencies (WS-01, WS-02 complete); no blockers reported | converged in Wave 1 log; track Wave 2 release preparation via inbox follow-up |

## Sync Snapshot

- Timestamp: 2026-03-07 20:31
- Completed items this sync:
  - WS-01 confirmed complete from child `## Execution Plan` (all phases done).
  - WS-02 confirmed complete from child `## Execution Plan` (all phases done).
  - WS-03 confirmed complete from child `## Execution Plan` and confidence-gate evidence.
- Blocked items and reason:
  - none.
- Ready-to-converge candidates:
  - WS-01, WS-02, WS-03 (all workstreams are in `done` state).

## Convergence Log

### Wave 1 -- 2026-03-07 20:48

1. Converged workstreams: WS-01, WS-02, WS-03.
2. Merge-gate evidence validated:
   - WS-01 (`module`): child plan reports all execution phases done and passing
     `bash -n lib/ops/gpu`, `./val/lib/ops/gpu_test.sh`, and
     `./val/lib/ops/gpu_std_compliance_test.sh`.
   - WS-02 (`module`): child plan reports all execution phases done and passing
     analyzer suites plus `./val/core/ref_pipeline_parity_test.sh` after
     `./utl/ref/run_all_doc.sh`.
   - WS-03 (`integration`): child plan reports all execution phases done and
     passing `./val/lib/confidence_gate.sh --risk medium lib/ops/gpu lib/gen/ana`.
3. Integration checks run:
   - `./val/lib/confidence_gate.sh --risk medium lib/ops/gpu lib/gen/ana`
     (passed: 28/28, failed: 0).
   - Wave 1 signature matrix compatibility confirmation for `gpu_ptp`,
     `gpu_ptd`, `gpu_pta`, `gpu_pts`, `ana_acu`, and `ana_lad`.
4. Unresolved conflicts or blockers: none.
5. Next wave release decision: Wave 1 is converged; Wave 2 is not auto-released
   in this pass. Capture Wave 2 scope kickoff as an inbox follow-up.
   Follow-up: `wow/inbox/20260307-2048_ops-hotspot-wave-2-release-followup.md`.

## Integration Cadence

1. Wave 1 opens with WS-01 and WS-02 in parallel.
2. WS-03 begins after both module workstreams satisfy module-gate checks.
3. Program convergence is allowed only after integration-gate verification is
   recorded in this parent.

## Risks

1. Partial decomposition can increase temporary complexity if batching is poor.
2. Behavior drift can occur without explicit compatibility and regression gates.
3. Large patchsets can delay review and reduce delivery confidence.

## Triage Decision

- Why now: The architecture review already identified high-risk hotspots, so
  triaging this decomposition wave now prevents additional unsafe growth in the
  most complex ops/gen modules.
- Design classification Q1 (meaningful alternatives): Yes -- batching,
  sequencing, and rollback design choices materially affect implementation
  safety and reviewability.
- Design classification Q2 (output shape dependencies): Yes -- downstream
  maintainers and test plans depend on stable decomposition boundaries and
  documented compatibility gates.
- Design: required
- Justification: Both the decomposition strategy and its artifacts directly
  influence how future implementation waves are executed and validated.

## Documentation Impact

- Docs: required
- Target docs (initial): `doc/ref/functions.md`, `doc/ref/module-dependencies.md`,
  `doc/ref/test-coverage.md`, `doc/ref/scope-integrity.md`,
  `doc/ref/error-handling.md`, `doc/ref/stats/actual.md`

## Next Step

Use the Wave 1 convergence record as release evidence and advance the Wave 2
hotspot kickoff from inbox triage.

## Execution Plan

1. [done] Phase 1 - Decomposition design baseline.
   Completion criterion: `wow/active/20260307-1047_ops-hotspot-decomposition-wave-design.md`
   is created with documented interfaces, constraints, trade-offs, and the
   chosen hotspot decomposition approach.
2. [done] Phase 2 - Wave 1 decomposition implementation.
   Completion criterion: The modules assigned to Wave 1 are decomposed with
   unchanged public function signatures, documented in a before/after signature
   matrix attached to this plan.
3. [done] Phase 3 - Compatibility verification and rollback hardening.
   Completion criterion: A verification record is added to this plan showing
   passing targeted tests for touched hotspots and rollback steps for each
   high-risk module.

## Wave 1 Signature Matrix (Baseline)

| Module | Public Function | Baseline Signature |
|---|---|---|
| `lib/ops/gpu` | `gpu_ptp` | `<step> [action] [--no-reboot]` |
| `lib/ops/gpu` | `gpu_ptd` | `[-d driver] [gpu_id] [hostname] [config_file] [pci0_id] [pci1_id]` |
| `lib/ops/gpu` | `gpu_pta` | `[-d driver] [gpu_id] [hostname] [config_file] [pci0_id] [pci1_id]` |
| `lib/ops/gpu` | `gpu_pts` | `-x (execute)` |
| `lib/gen/ana` | `ana_acu` | `[-o|-a|-j|-t|-b|--json-dir <dir>] <config file or directory> <target folder1> [target folder2 ...]` |
| `lib/gen/ana` | `ana_lad` | `<file/directory name> [-t] [-b] [-j]` |

## Phase 2 Progress Log

1. Batch A slice 1 completed: `gpu_ptp` was decomposed into internal helpers
   (`_gpu_ptp_apply_step1`, `_gpu_ptp_apply_step2`, `_gpu_ptp_apply_step3`)
   to collapse repeated logic across `all` and single-step execution paths.
2. Public interface check: `gpu_ptp`, `gpu_ptd`, `gpu_pta`, and `gpu_pts`
   signatures remain unchanged from the baseline matrix.
3. Verification check: syntax and nearest module tests passed for this slice
   (`bash -n lib/ops/gpu`, `./val/lib/ops/gpu_test.sh`,
   `./val/lib/ops/gpu_std_compliance_test.sh`).
4. Batch A slice 2 completed: `gpu_ptd`/`gpu_pta` were decomposed by extracting
   shared detach/attach internals (`_gpu_parse_driver_mode_args`,
   `_gpu_validate_passthrough_driver_mode`, `_gpu_check_passthrough_dependencies`)
   plus focused per-device helpers for detach, attach, and post-attach NVIDIA
   framebuffer handling.
5. Before/after note for slice 2: repeated parse/validation and side-effect
   blocks were inline in both public functions before extraction; after
   extraction, public paths are orchestration-focused while side-effect units
   are isolated in private helpers.
6. Slice 2 verification check: `bash -n lib/ops/gpu`,
   `./val/lib/ops/gpu_test.sh`, and `./val/lib/ops/gpu_std_compliance_test.sh`
   all passed.
7. Batch B slice 1 completed: `lib/gen/ana` now decomposes `ana_lad` through
   dedicated `_ana_lad_*` helpers for parsing, row rendering, metadata
   extraction, and JSON emission while preserving the public `ana_lad`
   signature.
8. Batch B slice 2 completed: `ana_acu` now routes argument parsing and
   variable scan orchestration through `_ana_acu_*` helpers, removes duplicated
   scan loops between table/JSON paths, and keeps output contracts stable.
9. Public interface check: `ana_acu` and `ana_lad` signatures remain unchanged
   from the Wave 1 baseline matrix.
10. Batch B verification check: `bash -n lib/gen/ana`,
    `./val/lib/gen/ana_dep_test.sh`, `./val/lib/gen/ana_err_test.sh`,
    `./val/lib/gen/ana_rdp_test.sh`, `./val/lib/gen/ana_scp_test.sh`,
    `./val/lib/gen/ana_tst_test.sh`, and `./val/core/ref_pipeline_parity_test.sh`
    all passed after regenerating references with `./utl/ref/run_all_doc.sh`.

## Phase 3 Verification Record

1. Dependency merge-gate check: WS-01 and WS-02 child plans both report all
   execution phases complete and passing module-level verification suites.
2. Integration confidence gate run completed with
   `./val/lib/confidence_gate.sh --risk medium lib/ops/gpu lib/gen/ana`.
3. Confidence-gate final summary: `Category: lib`, `Total Tests: 28`,
   `Passed: 28`, `Failed: 0`, `Skipped: 0`, `Confidence gate passed.`
4. Signature compatibility confirmation: Wave 1 baseline signatures for
   `gpu_ptp`, `gpu_ptd`, `gpu_pta`, `gpu_pts`, `ana_acu`, and `ana_lad`
   remain unchanged.

## Rollback Hardening Notes

1. `lib/ops/gpu` rollback unit: revert only the Wave 1 GPU decomposition slice
   and rerun `bash -n lib/ops/gpu`, `./val/lib/ops/gpu_test.sh`, and
   `./val/lib/ops/gpu_std_compliance_test.sh` before reattempting integration.
2. `lib/gen/ana` rollback unit: revert only the Wave 1 analyzer decomposition
   slice, regenerate references with `./utl/ref/run_all_doc.sh`, and rerun
   `bash -n lib/gen/ana` plus analyzer suite and parity checks before
   reattempting integration.
3. Wave-level rollback boundary: if integration drift appears after module-local
   rollback, back out both Wave 1 slices together and rerun
   `./val/lib/confidence_gate.sh --risk medium lib/ops/gpu lib/gen/ana` prior
   to convergence reopen.

## Verification Plan

1. Run syntax checks on changed Bash sources with `bash -n <file>`.
2. Run nearest module tests for each touched hotspot area under `val/`.
3. Run `./val/lib/confidence_gate.sh --risk medium <changed files>` before
   closeout to validate decomposition safety at library scope.

## Exit Criteria

- [done] The design baseline exists and is used as the reference for all Wave 1
  decomposition changes.
- [done] Wave 1 hotspot modules are decomposed without public contract drift.
- [done] Targeted regression checks and confidence-gate validation pass with
  recorded evidence linked from this plan.

## What changed

1. Closed the converged Wave 1 parent plan from `wow/active/` to
   `wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/`.
2. Preserved and finalized convergence state for `WS-01`, `WS-02`, and `WS-03`
   with no open blockers.
3. Updated child/design links to their completed paths and retained the Wave 2
   follow-up link.
4. Documentation files updated during this program wave: `doc/ref/functions.md`,
   `doc/ref/module-dependencies.md`, `doc/ref/test-coverage.md`,
   `doc/ref/scope-integrity.md`, `doc/ref/error-handling.md`,
   `doc/ref/stats/actual.md`.

## What was verified

1. Integration gate evidence remains recorded: `./val/lib/confidence_gate.sh
   --risk medium lib/ops/gpu lib/gen/ana` with `Passed: 28`, `Failed: 0`.
2. Module-level and signature-compatibility checks remain recorded in child
   plans and the Phase 3 verification record.
3. Docs: updated (`doc/ref/functions.md`, `doc/ref/module-dependencies.md`,
   `doc/ref/test-coverage.md`, `doc/ref/scope-integrity.md`,
   `doc/ref/error-handling.md`, `doc/ref/stats/actual.md`).

## What remains

1. Start Wave 2 decomposition release planning via
   `wow/inbox/20260307-2048_ops-hotspot-wave-2-release-followup.md`.
