# Spec Hierarchy and Enforcement Improvement Plan

- Status: active
- Owner: es
- Started: 2026-02-27
- Updated: 2026-02-27
- Links: `lib/.spec`, `lib/core/.spec`, `lib/gen/.spec`, `lib/ops/.spec`, `doc/pro/queue/spec-hierarchy-and-enforcement-plan.md`

This plan turns the current hierarchy work into an enforcement-grade standards model.

## Goal

Deliver a professional, testable, and non-contradictory `.spec` framework where:

- `lib/.spec` is concise and global-only.
- Module specs are strict specializations (`core`, `gen`, `ops`) with no scope bleed.
- Validation rules in `val/` can be enforced gradually, then switched to strict mode.

## Why this is active now

Current `.spec` files have strong direction but are not yet fully enforcement-ready:

- `lib/.spec` mixes global baseline with deep `ops`-only policy and migration guidance.
- Some language is advisory where enforcement requires normative wording.
- Duplication across files increases drift risk.

## Scope

In scope:

- Refactor `.spec` content by scope and precedence.
- Normalize rule language to enforceable terms.
- Define a direct mapping from rules to compliance checks.

Out of scope:

- Runtime behavior refactors in `lib/ops`.
- Live infrastructure execution.

## Workstreams

## 1) Baseline normalization (`lib/.spec`)

1. Keep only global requirements that apply to all `lib/*` modules.
2. Remove module-specific deep policy from global file.
3. Convert broad guidance into short, testable rules.

Deliverable:

- A compact global baseline with explicit MUST/SHOULD semantics.

## 2) Module specialization tightening

1. Keep `lib/core/.spec` bootstrap-safe and minimal dependency focused.
2. Keep `lib/gen/.spec` helper/utility constraints and help-contract expectations.
3. Move all `ops`-exclusive standards into `lib/ops/.spec`.

Deliverable:

- Clear separation of concerns with no rule duplication.

## 3) Enforcement mapping to `val/`

1. Build a rule-to-test matrix (rule id -> test check).
2. Add report mode first for `core` and `gen` compliance checks.
3. Define strict-mode cutover criteria.

Deliverable:

- Enforceable checks aligned to documented rules.

## 4) Language and professionalism pass

1. Standardize normative terms (`MUST`, `SHOULD`, `MAY`) across all `.spec` files.
2. Eliminate conflicting statements and ambiguous exceptions.
3. Keep examples short and non-authoritative (rules first, examples second).

Deliverable:

- Consistent professional tone and interpretation-safe wording.

## Execution sequence

1. Draft target outline for `lib/.spec` (global-only).
2. Relocate `ops`-specific sections from `lib/.spec` to `lib/ops/.spec`.
3. Run a contradiction/duplication pass across all four `.spec` files.
4. Update compliance tests in report mode.
5. Remediate gaps module-by-module.
6. Switch enforcement to strict mode after pass criteria are met.

## Acceptance criteria

- No module-specific policy remains in `lib/.spec`.
- Each `.spec` states scope, inheritance, and conflict behavior.
- Every MUST rule is either already checked in `val/` or has a planned check.
- No contradictory rule pairs remain across global and module specs.

## Risks and mitigations

- Risk: over-specification creates noisy failures.
  - Mitigation: keep baseline short; move guidance into docs, not normative spec.
- Risk: parser misses extensionless Bash function styles.
  - Mitigation: validate checks against representative files in `lib/core`, `lib/gen`, `lib/ops`.
- Risk: rollout churn in documentation blocks.
  - Mitigation: report-mode first, strict mode only after module cleanup.

## Immediate next actions

1. Create a proposed trimmed outline for `lib/.spec`.
2. Mark and extract `ops`-only sections currently living in `lib/.spec`.
3. Draft the rule-to-test matrix for `val/` implementation.
