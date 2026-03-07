# Completed-Close Bundle Auto Naming Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 16:56
- Links: wow/task/completed-close, wow/task/README.md, wow/task/RULES.md, wow/check-workflow.sh

## Goal

Add an optional `completed-close-bundle auto` mode that groups related completed
items into a single completed topic folder when they share a module context.

## Context

1. Two independent projects can finish around the same phase and touch the same
   module, but current `completed-close` behavior creates separate close folders.
2. The requested behavior is to support shared close destination without
   requiring program/child plan orchestration.
3. Bundle naming direction is pre-aligned to
   `<first-close-timestamp>-bundle-<module-slug>`.
4. This item is now in active execution with a design-first phase because
   folder-resolution semantics and close behavior create downstream dependencies.
5. Implementation now includes a dedicated `completed-close-bundle` task surface,
   updated workflow docs/rules, and checker support for bundle folder patterns
   plus duplicate bundle-folder detection by module slug.

## Scope

1. Add bundle-aware close task behavior (for example: `completed-close-bundle auto`).
2. Auto-group by deterministic key (module), with manual override support.
3. Use one stable folder name format:
   `<first-close-timestamp>-bundle-<module-slug>`.
4. Reuse existing bundle folder once created; do not rename later.
5. Persist bundle mapping so later closes resolve to the same folder path.

## Risks

1. Incorrect module metadata can route unrelated items into the same bundle.
2. Missing/ambiguous module values can produce non-deterministic grouping.
3. Concurrent close operations may race without a lock or atomic registry write.

## Next Step

Execute Phase 2 by adding/updating bundle-close task surfaces and checker rules
to enforce deterministic folder naming and stable bundle reuse.

## Triage Decision

- Why now: The bundle behavior is already defined and needed for imminent close transitions, so prioritizing this now avoids repeated manual folder decisions and inconsistent completed-state organization.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: This introduces new workflow semantics and deterministic naming/resolution rules that downstream tasks and operators will depend on.

## Documentation Impact

Docs: required

Initial doc targets:

1. wow/task/completed-close
2. wow/task/README.md
3. wow/task/RULES.md
4. wow/README.md

## Execution Plan

Phase 1 - Design baseline (COMPLETE)

1. [x] Define `completed-close-bundle` operating modes and metadata contract.
2. [x] Define deterministic folder resolution and bundle registry behavior.
3. [x] Define checker and task-surface update boundaries.
Completion criterion: A concrete design deliverable documents interfaces,
constraints, trade-offs, and the chosen approach for bundle close behavior.

Phase 2 - Task/checker implementation (COMPLETE)

1. [x] Map implementation touch-set and dependency order.
2. [x] Add/adjust workflow task templates for bundle close operations.
3. [x] Implement checker support for bundle folder naming and stability rules.
Completion criterion: Workflow tasks and checker enforce bundle-close semantics
for `auto`, `manual`, and `off` modes.

Phase 3 - Validation and closeout prep (COMPLETE)

1. [x] Run workflow validation and syntax checks for touched scripts.
2. [x] Verify documentation updates reflect final behavior.
3. [x] Prepare closeout evidence and any mandatory follow-up routes.
Completion criterion: Validation evidence is recorded and the item is ready for
`completed-close` without unresolved blockers.

## Phase 1 Design Deliverable

### Interfaces

1. Add a bundle-aware close operation contract with modes:
   - `auto`: infer bundle by module metadata and reuse/create stable folder.
   - `manual`: use explicit bundle identifier override.
   - `off`: retain current `completed-close` behavior.
2. Bundle folder naming contract:
   - `<first-close-timestamp>-bundle-<module-slug>`
3. Bundle resolution order:
   - `close_bundle` override when present
   - shared module key fallback
   - `off` fallback when no deterministic key exists

### Constraints

1. Keep existing file timestamp prefixes unchanged during close.
2. Keep bundle folder path stable after first creation (no rename on later closes).
3. Ensure checker compatibility with existing completed-topic rules.
4. Preserve backward compatibility for non-bundle close flows.

### Trade-offs

1. Registry-backed determinism vs recomputed naming:
   - Chosen registry approach avoids drift across sessions.
2. Single module-key grouping vs fuzzy similarity:
   - Chosen deterministic metadata avoids accidental co-grouping.
3. Immediate strict checker enforcement vs phased enforcement:
   - Prefer immediate clear checks to prevent inconsistent folder states.

### Chosen Approach

1. Introduce explicit bundle-close workflow task surface.
2. Persist module-to-folder mapping in a small registry under `wow/`.
3. Validate naming and stability in checker logic.
4. Keep bundle behavior opt-in so default close flow remains unchanged.

## Verification Plan

1. Run `bash -n wow/check-workflow.sh` if checker logic changes.
2. Run `bash wow/check-workflow.sh` after each workflow-doc/task update.
3. Verify doc target paths are updated before closeout.

## Exit Criteria

1. Bundle close modes (`auto`, `manual`, `off`) are documented and operable.
2. Folder naming/stability behavior is deterministic and checker-validated.
3. Required workflow docs/tasks are updated and linked in closeout evidence.

## What changed

1. Added a new bundle-aware close task template at `wow/task/completed-close-bundle` with mode handling (`auto`, `manual`, `off`), deterministic slug normalization, folder reuse/create rules, and registry contract guidance.
2. Updated workflow task contracts in `wow/task/completed-close`, `wow/task/README.md`, and `wow/task/RULES.md` to document bundle-close behavior and accepted completed folder formats.
3. Updated operator guidance in `wow/README.md` with bundle-close quickstart, completed-folder organization rules, checker expectations, and remediation guidance.
4. Extended checker logic in `wow/check-workflow.sh` to accept both completed topic-folder patterns and enforce one stable bundle folder per module slug.
5. Documentation files updated: `wow/task/completed-close`, `wow/task/completed-close-bundle`, `wow/task/README.md`, `wow/task/RULES.md`, `wow/README.md`.

## What was verified

1. Ran `bash -n wow/check-workflow.sh` -> pass.
2. Ran `bash wow/check-workflow.sh` -> `Workflow check passed.`
3. Docs: updated (`wow/task/completed-close`, `wow/task/completed-close-bundle`, `wow/task/README.md`, `wow/task/RULES.md`, `wow/README.md`).

## What remains

1. None for this workflow update; bundle-close behavior is documented and checker-covered for immediate use.
