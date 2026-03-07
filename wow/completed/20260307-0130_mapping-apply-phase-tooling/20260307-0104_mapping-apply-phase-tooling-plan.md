# Mapping Apply-Phase Tooling Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:28:38
- Links: wow/active/20260307-0005_planning-workspace-session-plan.md, utl/pla/map/runs/20260307-0057_present-showcase1/approved-mapping.json, utl/pla/cli

## Goal

Define and implement a safe apply-phase workflow that can ingest
`approved-mapping.json` and materialize planning entities/state bindings without
direct infrastructure side effects.

## Context

1. Artifact-first mapping is now established under `utl/pla/map/`.
2. Pilot run artifacts exist and include approved mapping output.
3. No apply mechanism exists yet to convert approved artifacts into planning DB
   entity/state records in a controlled, auditable way.
4. `approved-mapping.json` v1 already contains deterministic entity keys,
   evidence references, and a single target state (`present-showcase1`) that can
   be validated before any DB writes.
5. Existing schema constraints (`UNIQUE` keys on `plg_entity`,
   `plg_state_entity`, and `plg_cfg_binding`) can be combined with strict
   preflight checks to provide idempotent applies and collision rejection.
6. Apply implementation and targeted tests are now present in `utl/pla/cli` and
   `val/core/pla_apply_mapping_test.sh`.

## Scope

1. Define apply contract inputs and validation rules.
2. Add dry-run and apply semantics for DB-level changes only.
3. Enforce collision checks, duplicate prevention, and explicit error outputs.
4. Define rollback/recovery behavior for partial failures.

## Risks

1. Incorrect apply behavior could corrupt planning-model consistency.
2. Weak validation could allow low-confidence or malformed mappings into DB.
3. Hidden coupling to current JSON shape could break future rule versions.

## Triage Decision

- Why now: Mapping artifacts are now produced and reviewed, but without an apply step they cannot be operationalized within the planning model.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes -- direct SQL scripts, CLI subcommand, or staged import utility with strict validation.
  2. Will other code or users depend on the shape of the output? Yes -- apply behavior becomes a core interface between mapping artifacts and planning DB state.
  - Design: required
- Justification: Multiple implementation paths and high downstream dependency on import semantics require an explicit design phase.

## Next Step

Move this item to `active/` and begin with a design-phase contract for apply validation, idempotency, and rollback behavior.

## Execution Plan

### Phase 1 -- Design apply contract and control model (completed)

- [x] Define accepted input contract (`approved` output only, `v1` contract,
  high-confidence entities, target-state consistency).
- [x] Define idempotency model for entities, state bindings, and config
  bindings.
- [x] Define collision policy (reject type/label/state-kind mismatches).
- [x] Define transactional boundary and rollback behavior for apply mode.

Completion criterion: A documented design artifact in this task file that
defines interfaces, constraints, alternatives considered, and the chosen
approach.

### Phase 2 -- Implement apply pipeline in `utl/pla/cli` (completed)

- [x] Add `apply-mapping` command with explicit `--dry-run`/`--apply` modes.
- [x] Add preflight validation for payload shape, confidence, state-name, and
  binding consistency.
- [x] Emit structured operation reports and explicit validation/runtime errors.

Completion criterion: Apply-phase tooling code exists and executes end-to-end
against approved mapping input in dry-run mode.

### Phase 3 -- Add failure-handling and idempotency protections (completed)

- [x] Enforce duplicate/collision rejection paths for entity/type/label and
  state-kind mismatches.
- [x] Keep apply writes inside a single transaction with rollback on failure.
- [x] Add targeted automated tests for dry-run, idempotent reapply, collision
  rejection, and failpoint rollback behavior.

Completion criterion: Automated tests cover success, duplicate/collision, and
partial-failure recovery scenarios.

## Verification Plan

1. Add targeted tests for contract validation failures and schema/shape guardrails.
2. Add idempotency tests confirming repeat apply runs do not create duplicate DB bindings.
3. Add rollback/recovery tests that verify no partial state is left after simulated failures.
4. Run `bash wow/check-workflow.sh` to confirm workflow document compliance.

## Exit Criteria

1. Approved mapping artifacts can be processed through dry-run and apply flows with auditable, deterministic outcomes.
2. DB-level changes are guarded by validation, collision checks, and rollback protections.
3. Test coverage demonstrates safe behavior for success and failure paths.

## Phase 1 Design Decision Record

Date: 2026-03-07
Design classification: required

1. Chosen apply interface:
   - Command: `./utl/pla/cli apply-mapping [db_path] <approved_mapping_json> [--dry-run|--apply]`.
   - `--dry-run` performs full validation and action planning without
     persisting writes.
   - `--apply` performs the same validation, then executes DB writes in one
     transaction.
2. Input contract and validation gates:
   - `output_kind` must be `approved`.
   - `contract_version` must be `v1`.
   - `snapshot_id` must exist in `plg_cfg_snapshot`.
   - every proposed entity must be high confidence and include at least one
     evidence pair (`source_path`, `binding_key`).
   - every proposed state binding must target `target_state` and reference a
     declared entity key exactly once.
3. Idempotency and collision policy:
   - Entity keys are canonical; reapply reuses existing matching rows.
   - Entity collisions (same key with different type/label) are rejected.
   - Target state is created as `present` when absent; if present with other
     kind, apply fails.
   - State bindings and cfg bindings are upserted/compared so repeat apply does
     not duplicate records.
4. Transaction and rollback boundaries:
   - `--apply` writes are wrapped in one transaction and rollback on any
     validation/runtime/database exception.
   - `--dry-run` returns a structured action report and performs no commits.
   - test failpoint support (`PLY_APPLY_FAILPOINT`) is used only to verify
     rollback behavior during validation tests.
5. Alternatives considered:
   - direct SQL import script: lower implementation overhead but weaker CLI
     contract and safety ergonomics.
   - always-upsert with label/type overwrite: simpler but unsafe for accidental
     remapping collisions.
   - apply without transaction: unacceptable due to partial-write risk.
6. Final choice rationale:
   - a strict CLI contract with dry-run parity and transactional apply balances
     operator visibility, deterministic outcomes, and DB integrity while keeping
     scope limited to planning tables only.

## Progress Checkpoint

### Done

1. Implemented `apply-mapping` in `utl/pla/cli` with strict validation,
   structured JSON report output, and explicit `--dry-run`/`--apply` behavior.
2. Implemented collision/idempotency safeguards for entities, state bindings,
   and cfg bindings.
3. Added rollback failpoint hook for deterministic partial-failure validation.
4. Added `val/core/pla_apply_mapping_test.sh` covering dry-run non-persistence,
   idempotent apply, collision rejection, and rollback behavior.
5. Updated `utl/pla/README.md` and `utl/pla/ops/README.md` with the new
   operation.

### Current phase

All planned phases complete; item is closed.

### Next steps

1. Capture closeout evidence and move this item to `completed/`.

## What changed

1. Added `apply-mapping` to `utl/pla/cli` with strict preflight validation,
   deterministic dry-run/apply modes, and structured reporting.
2. Enforced idempotency/collision protections across entities, state bindings,
   and config bindings, including state-kind/type/label mismatch rejection.
3. Added transactional apply behavior with rollback on failure, including
   failpoint coverage for partial-failure simulation.
4. Added targeted test coverage in `val/core/pla_apply_mapping_test.sh` and
   updated tooling docs in `utl/pla/README.md` and `utl/pla/ops/README.md`.

## What was verified

1. `bash val/core/pla_apply_mapping_test.sh` -> PASS (`PASS: pla_apply_mapping_test`).
2. `bash wow/check-workflow.sh` -> PASS (see closeout checker run).

## What remains

- No mandatory follow-up items identified.
