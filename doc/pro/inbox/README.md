# Inbox

This folder stores ideas, issues, and plans not started yet.

## Naming standard

- Prefix every filename with `yyyymmdd-hhmm_`.
- After the prefix, use lowercase kebab-case.
- End with one of: `-plan.md`, `-issue.md`, `-review.md`, `-followup.md`.
- Keep names short and topic-focused.

## Suffix meanings

- `-issue.md`: problem statement, impact, and evidence; solution not yet committed.
- `-plan.md`: proposed or selected approach for implementation.
- `-review.md`: assessment of existing implementation/work.
- `-followup.md`: next-step item derived from prior work.

By default, follow-up items created during close/converge actions go to
`doc/pro/inbox/`. Direct `doc/pro/queue/` routing is reserved for mandatory,
already-scoped, priority-locked follow-ups.

## Current items

- Naming now follows the timestamp prefix rule.

## Required header

Each inbox file should include:

```md
- Status: inbox
- Owner: <name>
- Started: YYYY-MM-DD | n/a
- Updated: YYYY-MM-DD
- Links: none | related docs/tests/PRs
```
