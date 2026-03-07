# Completed Maintenance Essence Derivation Completion Plan

- Status: completed
- Owner: es
- Started: 2026-03-08 00:11
- Updated: 2026-03-08 00:28
- Links: wow/task/maintenance, wow/task/completed-close-bundle, wow/completed/20260307-completed_close-bundle-auto-naming/20260307-2022_completed_close-bundle-auto-naming/20260307-1644_completed-close-bundle-auto-naming-plan.md, wow/active/20260307-2123_completed-module-name-convention-rollout-plan.md

## Goal
- Complete the planned essence-based container naming flow so maintenance and bundle-close behavior derive meaningful `<essence-slug>` values instead of using generic fallback names like `_bundle`.

## Context
- The recent maintenance compaction normalized leaf and container structure successfully, but new containers were created with `_bundle` as a fallback essence.
- The original workflow direction expected essence naming to come from summary semantics, with deterministic derivation and conflict-safe reconciliation.
- Existing design notes in the completed auto-naming plan mark this behavior as intentionally planned but not yet implemented.
- Execution start findings: maintenance and bundle-close must share one canonical derivation routine to prevent name drift across entrypoints.
- Execution start findings: migration must be policy-driven (rename only when deterministic and reference-safe) to avoid unnecessary churn.
- Implementation findings: `wow/task/completed-close-bundle` and `wow/task/maintenance` now use the same deterministic essence derivation order and normalization constraints.
- Implementation findings: workflow rules/docs now explicitly disallow new `_bundle` essence writes while keeping legacy `_bundle` containers readable.
- Migration findings: migrated legacy `_bundle` containers under `wow/completed/` to derived essence names and reconciled registry + in-repo references.

## Scope
- Define and document a deterministic essence derivation policy (inputs, normalization, tie-break rules, and idempotency requirements).
- Implement/align derivation behavior across maintenance and bundle-close routing surfaces so container naming uses derived essence slugs when creating new containers.
- Define migration policy for already-created `_bundle` containers (rename/no-rename criteria, link updates, registry reconciliation, and checker-safe ordering).
- Validate with `bash wow/check-workflow.sh` before and after migration actions.

## Risks
- Post-hoc container renames can break references in workflow docs and orchestration metadata if path reconciliation is incomplete.
- Non-deterministic summarization logic can cause naming drift and registry conflicts across repeated maintenance runs.
- Aggressive migration may add churn without clear operator value if essence derivation quality is low.

## Triage Decision
- Why now: This unblocks deterministic completed-container naming and prevents further accumulation of generic `_bundle` containers that make maintenance harder.
- Design: required
- Justification: There are multiple viable derivation and migration approaches, and downstream workflow tooling and references depend on a stable container naming/output shape.

## Documentation Impact
- Docs: required
- Initial doc targets: `wow/README.md`, `wow/task/RULES.md`

## Execution Plan
- Phase 1 (design) [done]: Produce a written design decision in this item covering derivation inputs, normalization, tie-breaks, idempotency, migration criteria, and chosen trade-offs; completion criterion met with `## Design Decision (Phase 1 Deliverable)` below.
- Phase 2 (implementation) [done]: Apply the approved derivation flow across maintenance and bundle-close routing paths; completion criterion met by aligned task/docs contracts and explicit no-new-`_bundle` write rule.
- Phase 3 (migration and reconciliation) [done]: Execute the agreed migration policy for existing `_bundle` containers and reconcile links/registry records; completion criterion met with `## Migration Outcome Record (Phase 3)` decisions.

## Migration Outcome Record (Phase 3)
- Renamed 46 legacy containers from `yyyymmdd-<module>_bundle` to derived `yyyymmdd-<module>_<essence-slug>` names.
- Derivation source for this migration: `wow/completed/.bundle-registry.tsv` source-item path basename, normalized with the shared canonical essence rules.
- Reconciled references in-place across `wow/` text docs/templates and updated registry folder-name entries with no day+module conflicts.

## Design Decision (Phase 1 Deliverable)
- Interfaces and inputs: derive `<essence-slug>` from a canonical input set in order: explicit close summary title, normalized task title fallback, then stable legacy fallback token only when both semantic sources are empty.
- Normalization constraints: lowercase ASCII, collapse non-alphanumeric runs to single `-`, trim edge dashes, enforce max slug length with deterministic truncation, and reserve `_bundle` only as legacy-read compatibility (not new writes).
- Tie-break and idempotency rules: if multiple candidates are available, choose the highest-ranked non-empty canonical source; if collision occurs for the same day+module key, resolve by deterministic suffixing tied to stable content hash so repeated runs produce identical names.
- Migration policy: rename existing `_bundle` containers only when derived essence is stable and all discovered references can be rewritten in one transaction-like pass; otherwise mark container as intentionally unchanged with reason.
- Registry and reference reconciliation: update `completed/.bundle-registry.tsv` and any workflow links in the same ordered operation (derive -> verify uniqueness -> rewrite refs -> update registry -> run checker) to avoid transient mismatch states.
- Trade-off and chosen approach: prefer deterministic, conservative migration over aggressive renaming to maximize safety and predictability for operators and downstream tooling.

## Verification Plan
- Run `bash -n` on each modified script file related to maintenance and bundle-close behavior.
- Run targeted workflow task/script tests that cover derivation, routing, and registry reconciliation paths.
- Verify documentation updates in `wow/README.md` and `wow/task/RULES.md` are committed in this same workflow item.
- Run `./utl/ref/run_all_doc.sh` if structural/public reference surfaces change, and record the result.
- Run `bash wow/check-workflow.sh` and require a clean pass before closeout.

## Exit Criteria
- Deterministic essence derivation is documented and used by new maintenance/bundle-close container routing.
- Existing `_bundle` container handling follows the documented migration policy with reconciled references.
- Documentation changes are applied and all required verification steps pass.

## What changed
- Aligned `wow/task/completed-close-bundle` and `wow/task/maintenance` to the same deterministic essence derivation and normalization order to prevent name drift.
- Enforced no new `_bundle` essence writes while preserving legacy-read compatibility for existing containers.
- Migrated legacy `_bundle` completed containers to derived essence names and reconciled `wow/completed/.bundle-registry.tsv` plus in-repo workflow references.
- Updated workflow documentation in `wow/README.md` and `wow/task/RULES.md` to reflect the v2 container naming and migration policy.

## What was verified
- `bash wow/check-workflow.sh` (pass)
- Docs: updated (`wow/README.md`, `wow/task/RULES.md`)

## What remains
- None.
