# src/set Bootstrapper and Logging Alignment Plan

- Status: queue
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-05 22:56
- Links: src/set/.menu, src/set/h1, src/set/c1, src/set/c2, src/set/c3, src/set/t1, src/set/t2, bin/ini, bin/orc, lib/core/log, lib/gen/aux, doc/arc/07-logging-and-error-handling.md

## Goal

Align `src/set` playbook execution with the revamped bootstrapper and logging
system so deployment scripts remain predictable, debuggable, and consistent
across interactive and execution modes.

## Context

1. The bootstrapper redesign changed how modules are sourced and initialized.
2. The logging redesign introduced stricter structured logging expectations and
   severity gating behavior.
3. Existing `src/set` assets still include legacy startup and output patterns,
   including plain debug prints and direct sourcing assumptions.
4. Without alignment, `src/set` may diverge from the current runtime contract,
   causing brittle execution or inconsistent operator feedback.

## Scope

1. Audit all `src/set` runbooks and `.menu` for bootstrap dependency and source
   order assumptions against current bootstrap flow.
2. Replace legacy logging touchpoints in the `src/set` layer with the modern
   logging interfaces while preserving intentional menu/display output.
3. Standardize entrypoint behavior (`-i`, `-x`, usage, return codes, and setup)
   to match current bootstrap and runtime conventions.
4. Add or adjust validation coverage for `src/set` execution paths under current
   logging defaults and debug-level overrides.
5. Update related documentation so `src/set` behavior matches the current
   architecture narrative.

## Risks

1. Shared `.menu` changes can impact every host runbook at once.
2. Logging migration may accidentally suppress critical operator-visible details.
3. Bootstrap alignment may reveal hidden dependencies on legacy globals.
4. Interactive output quality could regress if menu rendering and structured
   logging are not cleanly separated.

## Triage Decision

1. Why now: `src/set` is directly exposed to the bootstrapper and logging
   revamps, so delaying alignment increases drift and raises operational risk.
2. Design classification questions:
   - Are there meaningful alternatives for how to solve this? Yes.
   - Will other code or users depend on the shape of the output? Yes.
3. Design: required
4. Justification: the migration has multiple viable implementation paths and its
   output contract affects runbooks, operators, and downstream tests/docs.

## Next Step

Start this queued item by moving it to `doc/pro/active/` with a phased
execution order: shared `.menu` first, then runbook files, then validation and
docs.
