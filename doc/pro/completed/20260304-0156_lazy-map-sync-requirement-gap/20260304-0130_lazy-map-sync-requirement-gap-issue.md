# Lazy Map Sync Requirement Gap

- Status: completed
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04 01:55
- Links: cfg/core/lzy, bin/orc, lib/.spec, lib/ops/.spec, lib/gen/.spec, AGENTS.md, doc/arc/03-operational-modules.md, doc/arc/02-core-and-gen.md, doc/man/05-writing-modules.md, val/core/initialization/orc_test.sh, doc/pro/active/20260304-0028_antigravity-account-reload-persistence-plan.md

## Goal

Capture and resolve the documentation/standards gap that allowed newly added
`lib/*` functions to ship without corresponding updates to `cfg/core/lzy`, which
caused lazy-loaded function stubs to be missing in interactive bootstrap.

## Context

After the bootstrap renewal, `lib/ops/*` and `lib/gen/*` are lazy-loaded by
default, with stubs registered from `cfg/core/lzy` and fallback discovery only
when no map entry exists for a module (`bin/orc`).

Observed symptom: newly added function(s) were not added to the static lazy map,
and direct invocation failed until another function call triggered module load.
Recent live example is documented for `dev_oac` in
`doc/pro/active/20260304-0028_antigravity-account-reload-persistence-plan.md`.

Current instruction coverage appears inconsistent:

1. `doc/arc/03-operational-modules.md` explicitly says to update
   `ORC_LAZY_OPS_FUNCTIONS` in `cfg/core/lzy` when ops public functions change.
2. `lib/.spec`, `lib/ops/.spec`, and `lib/gen/.spec` do not currently define
   an explicit MUST/SHOULD requirement to keep lazy map entries in sync.
3. `AGENTS.md` mentions lazy loading from `cfg/core/lzy`, but does not include
   an explicit maintenance checklist item to update map entries for new/removed
   public functions.
4. `doc/man/05-writing-modules.md` does not currently include a lazy-map sync
   step in the module authoring workflow.
5. Existing orchestrator tests validate lazy loading behavior for selected
   symbols but do not enforce full map-to-module parity.

Findings from execution (2026-03-04):

- Canonical standards gap confirmed: `lib/.spec`, `lib/ops/.spec`, and
  `lib/gen/.spec` did not explicitly require same-patch updates to
  `cfg/core/lzy` for public function surface changes.
- Documentation gap confirmed: `doc/arc/03-operational-modules.md` carried an
  ops-only note; `doc/arc/02-core-and-gen.md`, `doc/man/05-writing-modules.md`,
  and AGENTS checklist guidance were missing equivalent explicit maintenance
  language.
- Validation gap confirmed: `val/core/initialization/orc_test.sh` covered
  selected lazy-load behavior but had no parity assertion across all lazy-loaded
  ops/gen modules.

## Scope

In scope for follow-up:

1. Decide canonical policy location for lazy-map sync requirements
   (`lib/ops/.spec`, `lib/gen/.spec`, architecture docs, and AGENTS checklist).
2. Align AGENTS guidance with canonical rule(s) so agents do not miss the map
   update when adding/removing public module functions.
3. Add or strengthen validation coverage to detect lazy-map drift (missing or
   stale function entries) before merge.
4. Update writing/maintenance docs to include lazy-map sync in standard
   function/module change workflow.

Out of scope for this inbox capture:

- Implementing code changes in loaders/modules.
- Executing infrastructure operations.

## Risks

1. New functions can be unavailable by name in default lazy mode until a module
   is loaded through another call path.
2. Fallback discovery can mask map drift, causing inconsistent behavior and
   making gaps hard to notice during casual testing.
3. Agent behavior remains non-deterministic when the required update step is
   documented in some places but missing from canonical standards/workflows.

## Triage Decision

- Why now: the gap already caused a real lazy-stub miss (`dev_oac`) and can
  recur silently on any new public function; tightening standards and checks now
  prevents repeated bootstrap/runtime surprises.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required.
- Justification: selecting canonical rule locations and enforcement approach
  affects contributor workflow, review gates, and lazy-load behavior guarantees.

## Execution Plan

### Phase 1 - Canonical Policy Design

Decide and document the canonical requirement locations and enforcement shape
for lazy-map synchronization when public functions are added, removed, or
renamed in `lib/ops/*` and `lib/gen/*`.

Completion criterion: this item includes a concrete policy matrix that maps
each canonical doc (`lib/.spec`, `lib/ops/.spec`, `lib/gen/.spec`, AGENTS,
module-writing docs) to required lazy-map sync language and the selected
parity-check enforcement approach.

Status: completed (2026-03-04 01:51).

### Phase 2 - Documentation Alignment

Apply the Phase 1 policy to repository docs and standards so contributor and
agent workflows express one consistent lazy-map maintenance requirement.

Completion criterion: all targeted docs are updated with consistent,
non-conflicting lazy-map sync guidance.

Status: completed (2026-03-04 01:51).

### Phase 3 - Drift Detection Validation

Add or strengthen validation so map drift between `cfg/core/lzy` and public
functions in lazy-loaded modules is detected before merge.

Completion criterion: at least one automated test fails on intentional lazy-map
drift and passes on the baseline repository state.

Status: completed (2026-03-04 01:50).

### Phase 4 - Verification and Handoff

Run workflow and targeted validation checks for the patch set and capture
evidence in this item.

Completion criterion: this item records the exact commands and pass/fail
results for workflow checks and targeted tests.

Status: completed (2026-03-04 01:52).

## Phase 1 Deliverable - Canonical Policy Matrix

| Canonical location | Required lazy-map sync policy | Enforcement and intent |
| --- | --- | --- |
| `lib/.spec` | Add global MUST rule: for public function add/remove/rename in `lib/ops/*` or `lib/gen/*`, update `cfg/core/lzy` map entry in same patch. | Defines project-wide baseline and ties rule to enforceability/waiver model. |
| `lib/ops/.spec` | Add ops-specific MUST rules: maintain `ORC_LAZY_OPS_FUNCTIONS["<module>"]`; fallback discovery is not a substitute. | Makes ops contract explicit where most public infra functions are added. |
| `lib/gen/.spec` | Add gen-specific MUST rules: maintain `ORC_LAZY_GEN_FUNCTIONS["<module>"]`; fallback discovery is not a substitute. | Aligns gen contract with current default lazy-loading behavior. |
| `AGENTS.md` | Add checklist bullet under documentation expectations for lazy-map sync on public function surface changes in ops/gen. | Makes agent execution deterministic and review-safe in day-to-day edits. |
| `doc/man/05-writing-modules.md` | Add module-authoring workflow step: update `cfg/core/lzy` for public function changes and run `./val/core/initialization/orc_test.sh`. | Makes contributor workflow explicit at authoring time. |
| `doc/arc/02-core-and-gen.md` + `doc/arc/03-operational-modules.md` | Keep architecture maintenance notes explicit for gen/ops lazy-map ownership and fallback semantics. | Preserves architecture-level context and avoids relying on implicit behavior. |
| `val/core/initialization/orc_test.sh` | Add parity test to compare `cfg/core/lzy` map entries vs discovered non-private module functions (excluding `main`). | Converts policy into pre-merge enforcement; catches missing/stale map entries. |

Selected enforcement approach:

1. Keep `cfg/core/lzy` as the canonical lazy stub map for known ops/gen modules.
2. Treat `bin/orc` fallback function discovery as runtime safety net only.
3. Enforce map/function parity with `val/core/initialization/orc_test.sh`.
4. Allow temporary exceptions only through explicit waiver documentation with owner/removal date (per spec language).

## Verification Evidence

1. `bash -n val/core/initialization/orc_test.sh` -> pass.
2. `./val/core/initialization/orc_test.sh` -> pass (`8/8`), including drift probe where intentional `dev_oac` map removal is detected as mismatch.
3. `./val/core/agents_md_test.sh` -> pass (`59/59`).
4. `bash doc/pro/check-workflow.sh` -> pass.

## Verification Plan

1. Run `bash doc/pro/check-workflow.sh` after each workflow doc move/edit.
2. Run `./val/core/agents_md_test.sh` if AGENTS guidance is updated.
3. Run `./val/core/initialization/orc_test.sh` for lazy-load map behavior.
4. Run the nearest validation test that enforces map/module parity once added.

## Exit Criteria

- Canonical standards define lazy-map sync as an explicit requirement for
  public function surface changes.
- AGENTS and module authoring documentation include the same maintenance step.
- Validation coverage detects lazy-map drift and is wired into routine checks.
- This item contains command evidence showing workflow and targeted validation
  checks passed.

## What Changed

1. Added explicit lazy-map synchronization requirements across canonical standards:
   - `lib/.spec` (global rule `GLB-015`)
   - `lib/ops/.spec` (`OPS-024` through `OPS-026`)
   - `lib/gen/.spec` (`GEN-001` through `GEN-003`)
2. Aligned workflow-facing docs so lazy-map maintenance is explicit in contributor and agent flows:
   - `AGENTS.md`
   - `doc/man/05-writing-modules.md`
   - `doc/arc/03-operational-modules.md`
   - `doc/arc/02-core-and-gen.md`
3. Added parity enforcement in `val/core/initialization/orc_test.sh`:
   - validates `cfg/core/lzy` map entries match discovered public function surfaces
   - includes an intentional drift probe (`dev_oac` removed in-test) to verify mismatch detection behavior
4. Updated this workflow item with design matrix, phase status tracking, findings, and command evidence.

## What Was Verified

1. `bash -n val/core/initialization/orc_test.sh` -> pass.
2. `./val/core/initialization/orc_test.sh` -> pass (`8/8`).
3. `./val/core/agents_md_test.sh` -> pass (`59/59`).
4. `bash doc/pro/check-workflow.sh` -> pass.

## What Remains

- No immediate technical follow-up remains for this gap.
- Any future lazy-map compliance regression should be captured as a new `doc/pro/inbox/*-issue.md` item with failing test evidence.
