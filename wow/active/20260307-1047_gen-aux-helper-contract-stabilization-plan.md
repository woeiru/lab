# Gen Aux Helper Contract Stabilization Plan

- Status: active
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 11:19
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, doc/ref/reverse-dependecies.md, doc/ref/scope-integrity.md, lib/gen/aux

## Goal

Stabilize the `gen/aux` helper contract to reduce fan-in blast radius while
preserving current operational behavior.

## Context

1. The completed architecture review identified `gen/aux` as the highest
   coupling hotspot by reverse-dependency fan-in.
2. Contract drift in shared helpers can produce broad regressions across
   `lib/ops/*`, `lib/gen/*`, and supporting orchestration surfaces.
3. A bounded contract-first hardening pass is now prioritized for queue
   execution.
4. Reverse-dependency telemetry shows the heaviest `gen/aux` fan-in on
   `aux_err`, `aux_info`, `aux_use`, `aux_chk`, `aux_val`, and `aux_cmd`, so
   these helpers define the minimum no-break contract boundary.
5. Formatter and metadata helpers (`aux_get_log_color`,
   `aux_get_cluster_metadata`, `aux_format_json_log`,
   `aux_format_csv_log`) currently have no runtime callers outside
   `lib/gen/aux`, making them suitable for internal-only treatment.

## Scope

1. Define the stable public helper surface for `gen/aux`.
2. Classify helpers into stable API vs internal-only utilities.
3. Add compatibility guidance and migration notes for high-risk helper changes.
4. Add validation checks/tests for contract conformance.

## Triage Decision

- Why now: `gen/aux` has the highest cross-module fan-in, so stabilizing its
  contract gives the largest immediate risk reduction.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: Multiple contract-boundary strategies exist and the chosen
  helper surface affects many modules and future refactor sequencing.

## Phase 1 Design Deliverable

### Stable public helper contract (Tier A: hard-stable)

1. Help/introspection contract: `aux_use`, `aux_tec`.
   - Guarantee: preserve call style (no required args), output remains
     human-readable text, and current `0/1` error semantics remain stable.
2. Validation/execution contract: `aux_val`, `aux_chk`, `aux_cmd`.
   - Guarantee: preserve argument order, canonical return codes
     (`0/1/2/127` where applicable), and no hidden side effects.
3. Operational logging contract: `aux_log`, `aux_dbg`, `aux_info`, `aux_warn`,
   `aux_err`, `aux_business`, `aux_audit`, `aux_perf`.
   - Guarantee: preserve level semantics, stderr terminal behavior, and
     file-write behavior gated by `LOG_DIR`.
4. Utility contract with active consumers: `aux_arr`, `aux_ask`, `aux_ffl`.
   - Guarantee: keep existing operation names/flags stable and maintain
     current recursion and validation behavior.

### Compatibility public contract (Tier B: soft-stable)

1. Keep exported for compatibility but freeze for additive fixes only:
   `aux_fun`, `aux_var`, `aux_security`, `aux_start_trace`, `aux_end_trace`,
   `aux_metric`.
2. No new module should adopt Tier B helpers until Tier A hardening is
   complete and docs are updated with explicit status.

### Internal-only helper boundary

1. Treat as non-contract internals: `aux_get_log_color`,
   `aux_get_cluster_metadata`, `aux_format_json_log`, `aux_format_csv_log`,
   `_aux_extract_metadata_value`, `_aux_escape_json_string`,
   `_aux_escape_csv_string`.
2. Phase 2 may refactor internal helpers freely as long as Tier A and Tier B
   observable behavior remains unchanged.

### Constraints

1. Preserve lazy-load API parity with `cfg/core/lzy` during stabilization; no
   function removals in this pass.
2. Preserve current call signatures and return semantics for Tier A and Tier B
   helpers.
3. Preserve logging sinks and format selectors (`AUX_LOG_FORMAT`, `LOG_DIR`,
   verbosity gates).
4. Keep rollout non-disruptive for `lib/ops/*`, `src/dic/*`, and existing
   docs/tests.

### Trade-offs considered

1. Narrowing exports immediately would reduce surface area fastest but risks
   broad breakage across lazy stubs, docs, and downstream modules.
2. Keeping all exports stable indefinitely avoids short-term risk but preserves
   long-term maintenance burden.
3. Tiered contracting (chosen) balances safety and future cleanup by freezing
   high-fan-in APIs while marking low-adoption surfaces as compatibility-only.

### Chosen approach

1. Adopt a two-tier public contract (`Tier A` hard-stable, `Tier B`
   compatibility) plus an internal helper boundary.
2. In Phase 2, implement compatibility-preserving wrappers where needed and
   centralize mutable formatter logic behind internal helpers.
3. In Phase 3, add/extend tests to enforce Tier A signatures/returns and
   verify compatibility behavior for Tier B.

## Execution Plan

1. Phase 1 - Design the stable `gen/aux` helper contract boundary. [done 2026-03-07 11:19]
   Completion criterion: A documented design artifact defines stable helper
   interfaces, constraints, trade-offs, and the chosen stabilization approach.
   Met by: `## Phase 1 Design Deliverable` in this plan.
2. Phase 2 - Apply the approved contract design in code. [in progress]
   Completion criterion: A single implementation patch set updates
   `lib/gen/aux` and any required compatibility handling for impacted callers.
3. Phase 3 - Validate contract conformance and regression safety. [pending]
   Completion criterion: Every command listed in Verification Plan completes
   successfully with no failures.

## Progress Checkpoint

### Done

1. Completed Phase 1 design deliverable with a tiered public contract,
   internal helper boundary, and compatibility policy.
2. Captured fan-in findings from generated references to prioritize hard-stable
   APIs by risk.

### In-flight

1. Phase 2 implementation prep is active: convert contract decisions into
   concrete `lib/gen/aux` boundary changes while preserving caller behavior.

### Next steps

1. Draft the exact Phase 2 patch scope for `lib/gen/aux` and required shim
   behavior.
2. Update/add tests that lock Tier A contract behavior and Tier B
   compatibility semantics.
3. Execute Verification Plan commands once implementation changes land.

## Verification Plan

1. Run syntax checks on each edited file with `bash -n <file>`.
2. Run targeted helper coverage with `./val/lib/gen/aux_test.sh`.
3. Run broader library validation with `./val/run_all_tests.sh lib` if changes extend beyond `lib/gen/aux` internals.

## Exit Criteria

1. Stable and internal-only `gen/aux` helpers are clearly classified and documented.
2. Compatibility guidance exists for any helper contract changes with cross-module impact.
3. Required validation commands and `bash wow/check-workflow.sh` pass.
