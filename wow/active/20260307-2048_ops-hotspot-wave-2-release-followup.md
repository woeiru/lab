# Ops Hotspot Wave 2 Release Follow-up

- Status: active
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 21:23
- Links: wow/active/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md, wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, lib/ops/dev, val/lib/ops/dev_test.sh, wow/active/20260307-1548_ops-hotspot-decomposition-wave-design.md

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

Execute the Wave 2 design phase, then implement approved hotspot decomposition
workstreams under the defined merge and validation gates.

## Documentation Impact

Docs: required

Initial target docs:
- doc/arc/04-dependency-injection.md
- doc/ref/functions.md
- doc/ref/module-dependencies.md
- doc/ref/test-coverage.md

## Execution Plan

1. Phase 1 (design, pending): Produce a Wave 2 design brief that records
   interfaces, constraints, trade-offs, and the chosen approach for
   `lib/ops/dev` decomposition.
   Completion criterion: the design brief is committed in this workflow item.
2. Phase 2 (implementation, pending): Apply the approved decomposition to the
   Wave 2 hotspot set in `lib/ops/dev` and aligned tests.
   Completion criterion: planned Wave 2 code and test changes are complete.
3. Phase 3 (release decision, pending): Run validation gates and record the
   explicit release decision (`release now` or `hold`) with blockers and owner
   actions.
   Completion criterion: the release decision block is finalized in this item.

## Verification Plan

1. Run `bash -n` on every edited Bash file.
2. Run nearest hotspot tests (starting with `./val/lib/ops/dev_test.sh`).
3. Run `./val/run_all_tests.sh lib` when Wave 2 touches multiple lib modules.
4. Verify documentation updates are included in this same workflow item for all
   listed target doc paths.
5. Run `./utl/ref/run_all_doc.sh` when structural/public surfaces change, and
   record the result in closeout evidence.

## Exit Criteria

- Wave 2 design brief is complete and implementation is aligned to it.
- Validation evidence supports a clear `release now` or `hold` outcome.
- Documentation updates (or documented blocker with follow-up route) are
  present before closeout.

## Progress Checkpoint

### Done

- Confirmed this active item is still valid and checker-clean before handoff.
- Captured checkpoint state and refreshed remaining-plan status labels.
- Recorded execution order for promote -> fanout -> assign.
- Tests run this session: none.

### In-flight

- No child workstream plans exist yet for this Wave 2 follow-up item.
- Parent has not yet been promoted to a `-program-plan.md` form.

### Blockers

- Parallel fanout depends on promoting this item into a valid program parent
  path ending in `-program-plan.md`.

### Next steps

1. Run `wow/task/active-promote` on
   `wow/active/20260307-2048_ops-hotspot-wave-2-release-followup.md` and ensure
   the resulting parent path ends with `-program-plan.md`.
2. Run `wow/task/active-fanout` on the promoted parent to create child
   workstream plans with non-overlapping `Touch-Set` values.
3. Run `wow/task/active-assign` on the same parent to set owners, branches, and
   worktrees for each child plan.
4. Begin Phase 1 design execution on the parent/children and capture interface,
   constraint, trade-off, and chosen-approach evidence in active artifacts.

### Context

- Workflow state at checkpoint: item remains in `wow/active/` with
  `Status: active` and `Design: required`.
- No temporary files or uncommitted generated artifacts were created.
- No test evidence was produced in this session.
