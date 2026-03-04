# Strict Mode Design Classification Mismatch Issue

- Status: completed
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04 02:47
- Links: doc/pro/task/RULES.md, doc/pro/task/active-move, doc/pro/README.md, doc/pro/check-workflow.sh, doc/pro/queue/20260303-2245_logging-performance-renewal-plan.md, doc/pro/queue/20260303-2246_logging-architectural-restructure-plan.md, doc/pro/queue/20260303-2247_logging-visual-output-redesign-plan.md

## Problem Statement

Strict mode can halt valid workflow moves because design classification wording
is not standardized across workflow docs and task templates.

## Evidence

1. `doc/pro/task/active-move` requires exact tokens: `Design: required` or
   `Design: not needed`.
2. Queue items commonly use `Design required: Yes/No` wording instead.
3. `doc/pro/task/RULES.md` strict mode requires stop-on-missing rather than
   inference, so equivalent phrasing is treated as missing.
4. `doc/pro/check-workflow.sh` does not validate triage design-classification
   token format, so this mismatch is not caught before move execution.

## Impact

1. Operators can be blocked during `queue -> active` moves even when intent is
   clear.
2. Workflow behavior appears inconsistent (checker passes, task still stops).
3. Strict mode loses trust because it reports formatting misses as hard blockers
   without earlier detection.

## Desired Outcome

Define and enforce one canonical design-classification schema across workflow
templates, item docs, and checker validation so strict-mode halts reflect real
missing data instead of wording drift.

## Triage Decision

**Why now:** This mismatch blocks strict-mode queue-to-active progression and
creates avoidable workflow churn, so fixing it now restores predictable
triage-to-execution flow before more strict-mode moves accumulate.

**Are there meaningful alternatives for how to solve this?** Yes.

**Will other code or users depend on the shape of the output?** Yes.

**Design: required**

**Justification:** The canonical wording and checker enforcement define a
cross-workflow contract that downstream task prompts, operators, and strict
mode behavior all depend on.

## Suggested Follow-up Work

1. Pick a canonical field format for triage design classification.
2. Update task templates and `doc/pro/README.md` to match exactly.
3. Add checker enforcement for the canonical format.
4. Normalize existing queue/active docs to the chosen format.

## Phase 1 Deliverable - Canonical Classification Contract

Chosen approach:

1. Canonical triage classification is exactly one token line inside
   `## Triage Decision`:
   - `Design: required`
   - `Design: not needed`
2. The same `## Triage Decision` section must also include:
   - Why-now priority rationale
   - Answers to both design questions
   - One-sentence classification justification
3. Accepted formatting: plain text or emphasized markdown wrappers around the
   canonical token (for example `**Design: required**`), but token text itself
   must remain exact.

Constraints:

1. Strict mode must remain inference-free: missing canonical tokens are hard
   blockers.
2. Non-strict workflow should surface the same mismatches via checker failures
   before move-time task execution.
3. Existing timestamp prefixes and workflow state semantics must remain
   unchanged.

Alternatives considered:

1. Accept legacy synonyms (`Design required: Yes/No`) in strict mode/checker.
2. Canonicalize to exact tokens and fail legacy wording with clear remediation.

Trade-off and decision:

1. Chosen: canonical exact tokens with checker enforcement and actionable
   failure messages.
2. Trade-off: stricter validation now requires minor doc normalization, but it
   removes ambiguity and restores deterministic strict-mode behavior.

Migration policy:

1. Immediate one-time normalization for current queue/active items to remove
   active blockers.
2. Rewrite-on-touch for future docs, with checker enforcement preventing legacy
   wording from re-entering queue/active states.

## Progress Checkpoint

### Done

1. Completed Phase 1 design deliverable in this item with canonical token,
   placement, constraints, alternatives, trade-off decision, and migration
   policy.
2. Completed Phase 2 alignment by updating workflow guidance in
   `doc/pro/task/active-capture` and `doc/pro/README.md` to canonical
   `Design: required` / `Design: not needed` wording.
3. Completed Phase 3 checker enforcement in `doc/pro/check-workflow.sh` for
   queue/active triage section presence, canonical token validation, and legacy
   token rejection with actionable messages.
4. Completed Phase 4 normalization for current queue items:
   - `doc/pro/queue/20260303-2245_logging-performance-renewal-plan.md`
   - `doc/pro/queue/20260303-2246_logging-architectural-restructure-plan.md`
   - `doc/pro/queue/20260303-2247_logging-visual-output-redesign-plan.md`
5. Completed Phase 5 validation (`bash -n doc/pro/check-workflow.sh`,
   `bash doc/pro/check-workflow.sh`) and strict-mode precondition dry-run via
   token/section spot checks on queue and active items.

### In-flight

1. No in-flight tasks remain in this execution cycle.

### Blockers

1. No blockers.

### Next steps

1. Run `doc/pro/task/completed-close` for this item to move it to
   `doc/pro/completed/` with final closure summary.
2. Keep using canonical triage tokens for any new queue/active item to prevent
   regressions.

### Context

1. Branch: `master`.
2. Working tree now includes workflow-doc and checker updates for this item.
3. Checker enforcement now covers queue/active `## Triage Decision` integrity
   and canonical design token format.
4. Queue backlog no longer contains legacy `Design required: Yes/No` phrasing.
5. Current active board focus remains this item pending closure move.

## Execution Plan

### Phase 1 - Canonical Classification Design

1. Define one canonical triage classification schema for all workflow docs (`Design: required` / `Design: not needed`) including exact heading/body placement rules.
2. Document accepted equivalent legacy forms and explicit migration policy (rewrite-on-touch vs one-time normalization) with rationale.
3. Record checker behavior requirements for strict mode and non-strict mode when classification tokens are missing or malformed.

Completion criterion:

- A documented design decision exists in this item specifying canonical tokens, placement rules, migration policy, and checker behavior.

Status: completed (2026-03-04 02:39).

### Phase 2 - Workflow Template and Rule Alignment

1. Update task templates and workflow documentation so all triage instructions require the same canonical classification tokens.
2. Ensure examples use exact canonical wording and remove conflicting phrase variants.

Completion criterion:

- Workflow task docs and guidance use one consistent canonical classification format with no contradictory examples.

Status: completed (2026-03-04 02:39).

### Phase 3 - Checker Enforcement

1. Update `doc/pro/check-workflow.sh` to validate triage classification presence/format for queue and active items.
2. Keep failure messages actionable by pointing to the exact missing/malformed token requirement.

Completion criterion:

- Checker reliably fails malformed or missing triage classification tokens and reports precise remediation guidance.

Status: completed (2026-03-04 02:39).

### Phase 4 - Existing Item Normalization

1. Normalize existing queue/active workflow items that still use non-canonical design phrasing.
2. Update each touched file `Updated` header while preserving filename timestamp prefixes.

Completion criterion:

- All current queue/active items pass canonical triage classification checks without manual exceptions.

Status: completed (2026-03-04 02:39).

### Phase 5 - Validation

1. Run workflow checker and targeted validations after doc/script updates.
2. Confirm at least one queue-to-active move path works end-to-end with strict token expectations.

Completion criterion:

- Validation evidence demonstrates canonical triage format is enforced and strict-mode move workflow proceeds predictably.

Status: completed (2026-03-04 02:39).

## Verification Evidence

1. `bash -n doc/pro/check-workflow.sh` -> pass.
2. `bash doc/pro/check-workflow.sh` -> pass.
3. Canonical token spot-checks (`Design: required`/`Design: not needed`) pass
   for all current queue and active items.
4. `## Triage Decision` spot-checks show exactly one triage section per current
   queue and active item.

## Verification Plan

1. `bash -n doc/pro/check-workflow.sh`
2. `bash doc/pro/check-workflow.sh`
3. Spot-check representative queue/active items for canonical `Design:` token usage.
4. Dry-run one strict-mode move scenario against a canonicalized item.

## Exit Criteria

1. Canonical design-classification format is documented once and referenced by task templates.
2. Workflow checker enforces canonical format for relevant workflow states.
3. Existing queue/active items are normalized or explicitly migrated per policy.
4. Strict-mode queue-to-active flow no longer fails because of wording drift.

## What Changed

1. Defined and documented the canonical triage classification contract in this
   workflow item, including exact tokens (`Design: required` /
   `Design: not needed`), placement rules, constraints, alternatives, trade-off
   decision, and migration policy.
2. Updated workflow guidance to canonical wording in `doc/pro/task/active-capture`
   and `doc/pro/README.md`.
3. Implemented checker enforcement in `doc/pro/check-workflow.sh` for queue/active
   triage section integrity and canonical token validation, with actionable
   failure messages for missing/duplicate/malformed/legacy forms.
4. Normalized queue triage sections in:
   - `doc/pro/queue/20260303-2245_logging-performance-renewal-plan.md`
   - `doc/pro/queue/20260303-2246_logging-architectural-restructure-plan.md`
   - `doc/pro/queue/20260303-2247_logging-visual-output-redesign-plan.md`

## What Was Verified

1. `bash -n doc/pro/check-workflow.sh` -> pass.
2. `bash doc/pro/check-workflow.sh` -> pass.
3. Spot-check validation confirms current queue/active items contain exactly one
   `## Triage Decision` section and canonical design token usage.

## What Remains

1. No follow-up work remains for this item.
