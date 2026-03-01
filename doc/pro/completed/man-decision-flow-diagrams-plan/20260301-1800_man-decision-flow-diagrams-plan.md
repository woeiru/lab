# Man Decision Flow Diagrams Plan

- Status: completed
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-01 (completed)
- Links: doc/man/README.md (Decision flow diagrams standard), doc/man/07-dev-session-attribution-workflow.md (reference implementation)

## Goal

Add mermaid decision flow diagrams and summary tables to manual docs that
present multiple commands, modes, or execution paths -- per the quality
standard added to `doc/man/README.md`.

`05-writing-modules.md` is excluded: it is prescriptive with a single
mandatory pattern and no branching operator decisions.

## Triage Decision

This item is promoted directly to active because it is already fully scoped,
ordered by impact, and implementation-ready with concrete target files,
placement rules, and done criteria. Queue is skipped to reduce operator
guidance drift and unblock immediate documentation quality updates in the
highest-confusion manual sections (`03-cli-usage.md` and `04-deployments.md`).

## Implementation items

### 1. 03-cli-usage.md (highest priority)

Strongest candidate. Three distinct decision surfaces:

**Diagram A -- Direct call vs DIC call:**
- Calling functions directly in the shell (`gpu_ptd ...`) vs through DIC (`ops gpu ptd ...`).
- Decision point: ad-hoc debugging/testing vs day-to-day operation.

**Diagram B -- DIC execution mode selection:**
- Preview mode (no arguments) -- inspect injected values.
- Hybrid mode (provide some args, DIC fills the rest).
- Injection mode (`-j`) -- fully environment-driven.
- Pass-through (`-x`) -- for functions requiring an execute flag.
- Decision points: "do you know the arguments?", "want full injection?", "function uses -x flag?".

**Diagram C -- Dev session attribution command selection:**
- Already covered by `07-dev-session-attribution-workflow.md`. Consider a
  brief cross-reference diagram or link rather than duplicating the full flow.

Summary table columns: command/mode, when to use, side effects.

Place after the intro paragraph, before Section 1.

### 2. 04-deployments.md (high priority)

Two clear decision surfaces:

**Diagram A -- Runbook execution mode:**
- Interactive mode (`-i`) -- guided menu, multi-section.
- Direct mode (`-x <section>`) -- immediate, bounded, single-section.
- Decision point: "running a known single section?" vs "exploring or running multiple sections?".

**Diagram B -- Validation scope after changes:**
- Syntax-check only (`bash -n`) for quick edits.
- Category tests (`./val/run_all_tests.sh src`) for module-scoped changes.
- Full suite (`./val/run_all_tests.sh`) for structural changes.
- Decision points: "single file edit?", "multiple files in one module?", "cross-module change?".

Summary table columns: mode/scope, when to use, side effects.

Place after the intro paragraph, before Section 1.

### 3. 02-configuration.md (medium priority)

Two decision surfaces:

**Diagram A -- Configuration layer composition:**
- Base site file only (required minimum).
- Site + environment override (staging/production split).
- Site + environment + node override (per-host specialization).
- Decision points: "single environment?", "need per-environment values?", "need per-host overrides?".

**Diagram B -- Context switching method:**
- Manual edit of `cfg/core/ecc`.
- `env_switch` / `env_site_switch` / `env_node_switch` helpers.
- Decision points: "switching site?", "switching environment?", "switching node?".

Summary table columns: method/layer, when to use, scope of effect.

Place after the intro paragraph, before Section 1.

### 4. 01-installation.md (medium priority)

One primary decision surface:

**Diagram -- Activation pattern:**
- `lab` -- activate current shell only, no persistence.
- `lab-on` -- auto-load in every new shell.
- `./go init` -- one-time setup (prerequisite for both).
- Decision points: "first time setup?", "want persistent activation?".

The troubleshooting section (three error paths) could also benefit from a
small diagnostic diagram, but this is lower priority and optional.

Summary table columns: command, when to use, persistence.

Place after the intro paragraph, before Section 1.

### 5. 06-security-and-logging.md (lower priority)

Two moderate decision surfaces:

**Diagram A -- Logging layer selection:**
- `aux_*` (operational logging in ops modules).
- `lo1` (core runtime logging).
- `err` (error logging).
- Decision points: "writing an ops module?", "core runtime code?", "error/failure path?".

**Diagram B -- Log format selection:**
- `human` (default, terminal-friendly).
- `json` (machine-parseable).
- `csv` (tabular export).
- `kv` / `keyvalue` (structured key-value).
- Decision point: "who consumes this output?".

Summary table columns: layer/format, when to use, output destination.

Place after the intro paragraph, before Section 1.

## Excluded

- `05-writing-modules.md`: single mandatory pattern, no branching decisions.
  No diagram needed.
- `07-dev-session-attribution-workflow.md`: already done (reference implementation).

## Sequence and rationale

| Order | File | Reason |
|-------|------|--------|
| 1 | 03-cli-usage.md | Most complex decision surface, highest operator confusion risk |
| 2 | 04-deployments.md | Clear mode split, operators hit this early |
| 3 | 02-configuration.md | Layer composition is non-obvious to new operators |
| 4 | 01-installation.md | Simpler decision, but first doc operators see |
| 5 | 06-security-and-logging.md | Moderate benefit, more reference than procedural |

## Execution Plan (today)

1. Update `doc/man/03-cli-usage.md` with decision diagrams A/B and a compact
   summary table; add cross-reference (not duplication) for attribution flow.
2. Update `doc/man/04-deployments.md` with execution-mode and validation-scope
   decision diagrams plus summary table.
3. Update `doc/man/02-configuration.md` with composition/context-switch diagrams
   and summary table, then checkpoint consistency against style standard.

## Verification Plan

- Run workflow integrity check: `bash doc/pro/check-workflow.sh`.
- Validate each edited manual file for diagram placement (after intro,
  before section 1/prerequisites) and summary table completeness.
- Run markdown lint/readability spot checks for heading continuity and link
  correctness across all touched manual pages.

## Exit Criteria

- Each target doc contains a mermaid flowchart and summary table per the
  `doc/man/README.md` standard.
- Diagrams are placed after the intro paragraph, before prerequisites.
- Existing content and section numbering remain intact.
- Traceability checklist from `doc/man/README.md` passes for each changed file.
- No duplication of the `07` attribution flow in `03` -- use cross-reference.

## Review Fixes (2026-03-01)

Post-implementation review identified four issues. All fixed in-place.

### Fix 1 (high): 04-deployments.md validation scope diagram

**Problem:** The "no" branch from "Cross-module or structural change?" landed
on "Integration checks", but there is no real-world scenario that is
not-single-file, not-module-scoped, and not-cross-module. The branch was
unreachable and the four-node chain was overcomplicated.

**Fix:** Simplified to three terminal nodes: single file → syntax check +
nearest test, multiple files in one module → category tests, otherwise → full
suite. Removed the dead "integration" branch. Updated summary table to match.

### Fix 2 (high): 03-cli-usage.md DIC mode diagram

**Problem:** Preview mode (`P`) had an arrow into the `-x` execute-flag
decision node, implying operators should add `-x` to a read-only preview.
Preview is read-only and never takes `-x`.

**Fix:** Disconnected preview from the `-x` decision. Preview now terminates
at its own node ("Read-only preview output / no execution"). Hybrid and
injection modes still flow into the `-x` check.

### Fix 3 (medium): 01-installation.md diagram removed

**Problem:** `doc/man/README.md` line 67 explicitly exempts "linear
single-path procedures (e.g., installation, setup)" from decision flow
diagrams. The activation flowchart in `01` was accurate but contradicted the
project's own standard.

**Fix:** Removed the mermaid diagram. Kept the summary table (renamed heading
to "Command Summary") so operators still get the quick-reference lookup.

### Fix 4 (low): 06-security-and-logging.md logging layer diagram

**Problem:** The catch-all terminal node read "Select primary layer by
ownership and avoid duplicate messages" -- a principle, not a concrete action.
Every terminal node should map to a specific thing the operator does.

**Fix:** Replaced with "Use aux_* in lib/gen/* utilities / use lo1 elsewhere
in bootstrap chain", giving a concrete layer assignment for the remaining
code locations.

## What Changed

- Finalized the decision-flow diagram rollout plan and captured all accepted
  post-review corrections across manual docs.
- Aligned manual coverage with `doc/man/README.md` standards, including the
  linear-procedure exemption for `doc/man/01-installation.md`.
- Closed this workflow item and moved it from `doc/pro/active/` to
  `doc/pro/completed/man-decision-flow-diagrams-plan/` with the original
  filename prefix preserved.

## What Was Verified

- `bash doc/pro/check-workflow.sh` -> pass.

## What Remains

- No required follow-up remains for this plan in the current scope.
- Optional future work: add or revise diagrams only when new manual sections
  introduce meaningful branching operator decisions.
