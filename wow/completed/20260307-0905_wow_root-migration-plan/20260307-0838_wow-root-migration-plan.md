# WOW Root Migration Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 16:06
- Links: wow/task/queue-move, wow/task/active-move, wow/task/completed-close, wow/task/RULES.md, wow/README.md

## Goal

Define a safe, repository-wide migration plan to move the workflow board from
the legacy nested workflow path to root `wow/` while preserving behavior,
validation, and operator muscle memory.

## Context

1. The previous workflow state and task templates lived under a legacy nested
   board path.
2. The requested target is a top-level `wow/` directory as the canonical home.
3. Existing references, scripts, and guardrails previously pointed to that
   legacy path and must be updated consistently to avoid checker and workflow
   breakage.
4. `wow/` is selected to preserve compact naming while keeping a mnemonic link
   to "workflow".
5. Migration execution completed with `wow/check-workflow.sh` passing and
   `./val/core/agents_md_test.sh` passing after path updates.

## Phase 1 Design Note

### Interfaces and command surface

1. Canonical board root changes from the legacy nested board path to `wow/`.
2. Canonical checker command changes from the legacy board location to
   `bash wow/check-workflow.sh`.
3. Canonical task template entrypoints change from the legacy board location
   to `wow/task/*`.

### Mapping and invariants

1. Apply path-parity mapping for all board content:
   `legacy-board/<segment>` -> `wow/<segment>`.
2. Preserve filename timestamp prefixes and topic names across moves.
3. Keep folder semantics unchanged (`inbox`, `queue`, `active`, `completed`,
   `dismissed`, `experiments`, `task`, `check-workflow.sh`).
4. Keep status-field values unchanged (do not introduce a new status vocabulary).

### Compatibility strategy

1. Use hard cutover in tracked docs/scripts to remove the legacy nested board
   path as the primary location.
2. Allow historical references inside immutable/history-style records where
   rewriting is unnecessary for behavior.
3. Post-cutover validation must confirm no live operational instructions still
   require the legacy nested board path.

### Cutover order

1. Update active migration plan to lock design and naming.
2. Move the legacy board directory to root `wow/`.
3. Rewrite tracked references from the legacy path to `wow/` where they are
   operationally active.
4. Run `bash wow/check-workflow.sh` and targeted workflow/doc validations.
5. Record closure notes and any compatibility follow-ups.

## Scope

1. Inventory all repository references to the legacy nested board path in
   scripts, docs, and task templates.
2. Define migration mapping from `legacy-board/**` to `wow/**` with path
   parity.
3. Move workflow directories/files in one atomic change set and preserve
   filename timestamps.
4. Update checker and workflow tooling paths so `bash wow/check-workflow.sh`
   becomes the canonical validation command.
5. Update all task templates and operating references (including AGENTS and
   workflow docs) to point to `wow/`.
6. Run workflow checker and focused repo tests to confirm no broken references.

## Risks

1. Partial path updates can leave hidden references to the legacy board path
   and cause workflow drift.
2. Template/task instructions may become inconsistent if checker command text is
   not migrated everywhere.
3. External automation or user aliases may still target old paths and fail.
4. Large move commits can obscure review unless rename tracking is clean.

## Triage Decision

- Why now: Naming should be finalized before implementation to avoid duplicate
  reference updates and churn in scripts/docs.
- Are there meaningful alternatives for how to solve this? Yes.
- Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: Folder naming and migration shape affect every path reference,
  checker command, and user workflow entrypoint.

## Next Step

Closed as completed; no further execution is required on this item.

## Execution Plan

1. Phase 1 (Design) [done]: Produce a migration design note that defines final
   directory naming (`wow/`), path mapping rules, compatibility strategy, and
   cutover order; completion criterion: design note added to this item.
2. Phase 2 (Implementation) [done]: Apply one coordinated repository patch
   that moves `legacy-board/**` to `wow/**` and updates all in-repo
   references/tooling paths;
   completion criterion: migration patch applied with path parity.
3. Phase 3 (Validation) [done]: Run workflow and repo checks after migration;
   completion criterion: validation commands pass with no migration-related
   failures.

## Verification Plan

1. Pre-move baseline: run the checker from the legacy board location and record
   any existing failures.
2. Post-move workflow check: run `bash wow/check-workflow.sh` and require pass.
3. Reference audit: search for stale legacy-path references in tracked docs and
   scripts and confirm only intentional compatibility mentions remain.
4. Regression check: run focused validation scripts impacted by path-sensitive
   docs/tooling and confirm no new failures.

## Exit Criteria

1. Workflow board exists canonically at root `wow/` with the same operational
   structure previously used under the legacy nested board path.
2. In-repo references and checker instructions point to `wow/` consistently.
3. Validation is green for migrated workflow checks and impacted test/docs
   paths.
4. A short migration summary is documented with final outcomes and any
   compatibility follow-up.

## Execution Update

1. Completed move: legacy nested board path -> `wow/` with directory structure
   parity.
2. Updated active workflow/task/checker references across docs/specs/aliases to
   `wow/`.
3. Fixed `wow/check-workflow.sh` repo-root resolution for root-level board
   placement.
4. Validation results:
   - `bash wow/check-workflow.sh` -> pass
   - `./val/core/agents_md_test.sh` -> pass

## What changed

1. Moved workflow board root from the legacy nested board path to `wow/` with
   full folder structure parity.
2. Repointed active workflow docs, task templates, architecture/manual docs,
   and spec references from the legacy board path to `wow/`.
3. Updated workflow aliases in `cfg/ali/dyn` to the `c.wow.*` and `v.wow.*`
   naming family.
4. Updated `wow/check-workflow.sh` repo-root detection for root-level execution.

## What was verified

1. `bash -n wow/check-workflow.sh` -> pass.
2. `bash wow/check-workflow.sh` -> pass.
3. `./val/core/agents_md_test.sh` -> all tests passed (59/59).
4. Repository-wide legacy-path audit returned no active non-historical
   references remaining.

## What remains

1. Optional: regenerate generated reference artifacts if you want historical
   stats snapshots to reflect `wow/` paths (`./utl/doc/run_all_doc.sh`).
2. No mandatory follow-up item identified; default routing not used.
