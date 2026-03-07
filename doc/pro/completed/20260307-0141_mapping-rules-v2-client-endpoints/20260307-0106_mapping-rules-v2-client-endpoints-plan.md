# Mapping Rules v2 Client Endpoints Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:41:12
- Links: doc/pro/completed/20260307-0110_planning-workspace-session/20260307-0005_planning-workspace-session-plan.md, utl/pla/map/rules/cfg-env-v1.yaml, utl/pla/map/rules/cfg-env-v2.yaml, utl/pla/map/reports/unmapped-findings.md, utl/pla/map/runs/20260307-0134_present-showcase1-v2/approved-mapping.json, cfg/env/site1

## Goal

Define v2 mapping rules for unresolved client-endpoint semantics (for example
`CL_IPS`) and fold them into governed artifact-first mapping runs.

## Context

1. Pilot run identified `CL_IPS[t1]` as unresolved by v1 rules.
2. Current rule set intentionally leaves client endpoint semantics unmapped.
3. Unknown findings should be reduced in controlled increments.

## Scope

1. Determine canonical type mapping for client endpoints.
2. Extend rule schema and extraction logic where needed.
3. Define confidence and evidence expectations for new v2 rules.
4. Validate v2 behavior on at least one existing snapshot run.

## Risks

1. Misclassification can distort planning model semantics.
2. Rule broadening can introduce false positives.
3. Type decisions may require upstream model adjustments.

## Triage Decision

- Why now: A concrete unresolved finding is already tracked, and leaving it unresolved blocks trusted-plan maturity for broader automation.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes -- classify as host, classify as service, or introduce a refined type policy for endpoint semantics.
  2. Will other code or users depend on the shape of the output? Yes -- entity typing and keys influence planning diffs, exports, and future apply behavior.
  - Design: required
- Justification: This change affects model semantics and downstream workflows, so type decisions need explicit design review.

## Execution Plan

### Phase 1 -- Design decision record for client-endpoint mapping semantics (completed)

- [x] Document interfaces, constraints, trade-offs, and chosen v2 mapping approach.

Completion criterion: A committed decision document defines interfaces,
constraints, trade-offs, and the chosen mapping approach.

### Phase 2 -- Implement v2 rule schema and extraction changes from Phase 1 (completed)

- [x] Add v2 rule set and prompt contracts for client-endpoint semantics.
- [x] Publish v2 run artifacts aligned with the selected approach.

Completion criterion: Mapping code and rule artifacts are updated in-tree for
client-endpoint semantics with no unresolved TODO markers.

### Phase 3 -- Run governed validation on an existing snapshot and review output (completed)

- [x] Execute dry-run apply validation against `snapshot_id=1` showcase artifacts.
- [x] Record validation output and classification evidence in run artifacts.

Completion criterion: One validation run completes and records the
client-endpoint result classification in its report artifact.

## Verification Plan

1. Execute the mapping pipeline against a known snapshot previously containing
   `CL_IPS` unresolved findings.
2. Confirm expected entity type and key output align with the Phase 1 design.
3. Compare before/after unknown findings and document deltas in the run report.

## Exit Criteria

1. A design decision record is approved and linked from this item.
2. v2 client-endpoint rule changes are merged with tests or validation evidence.
3. The targeted unresolved client-endpoint finding is resolved or explicitly
   reclassified with rationale in artifacts.

## Phase 1 Design Decision Record

Date: 2026-03-07
Design classification: required

1. Chosen interface and output shape:
   - Keep `contract_version` at `v1` for mapping output payload compatibility.
   - Introduce `utl/pla/map/rules/cfg-env-v2.yaml` as the active ruleset for
     this follow-up run.
   - Keep entity surface in existing apply-compatible types; map
     `CL_IPS[*]` aliases into `host` entities.
2. Chosen client-endpoint policy:
   - Rule ID: `cl-ips-to-host-endpoint`.
   - Extraction source remains `assoc_array` over `CL_IPS`.
   - Key template remains alias-stable (`{alias}`) to keep diffs deterministic.
   - Label template becomes `Client endpoint {alias}` to separate endpoint
     intent from hypervisor host labels.
3. Confidence and evidence contract for v2 client endpoints:
   - Confidence is `high` only when a direct `CL_IPS[alias]` evidence tuple is
     present from the selected source file.
   - Every endpoint entity requires explicit `source_path` and `binding_key`
     evidence, matching existing mapping schema and apply validation gates.
4. Constraints and invariants:
   - Do not introduce a new entity type in this phase because apply tooling
     currently enforces a fixed type set.
   - Preserve key naming policy and state-binding semantics used by existing
     review/apply workflows.
   - Keep run-folder immutability by creating a fresh v2 run folder.
5. Alternatives considered:
   - Map endpoints to `service` (`svc-*`): rejected because endpoint aliases are
     host-like nodes rather than service roles.
   - Introduce a new `client_endpoint` type: rejected for this phase because it
     would require schema and apply-path type-surface expansion.
   - Keep reporting-only behavior: rejected because unresolved findings would
     remain open and block trusted-plan maturity.
6. Chosen approach rationale:
   - `host` typing with endpoint-specific labels resolves the known unknown now,
     stays compatible with current apply contracts, and preserves deterministic
     key behavior for future diffs.

## Progress Checkpoint

### Done

1. Completed design decision record with interfaces, constraints, trade-offs,
   and chosen client-endpoint mapping policy.
2. Added v2 mapping rules and prompt documents for extraction/review.
3. Published a v2 showcase run with approved endpoint classification and updated
   unresolved-findings tracking.
4. Executed governed dry-run apply validation against existing snapshot
   `snapshot_id=1` and captured report evidence.

### Current phase

All planned phases complete; item closed.

## What changed

1. Added v2 mapping rule set in `utl/pla/map/rules/cfg-env-v2.yaml`, including
   explicit `CL_IPS` classification policy (`cl-ips-to-host-endpoint`).
2. Added v2 extraction/review prompts in `utl/pla/map/prompts/extract-v2.md`
   and `utl/pla/map/prompts/review-v2.md`.
3. Added governed v2 run artifacts in
   `utl/pla/map/runs/20260307-0134_present-showcase1-v2/`.
4. Updated `utl/pla/map/reports/unmapped-findings.md` to close
   `CL_IPS[t1]` with v2 rationale and run reference.
5. Updated `utl/pla/map/README.md` to include v2 prompt/rule references.

## What was verified

1. `./utl/pla/cli apply-mapping ./utl/pla/data/ply-showcase.db ./utl/pla/map/runs/20260307-0134_present-showcase1-v2/approved-mapping.json --dry-run`
   - Result: dry-run report recorded in
     `utl/pla/map/runs/20260307-0134_present-showcase1-v2/validation-dry-run.json`.
   - Evidence: `entities.created=9`, `state_bindings.created=9`,
     `cfg_bindings.created=9`, `snapshot_id=1`, `target_state=present-showcase1`.
2. `./utl/pla/cli apply-mapping ./utl/pla/data/ply-showcase.db ./utl/pla/map/runs/20260307-0134_present-showcase1-v2/approved-mapping.json --apply`
   - Result: apply report recorded in
     `utl/pla/map/runs/20260307-0134_present-showcase1-v2/validation-apply.json`.
   - Evidence: `entities.created=9`, `state_bindings.created=9`,
     `cfg_bindings.created=9`, `snapshot_id=1`, `target_state=present-showcase1`.
3. `bash doc/pro/check-workflow.sh`
   - Result: pass (`Workflow check passed.`).

## What remains

- No mandatory follow-up items identified.
