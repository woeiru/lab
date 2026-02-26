# AGENTS.md -- experiments workflow

This file applies to work under `doc/pro/experiments/`.

## Goal

Implement and evaluate alternative plans independently without cross-contaminating changes.

## Branching rules

1. Create one branch per plan from `main` (or the agreed base branch).
2. Use `e/` prefix for experiment branches.
3. Keep each branch focused on a single plan.

Recommended names:

- `e/ini-perf-plan-1`
- `e/ini-perf-plan-2`
- `e/ini-perf-plan-4`

## Isolation rules

1. Do not mix plan implementations in one branch.
2. Do not cherry-pick between plan branches unless explicitly requested.
3. If common prep work is needed, put it in a separate baseline branch first.

## Validation rules

For each plan branch, run at minimum:

1. `bash -n` for edited scripts.
2. Nearest relevant test script(s) under `val/`.
3. Any plan-specific benchmark/measurement steps documented in that plan file.

## Commit guidance

- Keep commits small and plan-specific.
- Use clear scope prefixes when useful, for example:
  - `exp(plan-1): ...`
  - `exp(plan-2): ...`
  - `exp(plan-4): ...`

## Comparison output

When a plan branch is ready, record:

1. What changed.
2. Measured performance impact.
3. Risk/tradeoffs.
4. Recommendation (keep, revise, or reject).
