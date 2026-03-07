# Ops Hotspot Analyzer Workstream Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 21:03
- Links: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md, wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1548_ops-hotspot-decomposition-wave-design.md, lib/gen/ana, val/lib/gen/ana_dep_test.sh, val/lib/gen/ana_err_test.sh, val/lib/gen/ana_rdp_test.sh, val/lib/gen/ana_scp_test.sh, val/lib/gen/ana_tst_test.sh

## Goal

Execute Wave 1 Batch B decomposition for `lib/gen/ana` while preserving
`ana_acu` and `ana_lad` public interfaces.

## Context

1. Complexity telemetry places `ana_acu` among top large-function hotspots.
2. The design baseline locks interface guardrails and analyzer-specific
   verification targets.
3. This workstream is independent of GPU module changes and can run in
   parallel.
4. Baseline review confirmed `ana_lad` concentrated argument parsing, rendering,
   and metadata extraction in one function while `ana_acu` duplicated
   per-variable scan orchestration across table and JSON paths.

## Triage Decision

- Why now: analyzer decomposition is the second Wave 1 hotspot and can proceed
  concurrently with WS-01.
- Design classification Q1 (meaningful alternatives): Yes -- parser/orchestration
  split choices affect readability and failure-surface shape.
- Design classification Q2 (output shape dependencies): Yes -- compatibility
  validation and convergence records depend on stable analyzer boundaries.
- Design: required
- Justification: selecting correct decomposition seams is necessary to reduce
  complexity without introducing drift.

## Documentation Impact

- Docs: required
- Target docs (initial): `doc/ref/functions.md`, `doc/ref/module-dependencies.md`,
  `doc/ref/test-coverage.md`, `doc/ref/scope-integrity.md`,
  `wow/active/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md`

## Orchestration Metadata

- Program: wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md
- Workstream-ID: WS-02
- Depends-On: none
- Touch-Set: lib/gen/ana,val/lib/gen/ana_dep_test.sh,val/lib/gen/ana_err_test.sh,val/lib/gen/ana_rdp_test.sh,val/lib/gen/ana_scp_test.sh,val/lib/gen/ana_tst_test.sh
- Merge-Gate: module
- Branch: ws/ops-hotspot-ws-02-ana
- Worktree: /home/es/lab

## Scope

1. Decompose `ana_acu` and `ana_lad` internals around parsing and orchestration.
2. Preserve existing command semantics and return behavior.
3. Keep analyzer output contracts stable for docs/reference generators.

## Execution Plan

1. [done] Baseline current analyzer flows and identify extraction seams.
2. [done] Implement helper-based decomposition in reviewable slices.
3. [done] Record interface-compatibility checks in the parent signature matrix.

## Progress Log

1. `ana_lad` decomposition slice completed by extracting argument parsing,
   path resolution, row rendering, metadata extraction, and JSON emit helpers
   (`_ana_lad_*`) while preserving `ana_lad <file/directory name> [-t] [-b] [-j]`.
2. `ana_acu` decomposition slice completed by extracting parser/orchestration
   helpers (`_ana_acu_parse_args`, `_ana_acu_collect_usage_for_var`,
   `_ana_acu_display_folder_path`, `_ana_acu_json_escape`) and reusing one scan
   pass for both table and JSON output payload assembly.
3. Verification completed: `bash -n lib/gen/ana`,
   `./val/lib/gen/ana_dep_test.sh`, `./val/lib/gen/ana_err_test.sh`,
   `./val/lib/gen/ana_rdp_test.sh`, `./val/lib/gen/ana_scp_test.sh`,
   `./val/lib/gen/ana_tst_test.sh`, and
   `./val/core/ref_pipeline_parity_test.sh` all passed.
4. Documentation impact fulfilled by regenerating references with
   `./utl/ref/run_all_doc.sh` and revalidating parity after regeneration.

## Verification Plan

1. Run `bash -n lib/gen/ana` after each decomposition slice.
2. Run `./val/lib/gen/ana_dep_test.sh`, `./val/lib/gen/ana_err_test.sh`, and
   `./val/lib/gen/ana_rdp_test.sh`.
3. Run `./val/lib/gen/ana_scp_test.sh` and `./val/lib/gen/ana_tst_test.sh`
   before marking WS-02 done.

## Exit Criteria

- `ana_acu` and `ana_lad` public signatures remain unchanged.
- Analyzer nearest-module suites pass with no new regressions.
- Parent workstream row is ready for module-gate convergence review.

## What changed

1. Closed this completed analyzer workstream plan from `wow/active/` to
   `wow/completed/20260307-multi_completed-folder-module-naming-unification-plan/20260307-2103_multi_ops-hotspot-decomposition-wave-program-plan/`.
2. Preserved finalized decomposition evidence for `ana_lad` and `ana_acu`
   helper extraction and output-contract stability.
3. Documentation files updated during this workstream: `doc/ref/functions.md`,
   `doc/ref/module-dependencies.md`, `doc/ref/test-coverage.md`,
   `doc/ref/scope-integrity.md`.

## What was verified

1. Recorded analyzer validation remains: `bash -n lib/gen/ana`, analyzer test
   suite scripts, and `./val/core/ref_pipeline_parity_test.sh` all passed.
2. Recorded reference regeneration remains: `./utl/ref/run_all_doc.sh` completed
   before parity verification.
3. Docs: updated (`doc/ref/functions.md`, `doc/ref/module-dependencies.md`,
   `doc/ref/test-coverage.md`, `doc/ref/scope-integrity.md`).

## What remains

1. No WS-02-local follow-up; next-wave planning is tracked in parent-linked
   inbox follow-up.
