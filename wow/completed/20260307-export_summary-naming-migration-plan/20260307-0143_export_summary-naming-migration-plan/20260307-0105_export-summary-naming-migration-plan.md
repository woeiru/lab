# Export Summary Naming Migration Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:41:28
- Links: wow/active/20260307-0005_planning-workspace-session-plan.md, utl/pla/cli, utl/pla/export/README.md, doc/man/08-planning-workspace.md

## Goal

Migrate planning export naming toward a consistent summary convention
(`summary-default.md` and `summary-<label>.md`) while preserving compatibility
with existing paths.

## Context

1. Current naming is mixed (`inventory-summary.md` and custom overview names).
2. Export types are functionally similar but named inconsistently.
3. Session design record selected `summary-*` as future direction.
4. `utl/pla/cli export-md` now defaults to `utl/pla/export/summary-default.md`.
5. Default exports are mirrored to `utl/pla/export/inventory-summary.md` for compatibility.
6. Existing automation may rely on default invocation side effects rather than explicit output paths.

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

Validate close-readiness against exit criteria and route this item for close review.

## Execution Plan

### Phase 1 -- Finalize migration design contract

- [x] Document canonical summary filenames, compatibility alias behavior, and deprecation window policy.
- [x] Record interfaces, constraints, trade-offs, and the chosen migration approach.

Completion criterion: A design decision record in this task file captures interfaces, constraints, trade-offs, and the selected approach.

### Phase 2 -- Implement compatibility-first naming behavior

- [x] Update export defaults to produce `summary-default.md` and `summary-<label>.md`.
- [x] Preserve compatibility for legacy naming paths during the transition window.

Completion criterion: `utl/pla/cli` applies the new naming convention by default while keeping documented legacy compatibility behavior.

### Phase 3 -- Align docs and transition guidance

- [x] Update planning workspace docs to reflect canonical `summary-*` naming.
- [x] Add explicit migration guidance for users/scripts that still reference legacy paths.

Completion criterion: Documentation under planning/export references only canonical names plus an explicit transition section for legacy usage.

## Verification Plan

1. Run targeted export-path tests to verify default and labeled outputs use `summary-*` naming.
2. Run compatibility checks to confirm legacy path references continue to resolve during the transition window.
3. Validate documentation examples against implemented CLI behavior.
4. Run `bash wow/check-workflow.sh` and address any workflow compliance failures.

## Exit Criteria

1. Export naming defaults consistently use `summary-default.md` and `summary-<label>.md`.
2. Legacy naming remains supported according to the documented compatibility policy.
3. Documentation and user guidance match the implemented migration behavior.

## Phase 1 Design Decision Record

Date: 2026-03-07
Design classification: required

1. Chosen interface and canonical filenames:
   - CLI interface remains `./utl/pla/cli export-md [db_path] [output_path]`.
   - Canonical default output is `utl/pla/export/summary-default.md`.
   - Canonical labeled outputs use `summary-<label>.md` when callers provide explicit output paths.
2. Compatibility policy and transition window:
   - Legacy filename `utl/pla/export/inventory-summary.md` remains supported during migration.
   - When `export-md` is called without `output_path`, tooling writes canonical output and mirrors the same content to the legacy filename.
   - Explicit caller-provided output paths remain pass-through (including legacy and custom paths).
   - Deprecation window stays open until a dedicated follow-up task explicitly removes legacy mirroring.
3. Constraints and invariants:
   - Preserve existing command signature and positional argument behavior.
   - Keep report content format unchanged; migration scope is naming only.
   - Avoid destructive file behavior; only write/update output files.
4. Alternatives considered:
   - Hard rename (write only canonical file): rejected because default-path users would break immediately.
   - Documentation-only migration: rejected because mixed naming would persist in tooling behavior.
   - Optional compatibility flag: rejected due to added operator complexity and weaker out-of-box compatibility.
5. Chosen approach rationale:
   - Default-to-canonical plus automatic legacy mirroring minimizes user disruption while establishing a clear long-term naming convention.

## Progress Checkpoint

### Done

1. Completed design-phase decision record with interfaces, constraints, alternatives, and chosen compatibility-first migration approach.
2. Updated `utl/pla/cli` default export naming to `summary-default.md` with automatic legacy mirror to `inventory-summary.md`.
3. Added `val/core/pla_export_naming_test.sh` covering canonical default output, legacy mirror output, and labeled summary path usage.
4. Updated planning/export docs (`utl/pla/export/README.md`, `utl/pla/README.md`, `doc/man/08-planning-workspace.md`, `doc/arc/09-planning-subsystem.md`) with canonical naming and transition guidance.

### Current phase

Phase 3 complete; all planned phases complete.

### Next steps

1. Closeout completed; no additional execution steps remain for this item.

## Verification Results

1. `bash -n utl/pla/cli` -> pass.
2. `bash -n val/core/pla_export_naming_test.sh` -> pass.
3. `bash val/core/pla_export_naming_test.sh` -> pass.
4. `bash wow/check-workflow.sh` -> pass.

## What Changed

1. Updated export default naming in `utl/pla/cli` from `inventory-summary.md` to `summary-default.md`.
2. Added compatibility mirroring so default exports also write `utl/pla/export/inventory-summary.md` during the migration window.
3. Added targeted validation in `val/core/pla_export_naming_test.sh` for canonical default, legacy mirror, and labeled summary output paths.
4. Updated related docs to canonical `summary-*` naming and migration guidance in `utl/pla/export/README.md`, `utl/pla/README.md`, `doc/man/08-planning-workspace.md`, and `doc/arc/09-planning-subsystem.md`.
5. Recorded design decision and phase completion evidence in this task file.

## What Was Verified

1. `bash -n utl/pla/cli` -> pass.
2. `bash -n val/core/pla_export_naming_test.sh` -> pass.
3. `bash val/core/pla_export_naming_test.sh` -> pass.
4. `bash wow/check-workflow.sh` -> pass.

## What Remains

No mandatory follow-up items remain.
