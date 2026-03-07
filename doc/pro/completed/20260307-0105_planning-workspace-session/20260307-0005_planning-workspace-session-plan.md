# Planning Workspace Session Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:05
- Links: doc/man/08-planning-workspace.md, doc/arc/09-planning-subsystem.md, utl/pla/README.md, utl/pla/map/README.md, utl/pla/map/runs/20260307-0057_present-showcase1/approved-mapping.json, doc/pro/queue/20260307-0104_mapping-apply-phase-tooling-plan.md, doc/pro/queue/20260307-0105_export-summary-naming-migration-plan.md, doc/pro/queue/20260307-0106_mapping-rules-v2-client-endpoints-plan.md

## Goal

Track and refine planning-workspace improvements discovered during this session, including baseline review UX and additional follow-up items that emerge.

## Context

1. `import-present` already captures snapshot metadata and file inventory in `plg_cfg_snapshot.raw_json`.
2. `export-md` currently produces a global workspace overview, not a focused per-baseline detail report.
3. Session walkthrough feedback indicates a need for beginner-friendly review artifacts between planning steps.
4. More planning-workspace improvements are expected; this document should stay as a rolling session anchor.
5. Entity mapping decisions are currently human-driven, and automation must preserve reviewability.
6. Current `export-md` output naming is semantically redundant (`inventory-summary` vs custom overview names) and needs a consistent direction.
7. A governed artifact-first LLM mapping flow was selected to avoid direct mutation risk during early rollout.
8. Phase 2 skeleton assets were created under `utl/pla/map/` with contracts, prompts, rules, runs, and reports scaffolding.
9. Pilot run `20260307-0057_present-showcase1` produced all required run artifacts and one unresolved finding (`CL_IPS[t1]`).

## Scope

1. Keep planning behavior local-first and non-operational (no `lib/ops/*` execution).
2. Maintain a running list of planning-workspace review and UX items in one place.
3. Define a repeatable baseline-review artifact for selected `present` states.
4. Compare delivery options: dedicated CLI subcommand, helper script, or documented one-off query/export flow.
5. Define minimum review content (state metadata, snapshot metadata, file inventory, digest, and traceability links).
6. Continuously update this plan before any implementation decision.

## Risks

1. Overly detailed output may reduce readability for routine planning reviews.
2. Baseline-to-snapshot linkage is currently indirect and can become brittle if metadata conventions change.
3. Multiple present-state snapshots can cause selection ambiguity without explicit selection rules.
4. Documentation drift can occur if command behavior and manual pages are not updated together.

## Triage Decision

- Why now: The workshop reached a planning maturity point where continued discussion without a minimal contract implementation will increase ambiguity and ad hoc behavior.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes -- we can remain manual, implement docs/contracts only, or implement full automation early.
  2. Will other code or users depend on the shape of the output? Yes -- mapping artifacts and naming conventions will become shared operational interfaces.
  - Design: required
- Justification: Multiple viable solution paths and downstream dependency on output shape require explicit design control before implementation proceeds.

## Next Step

Execute follow-up queue items for apply tooling, export naming migration, and v2 mapping rule expansion.

## Execution Status

1. Phase 1 (design lock): completed.
2. Phase 2 (workspace contract skeleton): completed.
3. Phase 3 (artifact-only pilot run): completed.
4. Phase 4 (pilot quality assessment): completed.
5. Phase 5 (rollout recommendation): completed.

## Execution Plan

### Phase 1 -- Design lock for LLM mapping interface

1. [x] Finalize the design record for mapping scope, interface boundaries, confidence policy, and naming conventions.
2. [x] Resolve open decisions that influence artifact shapes (`summary-*` naming direction, unknown handling, and evidence requirements).
3. [x] Confirm which outputs are mandatory for every run and which are optional.

Completion criterion: this active item contains a concrete, approved design decision record with documented interfaces, constraints, trade-offs, and the chosen approach.

## Phase 1 Design Decision Record

Date: 2026-03-07
Design classification: required

### Interfaces and boundaries

1. Mapping flow remains artifact-first: snapshot input -> proposal artifacts -> human review -> approved artifacts.
2. No infrastructure execution is allowed in mapping phases.
3. No direct DB mutation is allowed during extraction/review phases.
4. Approved mapping artifacts are the handoff contract for any later apply phase.

### Constraints

1. Every proposed mapping row must include source evidence (`source_path` and `binding_key` equivalent).
2. Every proposed mapping row must include confidence level and a short rationale.
3. Unknown patterns must be explicit and tracked; they cannot be silently coerced.
4. Output contracts must remain stable across runs to support review diffs.

### Trade-offs considered

1. Manual-only mapping: safest but slow and inconsistent across sessions.
2. Full automated direct apply: fastest but too risky while rules are still evolving.
3. Governed artifact-first mapping (selected): balances safety, speed, and auditability.

### Chosen approach

Use governed artifact-first LLM mapping with mandatory review checkpoints and explicit confidence/evidence requirements.

### Resolved open decisions

1. Summary naming direction: use `summary-default.md` and `summary-<label>.md` as the target convention for future work; keep current names as compatibility surface until migration is explicitly scheduled.
2. Unknown handling: unknown patterns are written to `reports/unmapped-findings.md` and block trusted-plan designation until reviewed.
3. Evidence requirement: each mapping entry requires source trace + confidence + rationale.
4. Mandatory run outputs: `input-manifest.json`, `llm-proposal.json`, `reviewer-notes.md`, `approved-mapping.json`.
5. Optional output: supplemental analysis notes may be added, but required artifacts must always exist.

### Phase 1 completion status

Phase 1 completion criterion is met; implementation can proceed to Phase 2.

### Phase 2 -- Build minimal `utl/pla/map/` workspace contract skeleton

1. [x] Create the agreed `utl/pla/map/` folder layout (`contracts`, `prompts`, `rules`, `runs`, `reports`).
2. [x] Add initial contract documents and schema placeholders matching the approved design.
3. [x] Document usage intent and boundaries in `utl/pla/map/README.md`.

Completion criterion: the baseline `utl/pla/map/` structure and contract files exist and match the Phase 1 design record.

### Phase 3 -- Run one artifact-only pilot mapping cycle

1. [x] Select one baseline target (`present-showcase1`) and prepare an input manifest.
2. [x] Produce `llm-proposal.json` using the extraction prompt without direct DB mutation.
3. [x] Record reviewer feedback and publish an approved mapping artifact.

Completion criterion: one complete pilot run folder exists under `utl/pla/map/runs/` with `input-manifest.json`, `llm-proposal.json`, `reviewer-notes.md`, and `approved-mapping.json`.

### Phase 4 -- Validate pilot quality against manual expectations

1. [x] Compare pilot outputs with manual mapping expectations from the workshop.
2. [x] Log false positives, false negatives, and unresolved unknown patterns.
3. [x] Update unmapped findings report and confidence guidance if required.

Completion criterion: a single documented pilot-quality assessment exists with explicit findings and confidence outcomes.

### Phase 5 -- Decide rollout direction

1. [x] Summarize pilot outcomes and operational effort.
2. [x] Capture follow-up implementation items and priorities.
3. [x] Recommend whether to continue with broader implementation.

Completion criterion: this item records an explicit go/no-go recommendation and the next queued actions.

## Phase 4 Pilot Quality Assessment

### Findings

1. False positives: none for active v1 rules (`HY_IPS`, `CT_IPS`).
2. False negatives: none for active v1 rules in `cfg/env/site1`.
3. Unknowns: one unresolved mapping candidate (`CL_IPS[t1]`) recorded in `utl/pla/map/reports/unmapped-findings.md`.

### Confidence outcomes

1. All mapped entities were classified `high` based on deterministic alias extraction.
2. Unknown handling policy operated as intended (no silent coercion).

### Assessment result

Pilot quality is acceptable for continuing artifact-first mapping expansion under current governance.

## Phase 5 Rollout Recommendation

### Decision

Go: continue with broader implementation in controlled increments.

### Rationale

1. Contract skeleton and run artifacts are now concrete and reviewable.
2. Pilot mapping quality matched manual expectations for active v1 rule scope.
3. Remaining uncertainty is isolated and explicitly tracked as unmapped findings.

### Next queued actions

1. Create a queue item for apply-phase tooling that can ingest `approved-mapping.json` safely.
2. Create a queue item for export naming migration (`inventory-summary` to `summary-*` convention).
3. Create a queue item for v2 mapping rules covering currently unmapped client endpoint semantics.

## Verification Plan

1. Run `bash doc/pro/check-workflow.sh` after each workflow-file update.
2. Verify required workspace artifacts exist for the active phase using `test -e <path>` checks.
3. Verify pilot run deliverables are complete by checking all required files under one run directory.
4. Confirm unknown findings are recorded in `utl/pla/map/reports/unmapped-findings.md` when applicable.

## Exit Criteria

1. Phase 1 design lock is completed before implementation-heavy phases proceed.
2. Minimal `utl/pla/map/` contract skeleton exists and is consistent with the approved design.
3. One artifact-only pilot run is completed and reviewed with explicit findings.
4. Unknown patterns and confidence gaps are documented, not hidden.
5. A clear rollout recommendation and next queued actions are captured.
6. `bash doc/pro/check-workflow.sh` passes at item handoff.

## Candidate Items

1. Baseline review UX: standardize one detailed markdown export format for a selected `present` state.
2. Selection UX: define explicit snapshot-selection rules when multiple `present` states exist.
3. Export ergonomics: decide whether `export-md` should stay overview-only or support focused detail modes.
4. Export naming clarity: evaluate summary naming convention (`summary-default.md` plus `summary-<label>.md`) to replace mixed `inventory-summary`/`overview` terminology.
5. LLM mapping workflow: define a durable `utl/pla` workspace layout for contracts, prompts, runs, and review artifacts.

## Proposed LLM Mapping Workspace Layout

Use `doc/pro/` for workflow state and prioritization, and use `utl/pla/map/` for mapping artifacts and execution contracts.

```text
utl/pla/
├── cli
├── data/
├── export/
├── ops/
├── sql/
└── map/
    ├── README.md
    ├── contracts/
    │   ├── mapping-output.schema.json
    │   ├── confidence-policy.md
    │   └── key-naming-policy.md
    ├── prompts/
    │   ├── extract-v1.md
    │   └── review-v1.md
    ├── rules/
    │   └── cfg-env-v1.yaml
    ├── runs/
    │   └── yyyymmdd-hhmm_<state-or-snapshot>/
    │       ├── input-manifest.json
    │       ├── llm-proposal.json
    │       ├── reviewer-notes.md
    │       └── approved-mapping.json
    └── reports/
        └── unmapped-findings.md
```

### Layout intent

1. `contracts/`: immutable guardrails that define what the LLM is allowed to infer and how it must report confidence.
2. `prompts/`: reusable task prompts for extraction and review phases.
3. `rules/`: explicit parsing/mapping patterns for stable config conventions.
4. `runs/`: per-execution evidence and approvals for auditability.
5. `reports/`: aggregated unknowns and open modeling gaps.

## Governance Model for LLM-Assisted Mapping

### Purpose

Define how `cfg/env` patterns are translated into planning entities so mappings stay safe, reviewable, and adaptable as config evolves.

### Ownership and approval

1. Mapping owner: approves new or changed mapping rules.
2. Contributors: can propose rule updates and mapping outputs.
3. Reviewer: verifies proposed mappings against operator intent before approval.
4. Final authority: human approval is required for rule activation and for low-confidence mappings.

### Decision policy

1. `import-present` remains evidence capture only.
2. Mapping is human-in-the-loop; no silent autonomous rule activation.
3. New config patterns default to unmapped status until explicitly classified.
4. No mapping task may execute `lib/ops/*` or apply infrastructure changes.

### Rule lifecycle

1. Detect new/unmodeled config pattern in latest snapshot.
2. Propose rule with: entity type, key extraction method, label strategy, and source-path scope.
3. Run extraction in dry-run mode and produce `llm-proposal.json`.
4. Reviewer validates false positives/negatives and confidence tags.
5. Approve rule and capture rationale in `reviewer-notes.md`.
6. Re-run mapping and publish `approved-mapping.json`.

### Confidence policy

1. `high`: deterministic pattern with stable key extraction and explicit source evidence.
2. `medium`: mostly deterministic but includes assumptions (for example naming conventions).
3. `low`: heuristic guess or incomplete context; requires explicit human confirmation.

### Unknown handling policy

1. Unknown patterns must be listed explicitly in `reports/unmapped-findings.md`.
2. Unknowns are not silently coerced into existing entity types.
3. Unknowns do not block snapshot export but do block trusted-plan designation.

### Review cadence

1. Quick review after each `import-present` for drift detection.
2. Full review before generating implementation plans intended for real execution.
3. Re-review triggered when config conventions change or rule coverage regresses.

### Trusted mapping exit criteria

1. No critical unknown patterns remain unresolved.
2. Core entity types used by operations are covered with high or approved-medium confidence.
3. Reviewer sign-off exists for the current run.
4. Mapping outputs are traceable to snapshot/source evidence.

## LLM Execution Contract (Draft v1)

### Required inputs

1. Database path and target `present` state or explicit snapshot id.
2. Allowed entity types and key naming rules.
3. Active mapping rule set version.
4. Output folder for the run under `utl/pla/map/runs/`.

### Required outputs

1. `input-manifest.json`: snapshot metadata, selected files, and rule-set version.
2. `llm-proposal.json`: proposed entities, state bindings, confidence, and evidence pointers.
3. `reviewer-notes.md`: acceptance/rejection rationale for proposed mappings.
4. `approved-mapping.json`: final approved result (or explicit no-change decision).
5. `reports/unmapped-findings.md`: accumulated unresolved patterns.

### Output quality requirements

1. Every proposed mapping includes source evidence (`source_path`, `binding_key` equivalent).
2. No duplicate entity keys across incompatible types.
3. Confidence must be present for every mapping row.
4. Unknowns must be explicit, not omitted.

### Safety constraints

1. Capture and modeling only; no infrastructure mutation.
2. No direct table writes without explicit apply phase approval.
3. No hidden assumptions outside declared rules.

## What changed

1. Added governed mapping workspace scaffolding under `utl/pla/map/` (`contracts`, `prompts`, `rules`, `runs`, `reports`) with initial contract and policy documents.
2. Added pilot run artifacts under `utl/pla/map/runs/20260307-0057_present-showcase1/` (`input-manifest.json`, `llm-proposal.json`, `reviewer-notes.md`, `approved-mapping.json`).
3. Updated `utl/pla/README.md` to include the new `map/` workspace component.
4. Recorded unresolved finding `CL_IPS[t1]` in `utl/pla/map/reports/unmapped-findings.md`.
5. Created three follow-up queue items for apply-phase tooling, export naming migration, and v2 mapping rules.

## What was verified

1. Parsed pilot JSON artifacts successfully:
   - `python3 - <<'PY' ... json.load(...) ... PY` -> `json-ok` for `input-manifest.json`, `llm-proposal.json`, and `approved-mapping.json`.
2. Verified required pilot run files exist:
   - `test -e ... && printf "pilot-run-artifacts-ok"` -> `pilot-run-artifacts-ok`.
3. Workflow checks passed after state updates:
   - `bash doc/pro/check-workflow.sh` -> `Workflow check passed.`

## What remains

1. Execute `doc/pro/queue/20260307-0104_mapping-apply-phase-tooling-plan.md`.
2. Execute `doc/pro/queue/20260307-0105_export-summary-naming-migration-plan.md`.
3. Execute `doc/pro/queue/20260307-0106_mapping-rules-v2-client-endpoints-plan.md`.

## Session Update Log

- 2026-03-07: Captured plan from planning-workspace walkthrough; implementation is intentionally deferred.
- 2026-03-07 00:26: Captured naming proposal to improve sortability and clarity of summary exports; no implementation yet.
- 2026-03-07 00:46: Added detailed LLM mapping governance, folder layout, and execution-contract draft for future workflow implementation.
- 2026-03-07 00:49: Moved item from inbox to queue after triage; selected design-required path and prioritized minimal Phase A/B implementation before further workshop expansion.
- 2026-03-07 00:52: Moved item from queue to active and added design-aware execution, verification, and exit plans for implementation kickoff.
- 2026-03-07 00:53: Ran active-start, completed Phase 1 design lock, and recorded the approved design decision record.
- 2026-03-07 00:59: Completed Phase 2 skeleton build, Phase 3 pilot run artifacts, Phase 4 quality assessment, and Phase 5 rollout recommendation.
- 2026-03-07 01:05: Captured follow-up queue items and closed this item into completed state.
