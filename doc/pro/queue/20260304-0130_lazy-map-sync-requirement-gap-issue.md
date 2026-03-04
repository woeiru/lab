# Lazy Map Sync Requirement Gap

- Status: queue
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04
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

## Next Step

Triaged owner should move this item to `queue/` and define a small, explicit
documentation + validation patch set that:

1. makes lazy-map sync a canonical requirement,
2. wires that requirement into AGENTS + module-writing workflow docs, and
3. adds a parity check test to prevent recurrence.
