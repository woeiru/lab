# UTL Ref Rename Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 09:31
- Links: wow/task/active-capture, wow/task/completed-close, wow/task/RULES.md, utl/ref/run_all_doc.sh, val/core/stats_generator_test.sh, doc/ref/README.md

## Retroactive Capture

- Origin: The work started as a quick request to rename `utl/doc` to a clearer folder name.
- Escalation reason: The rename touches generators, tests, aliases, and generated references across the repository, so it became a coordinated path-migration task.
- Design classification:
  - Are there meaningful alternatives for how to solve this? Yes (hard cutover vs compatibility shim vs dual-path transition).
  - Will other code or users depend on the shape of the output? Yes (operator commands, docs, tests, and generated metadata paths).
  - Design: required
- Work so far: Renamed `utl/doc` to `utl/ref`, updated path references across active docs/tests/scripts, regenerated `doc/ref/*` and stats outputs, and re-ran targeted validations.

## Triage Decision

- Why now: The directory move is already in progress and spans runtime tooling plus generated docs, so leaving it uncaptured risks drift and partial migration.
- Are there meaningful alternatives for how to solve this? Yes.
- Will other code or users depend on the shape of the output? Yes.
- Design: required

## Progress Checkpoint

### Done

- Renamed folder `utl/doc` -> `utl/ref` and preserved generator layout (`config/`, `generators/`, `run_all_doc.sh`).
- Updated primary references in `README.md`, `AGENTS.md`, `doc/README.md`, `doc/ref/README.md`, `utl/README.md`, and `utl/ref/README.md`.
- Updated generator/test/alias paths including `utl/ref/generators/stats`, `utl/ref/config/targets`, `val/core/stats_generator_test.sh`, and `cfg/ali/dyn`.
- Regenerated references/stats via `./utl/ref/run_all_doc.sh`.
- Ran syntax checks and targeted tests: `./val/core/agents_md_test.sh` and `./val/core/stats_generator_test.sh`.

### In-flight

- Final migration cleanup is still pending for workflow-state historical artifacts (`wow/` plans and old stats snapshots) that retain legacy `utl/doc` text.
- Commit packaging is pending and needs a clean scope decision in a dirty working tree.

### Blockers

- No technical blocker for the rename itself.
- Repository has unrelated concurrent changes; rename-related commit scope must be curated carefully.

### Next steps

1. Run a scoped grep audit to confirm active code and docs (excluding historical workflow archives) have no operational `utl/doc` dependencies.
2. Decide and apply compatibility stance (no shim vs temporary shim) and update docs accordingly.
3. Stage only rename-related files and prepare a focused commit message for review.

### Context

- Branch: `master`.
- Active worktree contains unrelated in-progress changes outside this rename.
- Generated docs were refreshed after the move, so `doc/ref/*` and `STATS.md` changed alongside source updates.

## Execution Plan

1. Phase 1 (Design lock): Finalize migration compatibility policy for legacy `utl/doc` invocations and alias expectations; completion criterion: one policy is documented in this item and reflected in repo docs.
2. Phase 2 (Migration hardening): Complete scoped path audit and resolve any remaining operational references in active code/docs/tests; completion criterion: no `utl/doc` hits remain in active surfaces.
3. Phase 3 (Finalize and package): Stage rename-related changes and prepare closeout-ready commit scope; completion criterion: rename patch is isolated and reviewable without unrelated files.

This item is not large enough to split; continue as a single active track.

## Exit Criteria

1. `utl/ref/` is the sole active path for reference generators and orchestrator usage.
2. Operator-facing docs and tests point to `utl/ref` commands.
3. Active code surfaces no longer require `utl/doc` for execution or validation.
4. Rename-related changes are packaged in a clean, reviewable scope.

## What changed

- Renamed `utl/doc` to `utl/ref` and updated active operational references in docs, tests, aliases, and generator code.
- Updated stats and reference generation command paths to `./utl/ref/...` and refreshed generated reference outputs.
- Updated workflow guidance references where applicable so operator-facing instructions point to `utl/ref`.

## What was verified

- `bash -n` checks passed for edited generator and test scripts (`utl/ref/generators/*`, `val/core/stats_generator_test.sh`).
- `./val/core/agents_md_test.sh` passed (59/59).
- `./val/core/stats_generator_test.sh` passed (38/38).
- `./utl/ref/run_all_doc.sh functions variables dependencies module-dependencies test-coverage scope-integrity error-handling stats` completed successfully (error-handling+stats rerun completed after initial timeout).

## What remains

- Follow-up captured in `wow/inbox/20260307-0931_utl-doc-legacy-reference-cleanup-followup.md` to decide policy for legacy `utl/doc` references in historical artifacts.
