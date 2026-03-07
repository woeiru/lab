# Ops Hotspot Wave 2 Release WS-02 Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 23:45
- Links: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2345_multi_ops-hotspot-wave-2-release-program-plan/20260307-2048_ops-hotspot-wave-2-release-program-plan.md, lib/ops/dev, val/lib/ops/dev_test.sh, doc/ref/module-dependencies.md

## Goal

Define and implement WS-02 device-flow boundary extraction in `lib/ops/dev`
with compatibility to the WS-01 decomposition seam.

## Context

1. WS-02 depends on WS-01 outputs and should not overlap WS-01 touch-set scope.
2. Device-flow hotspots remain in Wave 2 scope after Wave 1 convergence.
3. Merge readiness for this stream is targeted at the `module` gate.
4. WS-01 finalized a seam pattern where orchestration stays thin and delegates
   to extracted boundary helpers.

## Scope

1. Isolate WS-02 device-flow hotspot boundaries in `lib/ops/dev`.
2. Update nearest device-flow tests in `val/lib/ops/dev_test.sh`.
3. Update dependency documentation inputs for downstream integration review.

## Triage Decision

- Why now: device-flow decomposition is the second required stream before
  integration convergence.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: dependency and boundary choices in WS-02 affect integration
  sequencing and release confidence.

## Documentation Impact

Docs: required

## Orchestration Metadata

- Program: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2345_multi_ops-hotspot-wave-2-release-program-plan/20260307-2048_ops-hotspot-wave-2-release-program-plan.md
- Workstream-ID: WS-02
- Depends-On: WS-01
- Touch-Set: lib/ops/dev::device-discovery-flow; val/lib/ops/dev_test.sh::discovery-cases; doc/ref/module-dependencies.md
- Merge-Gate: module
- Branch: ws/ops-hotspot-wave2-ws-02-device
- Worktree: /home/es/lab

## Execution Plan

1. Phase 1 (design, completed): align WS-02 with the WS-01 seam and lock the
   device-flow boundary contract for account-path discovery.
   Completion criterion: a reusable discovery boundary is defined and recorded
   before mutation-path implementation starts.
2. Phase 2 (implementation, completed): extract the discovery boundary into a
   shared helper and rewire WS-02 touch-set account mutation flows to use it.
   Completion criterion: `dev_oaa`, `dev_oas`, `dev_oar`, and `dev_oad`
   consume the boundary helper with no behavior drift.
3. Phase 3 (verification/docs, completed): update discovery-focused tests,
   refresh dependency documentation inputs, and capture validation evidence.
   Completion criterion: nearest tests and documentation evidence are recorded
   for parent sync.

## Verification Plan

1. Run `bash -n` on edited Bash files.
2. Run `./val/lib/ops/dev_test.sh` for nearest hotspot validation.
3. Verify documentation updates are recorded for
   `doc/ref/module-dependencies.md`.
4. Run `./utl/ref/run_all_doc.sh` when structural/public surfaces change and
   record the result in evidence.

## Exit Criteria

- WS-02 touch-set changes are complete and test-backed.
- WS-02 merges cleanly after WS-01 without touch-set overlap.
- Documentation updates and checkpoint evidence are recorded.

## Interface Notes

1. `_dev_prepare_device_flow_context` is the WS-02 discovery boundary and
   owns common preflight checks (`python3`, accounts-path discovery,
   denylist reconcile pre-pass).
2. `dev_oaa`, `dev_oas`, `dev_oar`, and `dev_oad` remain orchestration entry
   points that apply operation-specific mutation logic after discovery.
3. WS-02 preserves existing command signatures and return semantics so WS-03
   integration does not require call-site changes.

## Progress Checkpoint

### Done

- Phase 1 design completed: selected a discovery-boundary seam compatible with
  WS-01's extraction/orchestration split.
- Captured WS-02 interface notes for discovery boundary ownership and
  orchestration compatibility.
- Phase 2 implementation completed in `lib/ops/dev`:
  `_dev_prepare_device_flow_context` now owns shared device-flow preflight,
  and `dev_oaa`, `dev_oas`, `dev_oar`, `dev_oad` consume this boundary.
- Phase 3 verification completed:
  `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
  `./val/lib/ops/dev_test.sh` (90 passed, 0 failed).
- Dependency documentation input refreshed:
  `doc/ref/module-dependencies.md` regenerated via `./utl/ref/generators/dep`.

### In-flight

- None.

### Blockers

- None.

### Next steps

1. Run `wow/task/active-sync` to roll WS-02 completion evidence into the
   parent program item and unblock WS-03.
2. Prepare WS-02 for close/move once parent sync captures merge-gate status.

## What changed

1. Closed this WS-02 item from `wow/active/` to
   `wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2345_multi_ops-hotspot-wave-2-release-ws-02-plan/`.
2. Preserved finalized device-flow decomposition outputs centered on
   `_dev_prepare_device_flow_context` and downstream orchestration reuse in
   `dev_oaa`, `dev_oas`, `dev_oar`, and `dev_oad`.
3. Documentation files updated in this workstream: `doc/ref/module-dependencies.md`.

## What was verified

1. Validation evidence remained green from WS-02 completion checkpoint:
   `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
   `./val/lib/ops/dev_test.sh` (`90 passed`, `0 failed`).
2. Parent convergence log includes WS-02 module merge-gate evidence.
3. Docs: updated (`doc/ref/module-dependencies.md`).

## What remains

1. No WS-02-local follow-up is required.
2. Parent convergence/close workflow tracks any wave-level follow-up if new
   regressions appear.
