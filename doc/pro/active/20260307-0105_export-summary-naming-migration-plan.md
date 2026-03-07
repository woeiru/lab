# Export Summary Naming Migration Plan

- Status: active
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:28
- Links: doc/pro/active/20260307-0005_planning-workspace-session-plan.md, utl/pla/cli, utl/pla/export/README.md, doc/man/08-planning-workspace.md

## Goal

Migrate planning export naming toward a consistent summary convention
(`summary-default.md` and `summary-<label>.md`) while preserving compatibility
with existing paths.

## Context

1. Current naming is mixed (`inventory-summary.md` and custom overview names).
2. Export types are functionally similar but named inconsistently.
3. Session design record selected `summary-*` as future direction.

## Scope

1. Define migration strategy and compatibility window.
2. Update default path behavior and documentation references.
3. Add transition guidance for existing users and scripts.
4. Validate that report generation and review flow remain unchanged.

## Risks

1. Breaking path expectations in existing local workflows.
2. Documentation/code drift during transition.
3. Ambiguity if both old and new names coexist without policy.

## Triage Decision

- Why now: Naming inconsistency is now a known friction point and has already been addressed at design level, so migration planning should happen before more exports accumulate.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes -- hard rename, soft alias period, or documentation-only convention with delayed code change.
  2. Will other code or users depend on the shape of the output? Yes -- output path names are user-facing and referenced across docs and workflows.
  - Design: required
- Justification: Migration approach materially affects compatibility and user-facing contracts, so design must be explicit first.

## Next Step

Complete Phase 1 by documenting the migration contract and compatibility policy before implementation work begins.

## Execution Plan

### Phase 1 -- Finalize migration design contract

- [ ] Document canonical summary filenames, compatibility alias behavior, and deprecation window policy.
- [ ] Record interfaces, constraints, trade-offs, and the chosen migration approach.

Completion criterion: A design decision record in this task file captures interfaces, constraints, trade-offs, and the selected approach.

### Phase 2 -- Implement compatibility-first naming behavior

- [ ] Update export defaults to produce `summary-default.md` and `summary-<label>.md`.
- [ ] Preserve compatibility for legacy naming paths during the transition window.

Completion criterion: `utl/pla/cli` applies the new naming convention by default while keeping documented legacy compatibility behavior.

### Phase 3 -- Align docs and transition guidance

- [ ] Update planning workspace docs to reflect canonical `summary-*` naming.
- [ ] Add explicit migration guidance for users/scripts that still reference legacy paths.

Completion criterion: Documentation under planning/export references only canonical names plus an explicit transition section for legacy usage.

## Verification Plan

1. Run targeted export-path tests to verify default and labeled outputs use `summary-*` naming.
2. Run compatibility checks to confirm legacy path references continue to resolve during the transition window.
3. Validate documentation examples against implemented CLI behavior.
4. Run `bash doc/pro/check-workflow.sh` and address any workflow compliance failures.

## Exit Criteria

1. Export naming defaults consistently use `summary-default.md` and `summary-<label>.md`.
2. Legacy naming remains supported according to the documented compatibility policy.
3. Documentation and user guidance match the implemented migration behavior.
