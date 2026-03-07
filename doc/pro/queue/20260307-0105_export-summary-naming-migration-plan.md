# Export Summary Naming Migration Plan

- Status: queue
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:05
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

Move this item to `active/` after apply-phase tooling design starts, and produce a compatibility-first migration plan.
