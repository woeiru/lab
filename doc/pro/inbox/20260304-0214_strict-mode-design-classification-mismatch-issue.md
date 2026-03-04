# Strict Mode Design Classification Mismatch Issue

- Status: inbox
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04
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

## Suggested Follow-up Work

1. Pick a canonical field format for triage design classification.
2. Update task templates and `doc/pro/README.md` to match exactly.
3. Add checker enforcement for the canonical format.
4. Normalize existing queue/active docs to the chosen format.
