# Ops Hotspot Wave 2 Release Program Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 23:45
- Links: wow/active/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md, wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-ws-01-plan/20260307-2305_ops-hotspot-wave-2-release-ws-01-plan.md, wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-ws-02-plan/20260307-2305_ops-hotspot-wave-2-release-ws-02-plan.md, wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-ws-03-plan/20260307-2305_ops-hotspot-wave-2-release-ws-03-plan.md, lib/ops/dev, val/lib/ops/dev_test.sh, wow/active/20260307-1548_ops-hotspot-decomposition-wave-design.md

## Goal

Decide and prepare Wave 2 hotspot decomposition release scope after Wave 1
convergence, with first priority on `lib/ops/dev` complexity hotspots.

## Context

1. Wave 1 workstreams (`WS-01`, `WS-02`, `WS-03`) converged with integration
   evidence and no open blockers.
2. Architecture telemetry still shows `lib/ops/dev` hotspots (for example
   `_dev_osv_render`) outside Wave 1 scope.
3. Next-wave release should lock boundaries, merge gates, and validation depth
   before implementation starts.

## Scope

1. Propose Wave 2 module set and non-overlapping workstream `Touch-Set`
   boundaries.
2. Define merge-gate expectations and confidence-gate risk level for Wave 2.
3. Capture explicit release decision (`release now` or `hold`) with blockers and
   owner actions.

## Program Scope

1. Serve as the Wave 2 parent coordinator for child workstream planning,
   dependency control, and integration sequencing.
2. Hold cross-workstream constraints for `lib/ops/dev` decomposition while
   preserving non-overlapping `Touch-Set` boundaries.
3. Record final release posture (`release now` or `hold`) from merged validation
   evidence across all child workstreams.

## Global Invariants

1. Child `Touch-Set` values remain non-overlapping unless an explicit
   integration exception is approved here first.
2. Child `Depends-On` references only sibling `Workstream-ID` values and stays
   acyclic.
3. `Merge-Gate` values stay within `minimal`, `module`, or `integration`.
4. This parent owns release decision language, blockers, and owner actions.

## Workstreams

| Workstream-ID | Scope | Depends-On | Touch-Set | Merge-Gate | Child-Plan | Owner | Branch | Worktree | State | Blocker Summary | Next Owner Action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| WS-01 | Render-path boundary extraction in `lib/ops/dev` | none | lib/ops/dev::_dev_osv_render; val/lib/ops/dev_test.sh::render-cases; doc/arc/04-dependency-injection.md | module | wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-ws-01-plan/20260307-2305_ops-hotspot-wave-2-release-ws-01-plan.md | es | ws/ops-hotspot-wave2-ws-01-render | /home/es/lab | done | none | Closed and archived with module-gate evidence recorded. |
| WS-02 | Device-flow boundary extraction in `lib/ops/dev` | WS-01 | lib/ops/dev::device-discovery-flow; val/lib/ops/dev_test.sh::discovery-cases; doc/ref/module-dependencies.md | module | wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-ws-02-plan/20260307-2305_ops-hotspot-wave-2-release-ws-02-plan.md | es | ws/ops-hotspot-wave2-ws-02-device | /home/es/lab | done | none | Closed and archived with module-gate evidence recorded. |
| WS-03 | Integration/release decision and gate evidence | WS-01,WS-02 | wow/active/20260307-2048_ops-hotspot-wave-2-release-program-plan.md::release-decision; val/run_all_tests.sh::lib-category; doc/ref/functions.md; doc/ref/test-coverage.md | integration | wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-ws-03-plan/20260307-2305_ops-hotspot-wave-2-release-ws-03-plan.md | es | ws/ops-hotspot-wave2-ws-03-integration | /home/es/lab | done | none | Closed and archived with integration-gate release evidence recorded. |

## Assignment Snapshot

- Timestamp: 2026-03-07 23:08
- Assigned workstreams: WS-01, WS-02, WS-03
- Unassigned workstreams: none
- Immediate blockers: none

## Sync Snapshot

- Timestamp: 2026-03-07 23:41
- Completed items this sync:
  - none (no state transitions; WS-01, WS-02, and WS-03 remain `done`).
- Blocked items and reason:
  - none.
- Ready-to-converge candidates:
  - WS-01
  - WS-02
  - WS-03

## Convergence Log

### Wave 2 -- 2026-03-07 23:43

1. Converged workstreams: WS-01, WS-02, WS-03.
2. Merge-gate evidence validated:
   - WS-01 (`module`): child execution phases are complete with passing
     `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
     `./val/lib/ops/dev_test.sh` (88 passed, 0 failed).
   - WS-02 (`module`): child execution phases are complete with passing
     `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
     `./val/lib/ops/dev_test.sh` (90 passed, 0 failed).
   - WS-03 (`integration`): child execution steps are complete with passing
     `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
     `./val/run_all_tests.sh lib` (28/28 suites passed), plus docs refresh via
     `./utl/ref/run_all_doc.sh`.
3. Integration checks run:
   - `bash -n lib/ops/dev`
   - `bash -n val/lib/ops/dev_test.sh`
   - `./val/run_all_tests.sh lib`
   - `./utl/ref/run_all_doc.sh`
4. Unresolved conflicts or blockers: none.
5. Next wave release decision: `release now`.
6. Follow-up routing: no new follow-up item required (no remaining mandatory,
   scope-locked blocker for a forced next-wave queue item).

## Integration Cadence

1. Run `wow/task/active-fanout` to create child workstream plans from this
   parent.
2. Run `wow/task/active-assign` to bind owner/context/branch/worktree metadata
   for each child plan.
3. Use recurring parent sync checkpoints to roll up child status, blockers, and
   merge readiness before convergence.

## Triage Decision

- Why now: Wave 1 convergence removed blockers, and remaining `lib/ops/dev`
  hotspots now define near-term release risk and sequencing.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: Wave 2 boundary and merge-gate decisions shape downstream
  workstream contracts and validation behavior across dependent modules.

## Next Step

Closed through the standard completed-close path with convergence and release
decision evidence preserved.

## Documentation Impact

Docs: required

## Execution Plan

1. Phase 1 (orchestration, completed): Fan out this parent into child
   workstream plans and assign owner/worktree metadata.
   Completion criterion: child plans exist with non-overlapping `Touch-Set`
   entries and valid orchestration metadata.
2. Phase 2 (design and implementation, completed): Execute Wave 2 decomposition
   across child workstreams and record design trade-offs and selected
   interfaces.
   Completion criterion: planned Wave 2 code and test changes are complete.
3. Phase 3 (release decision, completed): Run validation gates and record the
   explicit release decision (`release now` or `hold`) with blockers and owner
   actions.
   Completion criterion: the release decision block is finalized in this item.

## Verification Plan

1. Run `bash -n` on every edited Bash file.
2. Run nearest hotspot tests (starting with `./val/lib/ops/dev_test.sh`).
3. Run `./val/run_all_tests.sh lib` when Wave 2 touches multiple lib modules.
4. Verify documentation updates are included in this same workflow item when
   structural/public surfaces change.
5. Run `./utl/ref/run_all_doc.sh` when structural/public surfaces change, and
   record the result in closeout evidence.

## Exit Criteria

- Wave 2 child workstreams are planned, assigned, and progressing under
  non-overlapping boundaries.
- Validation evidence supports a clear `release now` or `hold` outcome.
- Documentation updates (or documented blocker with follow-up route) are
  present before closeout.

## Release Decision

- Decision: release now.
- Evidence basis:
  1. WS-01 and WS-02 completed with no blockers and compatible interface
     boundaries.
  2. WS-03 integration validation passed (`bash -n lib/ops/dev`,
     `bash -n val/lib/ops/dev_test.sh`, `./val/run_all_tests.sh lib`: 28
     suites passed, 0 failed).
  3. Structural/reference documentation was refreshed with
     `./utl/ref/run_all_doc.sh`, including `doc/ref/functions.md` and
     `doc/ref/test-coverage.md`.
- Blockers: none.
- Owner actions:
  1. Archive completed evidence in this leaf and retain links to closed
     workstream leaves.
  2. Open a follow-up only if post-close regression evidence appears.

## Progress Checkpoint

### Done

- Promoted this active item into a `-program-plan.md` parent path.
- Added required parent sections for parallel orchestration readiness.
- Executed fanout and created child plans for WS-01, WS-02, and WS-03.
- Assigned all child workstreams with owner, branch, and worktree metadata.
- Synced child state into parent: WS-01 done, WS-02 done, WS-03 done.
- Recorded explicit parent release decision: `release now` with no blockers.
- Re-synced parent state after completion with no workstream status drift.
- Recorded Wave 2 convergence log with validated merge-gate evidence.
- Tests/docs evidence run this session: `./val/run_all_tests.sh lib` and
  `./utl/ref/run_all_doc.sh`.

### In-flight

- None.

### Blockers

- None.

### Next steps

1. None.

### Context

- Workflow state at checkpoint: item moved to `wow/completed/` with
  `Status: completed` and `Design: required`.
- Parent filename now conforms to the required `-program-plan.md` suffix.
- No temporary files or uncommitted generated artifacts were created.

## What changed

1. Closed this parent program plan from `wow/active/` to
   `wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-program-plan/`.
2. Updated the parent workstream table to reference immutable completed paths
   for WS-01, WS-02, and WS-03 child plans.
3. Preserved Wave 2 convergence and release decision records (`release now`) in
   this completed parent.
4. Documentation files updated during this wave:
   `doc/arc/04-dependency-injection.md`, `doc/ref/module-dependencies.md`,
   `doc/ref/functions.md`, `doc/ref/test-coverage.md`.

## What was verified

1. WS-01 module-gate evidence remained recorded with passing
   `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
   `./val/lib/ops/dev_test.sh` (`88 passed`, `0 failed`).
2. WS-02 module-gate evidence remained recorded with passing
   `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
   `./val/lib/ops/dev_test.sh` (`90 passed`, `0 failed`).
3. WS-03 integration-gate evidence remained recorded with passing
   `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
   `./val/run_all_tests.sh lib` (`28/28 suites passed`, `0 failed`), plus
   `./utl/ref/run_all_doc.sh` completion.
4. Docs: updated (`doc/arc/04-dependency-injection.md`,
   `doc/ref/module-dependencies.md`, `doc/ref/functions.md`,
   `doc/ref/test-coverage.md`).

## What remains

1. No mandatory follow-up item is required at close.
2. If regressions appear after close, capture a new follow-up in `wow/inbox/`
   using standard routing policy.
