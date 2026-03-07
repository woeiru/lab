# Ops Hotspot Wave 2 Release WS-01 Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 23:45
- Links: wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-program-plan/20260307-2048_ops-hotspot-wave-2-release-program-plan.md, lib/ops/dev, val/lib/ops/dev_test.sh, doc/arc/04-dependency-injection.md

## Goal

Define and implement WS-01 render-path boundary extraction in `lib/ops/dev` so
downstream workstreams can depend on a stable decomposition seam.

## Context

1. The program parent requires non-overlapping touch-sets across workstreams.
2. WS-01 is the upstream dependency for WS-02 and WS-03.
3. Existing hotspot evidence identifies render-path complexity as a near-term
   release risk.
4. `_dev_osv_render` previously mixed data extraction and terminal table
   formatting in one hotspot path.
5. WS-01 extracted a stable row contract boundary so rendering can evolve
   without changing attribution/query behavior.

## Scope

1. Isolate the WS-01 render-path hotspot segment within `lib/ops/dev`.
2. Update nearest render-path tests in `val/lib/ops/dev_test.sh`.
3. Capture interface notes needed by dependent workstreams.

## Triage Decision

- Why now: render-path decomposition is the first prerequisite for downstream
  hotspot workstreams.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: boundary and interface choices in WS-01 directly constrain
  downstream dependency contracts.

## Documentation Impact

Docs: required

## Orchestration Metadata

- Program: wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-program-plan/20260307-2048_ops-hotspot-wave-2-release-program-plan.md
- Workstream-ID: WS-01
- Depends-On: none
- Touch-Set: lib/ops/dev::_dev_osv_collect_rows_tsv,_dev_osv_render_table_from_tsv,_dev_osv_render; val/lib/ops/dev_test.sh::render-cases; doc/arc/04-dependency-injection.md
- Merge-Gate: module
- Branch: ws/ops-hotspot-wave2-ws-01-render
- Worktree: /home/es/lab

## Execution Plan

1. Phase 1 (design, completed): finalize the WS-01 seam by splitting
   extraction, rendering, and orchestration responsibilities.
   Completion criterion: a stable interface contract is chosen and recorded.
2. Phase 2 (implementation, completed): implement `_dev_osv_collect_rows_tsv`
   and `_dev_osv_render_table_from_tsv`, then route `_dev_osv_render` through
   the seam.
   Completion criterion: WS-01 code touch-set reflects the approved boundary.
3. Phase 3 (verification/docs, completed): update render-path tests, validate,
   and record downstream interface notes.
   Completion criterion: tests pass and docs/checkpoint evidence are captured.

## Verification Plan

1. Run `bash -n` on edited Bash files.
2. Run `./val/lib/ops/dev_test.sh` for nearest hotspot validation.
3. Verify documentation updates are recorded for
   `doc/arc/04-dependency-injection.md`.
4. Run `./utl/ref/run_all_doc.sh` when structural/public surfaces change and
   record the result in evidence.

## Exit Criteria

- WS-01 touch-set changes are complete and test-backed.
- Downstream workstreams can consume WS-01 interfaces without overlap.
- Documentation updates and checkpoint evidence are recorded.

## Interface Notes

1. `_dev_osv_collect_rows_tsv` is the data boundary and emits canonical TSV
   rows with header:
   `suffix,id,project_root,directory,title,updated_local,first_prompt_local,user,src,conf,model,input,output`.
2. `_dev_osv_render_table_from_tsv` is presentation-only and must consume the
   TSV contract without touching attribution/query logic.
3. `_dev_osv_render` is orchestration-only (`-x` plain/column output, `-t`
   bordered table output) and should remain thin for downstream changes.

## Progress Checkpoint

### Done

- Phase 1 design decision completed: selected extraction/render/orchestration
  seam over extending the monolithic render path.
- Refactored `lib/ops/dev` to introduce `_dev_osv_collect_rows_tsv` and
  `_dev_osv_render_table_from_tsv`, with `_dev_osv_render` now orchestrating
  mode output.
- Added render-path boundary tests:
  `test_dev_overview_rows_tsv_contract` and
  `test_dev_overview_table_renderer_from_tsv_contract`.
- Updated architecture notes in `doc/arc/04-dependency-injection.md` with WS-01
  seam contract guidance for downstream workstreams.
- Verification run: `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`,
  and `./val/lib/ops/dev_test.sh` (88 passed, 0 failed).

### In-flight

- None.

### Blockers

- None.

### Next steps

1. WS-02 can consume the TSV seam and focus on device-flow extraction without
   touching rendering internals.
2. Run parent sync (`wow/task/active-sync`) to roll WS-01 completion evidence
   into the program item.

## What changed

1. Closed this WS-01 item from `wow/active/` to
   `wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2345_ops_hotspot-wave-2-release-ws-01-plan/`.
2. Preserved finalized render-path decomposition outputs for
   `_dev_osv_collect_rows_tsv`, `_dev_osv_render_table_from_tsv`, and
   `_dev_osv_render` orchestration behavior.
3. Documentation files updated in this workstream: `doc/arc/04-dependency-injection.md`.

## What was verified

1. Validation evidence remained green from WS-01 completion checkpoint:
   `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and
   `./val/lib/ops/dev_test.sh` (`88 passed`, `0 failed`).
2. Parent convergence log includes WS-01 module merge-gate evidence.
3. Docs: updated (`doc/arc/04-dependency-injection.md`).

## What remains

1. No WS-01-local follow-up is required.
2. Parent convergence/close workflow tracks any wave-level follow-up if new
   regressions appear.
