# Strict Mode Design Classification Mismatch Issue

- Status: active
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04 02:34
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

## Progress Checkpoint

### Done

1. Moved this item into `doc/pro/active/` with `Status: active` and canonical `## Triage Decision` answers captured.
2. Added `## Execution Plan`, `## Verification Plan`, and `## Exit Criteria` sections to make the work execution-ready.
3. Confirmed current wording mismatch scope by identifying queue items still using `**Design required:** Yes/No` phrasing.
4. Ran workflow validation: `bash doc/pro/check-workflow.sh` passed after move/update.
5. Committed activation changes on `master` as `98f5013e` (`docs(pro): move strict-mode classification issue to active`).

### In-flight

1. Phase 1 design decision is outlined but not yet written as a finalized canonical schema and migration policy.
2. Checker enforcement logic in `doc/pro/check-workflow.sh` is not yet implemented.

### Blockers

1. No hard blocker; the remaining dependency is selecting and documenting a single migration policy (rewrite-on-touch vs one-time normalization).

### Next steps

1. Complete Phase 1 by documenting the canonical classification schema and migration policy directly in this file (`doc/pro/active/20260304-0214_strict-mode-design-classification-mismatch-issue.md`).
2. Update workflow instructions to the canonical wording in `doc/pro/task/active-move`, `doc/pro/task/queue-move`, `doc/pro/task/queue-triage`, and `doc/pro/README.md`.
3. Implement classification-token validation in `doc/pro/check-workflow.sh` with actionable failure messages for missing/malformed tokens.
4. Normalize existing queue items to canonical `Design: required` or `Design: not needed` wording in `doc/pro/queue/20260303-2245_logging-performance-renewal-plan.md`, `doc/pro/queue/20260303-2246_logging-architectural-restructure-plan.md`, and `doc/pro/queue/20260303-2247_logging-visual-output-redesign-plan.md`.
5. Run `bash -n doc/pro/check-workflow.sh` and `bash doc/pro/check-workflow.sh`, then record validation results in this file.

### Context

1. Branch: `master`.
2. Working tree: clean at checkpoint start; this file is the only intended edit for this checkpoint update.
3. Latest workflow commits: `98f5013e` (move strict-mode item to active), `f38e5cac` (close OpenAI visibility plan).
4. Current active board focus: this issue is now the only active non-waiver workflow item.
5. Validation baseline before next implementation step: workflow checker currently passes.

## Execution Plan

All phases below are remaining work.

### Phase 1 - Canonical Classification Design

1. Define one canonical triage classification schema for all workflow docs (`Design: required` / `Design: not needed`) including exact heading/body placement rules.
2. Document accepted equivalent legacy forms and explicit migration policy (rewrite-on-touch vs one-time normalization) with rationale.
3. Record checker behavior requirements for strict mode and non-strict mode when classification tokens are missing or malformed.

Completion criterion:

- A documented design decision exists in this item specifying canonical tokens, placement rules, migration policy, and checker behavior.

### Phase 2 - Workflow Template and Rule Alignment

1. Update task templates and workflow documentation so all triage instructions require the same canonical classification tokens.
2. Ensure examples use exact canonical wording and remove conflicting phrase variants.

Completion criterion:

- Workflow task docs and guidance use one consistent canonical classification format with no contradictory examples.

### Phase 3 - Checker Enforcement

1. Update `doc/pro/check-workflow.sh` to validate triage classification presence/format for queue and active items.
2. Keep failure messages actionable by pointing to the exact missing/malformed token requirement.

Completion criterion:

- Checker reliably fails malformed or missing triage classification tokens and reports precise remediation guidance.

### Phase 4 - Existing Item Normalization

1. Normalize existing queue/active workflow items that still use non-canonical design phrasing.
2. Update each touched file `Updated` header while preserving filename timestamp prefixes.

Completion criterion:

- All current queue/active items pass canonical triage classification checks without manual exceptions.

### Phase 5 - Validation

1. Run workflow checker and targeted validations after doc/script updates.
2. Confirm at least one queue-to-active move path works end-to-end with strict token expectations.

Completion criterion:

- Validation evidence demonstrates canonical triage format is enforced and strict-mode move workflow proceeds predictably.

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
