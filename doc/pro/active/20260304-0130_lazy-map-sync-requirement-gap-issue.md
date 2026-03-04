# Lazy Map Sync Requirement Gap

- Status: active
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04 01:36
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

### Phase 2 - Documentation Alignment

Apply the Phase 1 policy to repository docs and standards so contributor and
agent workflows express one consistent lazy-map maintenance requirement.

Completion criterion: all targeted docs are updated with consistent,
non-conflicting lazy-map sync guidance.

### Phase 3 - Drift Detection Validation

Add or strengthen validation so map drift between `cfg/core/lzy` and public
functions in lazy-loaded modules is detected before merge.

Completion criterion: at least one automated test fails on intentional lazy-map
drift and passes on the baseline repository state.

### Phase 4 - Verification and Handoff

Run workflow and targeted validation checks for the patch set and capture
evidence in this item.

Completion criterion: this item records the exact commands and pass/fail
results for workflow checks and targeted tests.

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
