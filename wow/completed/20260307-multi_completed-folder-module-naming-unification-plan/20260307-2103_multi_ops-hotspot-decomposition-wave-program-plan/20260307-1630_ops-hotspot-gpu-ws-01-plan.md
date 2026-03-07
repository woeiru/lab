# Ops Hotspot GPU Workstream Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 21:03
- Links: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md, wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1548_ops-hotspot-decomposition-wave-design.md, lib/ops/gpu, val/lib/ops/gpu_test.sh, val/lib/ops/gpu_std_compliance_test.sh

## Goal

Complete Wave 1 Batch A decomposition for `lib/ops/gpu` while preserving public
interfaces and behavior.

## Context

1. `gpu_ptp` has already been split into shared step helpers in the parent
   batch log.
2. Remaining high-value decomposition work is concentrated in detach/attach
   flows (`gpu_ptd` and `gpu_pta`).
3. This workstream owns only GPU-module refactoring and nearest regression
   checks.
4. `gpu_ptd` and `gpu_pta` shared the same driver-mode parsing, mode
   validation, and runtime dependency checks.
5. Per-device detach and attach sequences were extracted into dedicated helper
   boundaries to reduce nested control flow in public functions.
6. Current WS-01 verification snapshot (detach/attach slice): `bash -n
   lib/ops/gpu`, `./val/lib/ops/gpu_test.sh`, and
   `./val/lib/ops/gpu_std_compliance_test.sh` all pass.

## Triage Decision

- Why now: this is the highest active hotspot in Wave 1 and already has partial
  decomposition momentum.
- Design classification Q1 (meaningful alternatives): Yes -- helper boundaries
  for detach/attach paths affect readability and rollback safety.
- Design classification Q2 (output shape dependencies): Yes -- downstream
  verification and convergence depend on stable GPU decomposition outputs.
- Design: required
- Justification: decomposition boundary choices directly determine maintainable
  structure without contract drift.

## Documentation Impact

- Docs: required
- Target docs (initial): `doc/ref/functions.md`, `doc/ref/module-dependencies.md`,
  `doc/ref/test-coverage.md`, `doc/ref/error-handling.md`,
  `wow/active/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md`

## Orchestration Metadata

- Program: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md
- Workstream-ID: WS-01
- Depends-On: none
- Touch-Set: lib/ops/gpu,val/lib/ops/gpu_test.sh,val/lib/ops/gpu_std_compliance_test.sh
- Merge-Gate: module
- Branch: ws/ops-hotspot-ws-01-gpu
- Worktree: /home/es/lab

## Scope

1. Extract shared internals from `gpu_ptd`/`gpu_pta` without changing signatures.
2. Keep return-code and logging semantics aligned with `lib/ops/.spec`.
3. Maintain Wave 1 baseline signature compatibility for GPU public functions.

## Execution Plan

1. [done] Phase 1 - Map detach/attach decomposition seams.
   Completion criterion: shared setup and per-device boundary candidates are
   locked for `gpu_ptd`/`gpu_pta`.
2. [done] Phase 2 - Extract helpers in small slices and rewire call paths.
   Completion criterion: shared setup, per-device attach/detach, and
   post-attach NVIDIA handling are helper-backed with unchanged signatures.
3. [done] Phase 3 - Update parent phase log with before/after slice notes.
   Completion criterion: parent Phase 2 progress log records slice details and
   verification evidence.

## Verification Plan

1. Run `bash -n lib/ops/gpu` after each extraction slice.
2. Run `./val/lib/ops/gpu_test.sh` for behavioral regression coverage.
3. Run `./val/lib/ops/gpu_std_compliance_test.sh` for standards compliance.

## Exit Criteria

- `gpu_ptp`, `gpu_ptd`, `gpu_pta`, and `gpu_pts` signatures remain unchanged.
- GPU nearest-module test suites pass after final WS-01 changes.
- Parent workstream row is ready for module-gate convergence review.

## What changed

1. Closed this completed GPU workstream plan from `wow/active/` to
   `wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/`.
2. Preserved finalized decomposition scope/evidence for `gpu_ptp`, `gpu_ptd`,
   and `gpu_pta` helper extraction work.
3. Documentation files updated in this close step: none.

## What was verified

1. Recorded module gate evidence remains: `bash -n lib/ops/gpu`,
   `./val/lib/ops/gpu_test.sh`, and `./val/lib/ops/gpu_std_compliance_test.sh`
   passed.
2. Parent convergence log confirms WS-01 converged with no blockers.
3. Docs: none (no additional documentation files were changed during closeout).

## What remains

1. No WS-01-local follow-up; next-wave planning is tracked in parent-linked
   inbox follow-up.
