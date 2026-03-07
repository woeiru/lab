# Completed-Close Bundle Auto Naming Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 20:22
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

Execute a new Phase 4 to add windowed auto-bundle routing and end-of-window
summary generation while keeping existing `auto` behavior as backward-compatible
default.

## Triage Decision

- Why now: The bundle behavior is already defined and needed for imminent close transitions, so prioritizing this now avoids repeated manual folder decisions and inconsistent completed-state organization.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: This introduces new workflow semantics and deterministic naming/resolution rules that downstream tasks and operators will depend on.

## Documentation Impact

Docs: required

## Reopened

Why this needs revisiting:

1. Current `mode=auto` behavior is deterministic but still key-driven; it does not provide session-aware grouping behavior operators expect from "smart auto" mode.
2. The current bundle rule always reuses one stable `*-bundle-<slug>` folder, which is correct for stability but does not support time-windowed rollups.

Additional work required:

1. Design and implement an optional auto-window policy so repeated closes like `mode=auto module=wow` can open a new bundle period (for example, hourly) instead of reusing one folder forever.
2. Add a bundle-roundup artifact policy so each closed window receives a short end-of-window summary generated from all items closed in that window.
3. Keep backward compatibility for existing `auto`, `manual`, and `off` flows unless the new windowed option is explicitly enabled.

New exit criteria for this round:

1. A documented contract exists for windowed auto bundle routing (`module + window key`) and registry behavior.
2. Checker and task docs enforce the new behavior without breaking existing completed history.
3. At least one reopened item can be closed with the new mode and records a window summary artifact in the target bundle folder.

## Bundle Auto v2 Design Proposal

Proposed behavior:

1. Keep current behavior as default (`auto` = stable bundle by module slug).
2. Add explicit windowed mode via prompt metadata:
   - `mode=auto module=<slug> bundle_window=1h bundle_summary=on`
3. Compute bundle key as `<module-slug> + <window-start>` when `bundle_window` is present.
4. Reuse/create folder per computed windowed slug:
   - `<close-ts>-bundle-<module-slug>-w-<yyyymmdd-hhmm>`
5. Maintain deterministic registry entries keyed by full windowed slug to prevent drift.

Dynamic essence-based folder naming (requested behavior):

1. For windowed auto mode, folder naming becomes:
   - `<first-close-ts>_<module-slug>-<essence-slug>`
2. `essence-slug` is a 2-3 word summary token generated from the latest
   window summary (last close in that window).
3. During an open window, use a temporary suffix:
   - `<first-close-ts>_<module-slug>-in-progress`
4. When the window closes (first close in the next window or explicit
   finalize), compute the final essence slug and rename once to the final path.
5. Registry keeps a stable `window-id` key and current folder path so one
   controlled rename is tracked and conflict-safe.

Roundup summary contract:

1. Add/update `window-summary.md` in the bundle folder.
2. Summary includes:
   - Window range
   - Closed item count
   - 2-3 word module outcome phrase
   - Item links
3. Summary is rewritten on each close inside the same window and finalized when the first close in the next window occurs.

Compatibility and safety:

1. Existing bundle folders remain valid and are never renamed.
2. `manual` and `off` modes remain unchanged.
3. If `bundle_window` is provided without `module`, stop with missing-field guidance.
4. The one-time end-of-window rename applies only to new windowed mode and
   does not affect legacy stable bundle folders.

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
4. Verify docs token coverage is preserved in active/completed plan checks and record one docs outcome token at close.

## Exit Criteria

1. Bundle close modes (`auto`, `manual`, `off`) are documented and operable.
2. Folder naming/stability behavior is deterministic and checker-validated.
3. Required workflow docs/tasks are updated and linked in closeout evidence.

## What changed

1. Reopened this item to capture a v2 design upgrade for bundle auto behavior: optional time-windowed grouping plus end-of-window summary generation.
2. Added explicit folder naming semantics for the requested essence-based pattern in windowed mode: `<first-close-ts>_<module-slug>-<essence-slug>`, with temporary `-in-progress` naming during an open window.
3. Defined controlled finalization behavior: a one-time rename at window close to apply the final essence slug, tracked via registry `window-id` mapping.
4. Clarified compatibility boundaries: legacy stable bundle behavior remains default; rename behavior applies only to the new windowed mode.
5. Documentation files updated in this close round: none (design was captured in the reopened workflow item only).

## What was verified

1. Ran `bash wow/check-workflow.sh` after reopening updates -> `Workflow check passed.`
2. Verified completed chronology and structure by closing to `wow/completed/20260307-2022_completed-close-bundle-auto-naming/` with unchanged file timestamp prefix `20260307-1644`.
3. Docs: none (this close captured design intent; implementation/docs updates are planned in a follow-up execution round).

## What remains

1. Implement the windowed bundle-close metadata contract (`bundle_window`, `bundle_summary`) in `wow/task/completed-close-bundle` and related docs.
2. Add checker validation for the new windowed naming/finalization path and summary artifact expectations.
3. Execute an end-to-end validation scenario (same-window reuse + next-window rollover + finalized essence slug rename).
