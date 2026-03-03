# Bootstrapper Modern Output Plan

- Status: dismissed
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-03
- Links: bin/ini, bin/orc, lib/core/lo1, lib/core/tme, lib/core/err

## Dismissal Reason

- Scope overlaps with existing bootstrap output redesign planning items.
- Kept only one canonical planning thread to avoid duplicate execution paths.

## Goal

Redesign bootstrap terminal output to look more professional and modern while
staying minimal, efficient, and easy to scan. The result should reduce visual
noise, keep important status visible, and preserve practical diagnostics.

## Context

Current bootstrap output mixes multiple visual styles and verbosity layers,
which makes startup look busy and inconsistent. The user requests a cleaner
state-of-the-art presentation that feels intentional, not overly decorative,
and remains fast in interactive terminal use.

## Scope

- Define a compact visual model for bootstrap output (header, progress,
  completion summary, and error state).
- Unify style primitives (spacing, symbols, and color usage) across bootstrap
  log emitters.
- Keep functionality and execution flow unchanged; this is a presentation
  redesign only.
- Preserve detailed diagnostics under higher verbosity while making normal
  mode concise.
- Keep compatibility with existing terminal environments and width
  constraints.

## Risks

- Over-simplification may hide context needed for troubleshooting.
- Color and symbol choices may render inconsistently across terminals.
- Existing tests may assert output text that changes with the redesign.
- Multiple bootstrap emitters may drift unless a shared output pattern is
  enforced.

## Next Step

Create a concrete output specification with before/after examples and a
single default compact mode, then implement behind a feature flag before
promoting it to default behavior.
