# Ops Hotspot Decomposition Wave Design

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 21:03
- Links: wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2103_ops_hotspot-decomposition-wave-program-plan/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md, doc/ref/stats/actual.md, doc/ref/functions.md, doc/ref/test-coverage.md, doc/ref/scope-integrity.md

## Goal

Lock Wave 1 decomposition interfaces, constraints, trade-offs, and sequencing
so implementation can proceed with low regression risk.

## Triage Decision

- Why now: Hotspot concentration is already measurable in `lib/ops/dev`,
  `lib/ops/gpu`, and `lib/gen/ana`, so delaying decomposition increases
  maintenance and review risk.
- Design classification Q1 (meaningful alternatives): Yes -- batching and
  module order materially change reviewability, rollback ease, and blast radius.
- Design classification Q2 (output shape dependencies): Yes -- follow-up
  implementation and test waves depend on stable decomposition boundaries and
  compatibility gates.
- Design: required
- Justification: The decomposition structure itself determines whether
  implementation can preserve behavior while reducing complexity.

## Documentation Impact

- Docs: required
- Target docs (initial): `wow/active/20260307-1047_ops-hotspot-decomposition-wave-program-plan.md`,
  `doc/ref/functions.md`, `doc/ref/test-coverage.md`,
  `doc/ref/module-dependencies.md`, `doc/ref/scope-integrity.md`

## Interfaces (Compatibility Contract)

Wave 1 must preserve these public signatures and current call semantics:

1. `lib/ops/gpu`
   - `gpu_ptp <step> [action] [--no-reboot]`
   - `gpu_ptd [-d driver] [gpu_id] [hostname] [config_file] [pci0_id] [pci1_id]`
   - `gpu_pta [-d driver] [gpu_id] [hostname] [config_file] [pci0_id] [pci1_id]`
   - `gpu_pts -x`
2. `lib/gen/ana`
   - `ana_acu [-o|-a|-j|-t|-b|--json-dir <dir>] <config file or directory> <target folder1> [target folder2 ...]`
   - `ana_lad <file/directory name> [-t] [-b] [-j]`

Wave 2 pre-locked interface guardrail (do not change in Wave 1):

- `lib/ops/dev`: `dev_osv`, `dev_oqu`, `dev_olb`, `dev_ois`, `dev_oac`

## Constraints

1. No external signature drift on public functions included in Wave 1.
2. No behavior drift in success/error return semantics for user-facing commands.
3. Keep decomposition patches batch-sized and reviewable (single-module focus per
   batch).
4. Maintain Bash style contracts from `lib/.spec` and `lib/ops/.spec`
   (validation flow, return codes, structured logging).
5. Validate each batch with syntax checks plus nearest module tests before
   moving to the next batch.

## Trade-offs Considered

1. Option A: module-by-module full rewrite before merge.
   - Pros: clean internal structure per module at completion.
   - Cons: large patchsets, slow feedback, difficult rollback boundaries.
2. Option B: cross-module helper extraction first.
   - Pros: early reuse and consistency improvements.
   - Cons: wider blast radius and more coupled regression surface.
3. Option C: risk-first incremental decomposition (chosen).
   - Pros: small batches, tighter rollback scope, faster compatibility feedback.
   - Cons: temporary mixed style until all waves complete.

## Chosen Approach

1. Wave 1 Batch A (`lib/ops/gpu`): split large passthrough flows into private
   helpers while keeping `gpu_ptp/gpu_ptd/gpu_pta/gpu_pts` signatures stable.
2. Wave 1 Batch B (`lib/gen/ana`): split analyzer pipelines around argument
   parsing, scan orchestration, and rendering, preserving `ana_acu/ana_lad`
   interfaces.
3. Wave 2 (`lib/ops/dev`): decompose large render and account-management flows
   after Wave 1 compatibility gates are stable.

## Compatibility Gates

Per batch, run:

1. `bash -n` on each touched file.
2. Nearest module suites:
   - `val/lib/ops/gpu_test.sh`
   - `val/lib/ops/gpu_std_compliance_test.sh`
   - `val/lib/gen/ana_dep_test.sh`
   - `val/lib/gen/ana_err_test.sh`
   - `val/lib/gen/ana_rdp_test.sh`
   - `val/lib/gen/ana_scp_test.sh`
   - `val/lib/gen/ana_tst_test.sh`
3. `./val/lib/confidence_gate.sh --risk medium <changed files>` at wave close.

## Rollback Strategy

1. Keep each batch isolated by module and scope so rollback can happen without
   undoing unrelated refactors.
2. Land helper extraction before call-site rewiring in each batch.
3. If a compatibility gate fails, revert only the current batch and retain
   previously validated batches.

## Phase 1 Completion Record

The design baseline is complete. Implementation can proceed using this document
as the source of truth for wave boundaries and compatibility guards.

## What changed

1. Closed this Wave 1 design baseline from `wow/active/` to
   `wow/completed/20260307-ops_completed-folder-module-naming-unification-plan/20260307-2103_ops_hotspot-decomposition-wave-program-plan/`.
2. Retained the finalized decomposition contracts, constraints, and wave
   sequencing used by converged workstreams.
3. Documentation files updated in this close step: none.

## What was verified

1. Parent convergence record confirms all dependent workstreams completed using
   this baseline and passed declared merge gates.
2. Wave-level verification command remains recorded in parent: `./val/lib/confidence_gate.sh --risk medium lib/ops/gpu lib/gen/ana`.
3. Docs: none (no additional documentation files were changed during closeout).

## What remains

1. Reuse this design baseline as historical input when scoping Wave 2 follow-up
   work.
