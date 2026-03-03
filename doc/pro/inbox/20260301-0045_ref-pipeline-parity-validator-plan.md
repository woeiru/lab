# Ref Pipeline Parity Validator Plan

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-01
- Links: doc/ref/README.md, doc/ref/functions.md, doc/ref/variables.md, doc/ref/reverse-dependecies.md, doc/ref/module-dependencies.md, cfg/ali/sta, utl/doc/run_all_doc.sh

## Goal

Add a lightweight validation test that checks parity between terminal cycle outputs and generated `doc/ref/*` references for all four pipelines:

- `ffl-laf_cycle` <-> `doc/ref/functions.md`
- `ffl-acu_cycle` <-> `doc/ref/variables.md`
- `ffl-rdp_cycle` <-> `doc/ref/reverse-dependecies.md`
- `ffl-dep_cycle` <-> `doc/ref/module-dependencies.md`

## Why

Current tests validate analyzer behavior (`ana_*`) but do not verify end-to-end doc parity. A dedicated validator will prevent drift between terminal analysis and documentation outputs.

## Proposed Test Location

- `val/utl/doc/ref_pipeline_parity_test.sh`

## Proposed Approach

1. Prepare shell context by sourcing required layers (`cfg/core/ric`, `lib/gen/aux`, `lib/gen/ana`, `cfg/ali/sta`).
2. Execute each cycle in stable output mode (prefer JSON-backed generator outputs to avoid ANSI/noise).
3. Regenerate relevant `doc/ref/*` files via `./utl/doc/run_all_doc.sh` targets.
4. Compare normalized representations (row-level comparisons, not raw full-file diffs).
5. Fail with focused mismatch output per pipeline.

## Acceptance Criteria

- One test script covers all four pipelines.
- Test is deterministic and CI-safe.
- Failures identify which pipeline drifted and where.
- Pass confirms parity for current generated references.

## Open Notes

- Handle alias behavior in non-interactive shells by using wrapper functions (`_ffl_*_cycle`) where needed.
- Avoid false negatives from formatting/timestamps in markdown headers.
