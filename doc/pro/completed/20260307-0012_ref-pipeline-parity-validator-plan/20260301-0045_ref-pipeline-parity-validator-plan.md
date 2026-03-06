# Ref Pipeline Parity Validator Plan

- Status: completed
- Owner: es
- Started: n/a
- Updated: 2026-03-07 00:09:00
- Links: doc/ref/README.md, doc/ref/functions.md, doc/ref/variables.md, doc/ref/reverse-dependecies.md, doc/ref/module-dependencies.md, doc/ref/test-coverage.md, doc/ref/scope-integrity.md, doc/ref/error-handling.md, cfg/ali/sta, utl/doc/run_all_doc.sh

## Goal

Add a lightweight, deterministic parity validator that compares normalized analyzer-backed rows against generated `doc/ref/*` outputs for all current reference pipelines:

- `ffl-laf_cycle` <-> `doc/ref/functions.md`
- `ffl-acu_cycle` <-> `doc/ref/variables.md`
- `ffl-rdp_cycle` <-> `doc/ref/reverse-dependecies.md`
- `ffl-dep_cycle` <-> `doc/ref/module-dependencies.md`
- `ffl-tst_cycle` <-> `doc/ref/test-coverage.md`
- `ffl-scp_cycle` <-> `doc/ref/scope-integrity.md`
- `ffl-err_cycle` <-> `doc/ref/error-handling.md`

## Why

Current tests validate individual analyzers, but coverage still reports no dedicated tests for the main doc generators/parity path. This leaves room for silent drift between cycle expectations and committed reference docs.

## Triage Decision

- Why now: `doc/ref/README.md` defines strict parity with cycle aliases, but parity is not currently validated end-to-end in CI for these pipelines.
- Design questions:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: normalization strategy and mismatch reporting become a stable contract for CI and maintainers, so design choices materially affect future changes.

## Execution Plan

### Phase 1 -- Finalize Design Contract (completed)

- Produce a design decision record for parity validation covering: helper interfaces, normalization schema, parser constraints, trade-offs, and chosen comparison strategy.
- Phase gate: no implementation work starts until this phase is complete.

Completion criterion: this document contains a completed design decision record with interfaces, constraints, trade-offs, and the chosen approach.

## Phase 1 Design Decision Record

Date: 2026-03-06
Design classification: required

1. Interfaces (chosen):
   - One new executable test: `val/core/ref_pipeline_parity_test.sh`.
   - Internal helper families in that script:
     - expected-row collectors (from analyzer JSON)
     - actual-row extractors (from `doc/ref/*.md` auto-generated table sections)
     - one generic set-comparison reporter (missing/extra rows per pipeline).
2. Normalization contract (chosen):
   - Unit of comparison is a normalized markdown **row line**, not full-file text.
   - Ignore markdown prose, timestamps, and table headers/separators.
   - Preserve cell payload content (including escaped markdown characters) so
     parity remains content-accurate.
3. Constraints:
   - CI-safe and read-only for `doc/ref/*` (no generator write-back in tests).
   - Deterministic output and deterministic mismatch diagnostics.
   - Cover all cycle/doc contracts currently declared in `doc/ref/README.md`.
4. Alternatives considered:
   - Full-file markdown diff: rejected due to timestamp/format noise.
   - JSON-only artifact parity without markdown parse: rejected because it would
     not validate the committed `doc/ref/*.md` contract actually consumed by users.
5. Trade-off:
   - Row-level markdown parity is stricter than semantic-only checks, but it
     catches real documentation drift with actionable missing/extra row output.
6. Chosen approach:
   - Recompute expected rows directly from `ana_* -j` outputs using the same
     row-shaping logic as each generator, extract actual rows from auto-generated
     markdown tables, then compare sorted row sets for the seven pipelines.

### Phase 2 -- Implement Core Parity Harness (completed)

- Create `val/core/ref_pipeline_parity_test.sh` with reusable helpers to collect analyzer JSON outputs, parse markdown table rows, normalize row payloads, and diff sets.

Completion criterion: `bash -n val/core/ref_pipeline_parity_test.sh` passes.

### Phase 3 -- Implement Seven Pipeline Comparators (completed)

- Add sequential parity checks for `laf`, `acu`, `rdp`, `dep`, `tst`, `scp`, and `err`, each emitting focused missing/extra-row diagnostics.

Completion criterion: all seven pipeline comparators are implemented in `val/core/ref_pipeline_parity_test.sh` with pipeline-specific mismatch output.

### Phase 4 -- Validate Integration Path (completed)

- Run the new parity test directly and then run the core suite path to confirm deterministic behavior in standard validation flow.

Completion criterion: `./val/run_all_tests.sh core` passes with the parity test included.

## Verification Plan

- Syntax: `bash -n val/core/ref_pipeline_parity_test.sh`
- Targeted execution: `./val/core/ref_pipeline_parity_test.sh`
- Category validation: `./val/run_all_tests.sh core`

## Exit Criteria

- Active item includes a completed Phase 1 design decision record and implemented parity validator script.
- Parity validation covers all seven doc/ref cycle contracts with deterministic mismatch reporting.
- Required verification commands pass and the item is ready for `completed-close`.

## Proposed Test Location

- `val/core/ref_pipeline_parity_test.sh`

## Proposed Approach

1. Build expected row sets from analyzer JSON outputs (`ana_* -j --json-dir <tmp>`), scoped to each cycle contract.
2. Parse each target `doc/ref/*.md` auto-generated table into normalized row sets (ignore markdown headers/timestamps).
3. Compare expected vs actual as set/row parity checks (missing rows and extra rows), not full-file diffs.
4. Cover all seven pipelines in one script with per-pipeline failure summaries.
5. Keep test CI-safe by using temporary directories only and avoiding write-back regeneration of docs.

## Acceptance Criteria

- One test script covers all seven parity pipelines.
- Test is deterministic and CI-safe.
- Failures identify pipeline plus missing/extra normalized rows.
- Pass confirms parity for current generated references.

## Open Notes

- Handle alias behavior in non-interactive shells by using wrapper functions (`_ffl_*_cycle`) where needed.
- Avoid false negatives from markdown formatting/timestamps by comparing normalized rows only.

## Progress Checkpoint

### Done

1. Added Phase 1 design decision record (interfaces, normalization contract, constraints, alternatives, chosen approach).
2. Implemented parity harness in `val/core/ref_pipeline_parity_test.sh`.
3. Implemented all seven pipeline checks (`laf`, `acu`, `rdp`, `dep`, `tst`, `scp`, `err`) with missing/extra row diagnostics.
4. Regenerated affected reference docs so current repository state matches analyzer-derived parity expectations.
5. Validation results:
   - `bash -n val/core/ref_pipeline_parity_test.sh` -> pass
   - `./val/core/ref_pipeline_parity_test.sh` -> pass
   - `./val/run_all_tests.sh core` -> pass

### In-flight

1. None.

### Blockers

1. None.

### Next steps

1. Run `doc/pro/task/completed-close` when you want to close this item.

## What Changed

- Added `val/core/ref_pipeline_parity_test.sh` to validate analyzer/doc parity across seven cycle contracts.
- Implemented deterministic row-set comparison with per-pipeline missing/extra-row diagnostics.
- Regenerated parity-affected reference outputs: `doc/ref/module-dependencies.md`, `doc/ref/test-coverage.md`, `doc/ref/scope-integrity.md`, and `doc/ref/error-handling.md`.

## What Was Verified

- `bash -n val/core/ref_pipeline_parity_test.sh` -> pass.
- `./val/core/ref_pipeline_parity_test.sh` -> pass (all seven parity pipelines matched).
- `./val/run_all_tests.sh core` -> pass.
- `bash doc/pro/check-workflow.sh` -> pass.

## What Remains

- None for this scope.
