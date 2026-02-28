# ERR Pipeline Expansion (Active Plan)

- Status: active
- Owner: es
- Created: 2026-03-01
- Scope: `cfg/ali/sta`, `lib/gen/ana`, `utl/doc/generators`, `utl/doc/run_all_doc.sh`, `utl/doc/config/targets`, `doc/ref`

## Goal

Add a seventh reference pipeline at parity with LAF/ACU/RDP/DEP/TST/SCP by integrating
`ana_err` into:

- alias cycle API (`ffl-err_*`, `ffl-err_cycle`)
- documentation generation (`utl/doc/generators/err`)
- reference output (`doc/ref/error-handling.md`)

## Why this matters

- Keeps analyzer-to-doc parity consistent across all reference pipelines.
- Makes error/exit-pattern findings visible in generated docs, not only terminal output.
- Reduces drift between `cfg/ali/sta` cycle behavior and `doc/ref/*.md`.

## Non-goals

- No redesign of `ana_err` detection heuristics beyond compatibility flags needed for docs.
- No behavior changes to existing pipelines (`laf`, `acu`, `rdp`, `dep`, `tst`, `scp`).
- No changes to live environment files under `cfg/env/`.

## Preconditions

1. `ana_err` remains callable in both table mode and `-j` mode.
2. Existing doc generator chain (`utl/doc/run_all_doc.sh`) continues to run from repo root.
3. New target naming follows existing user-facing convention (`kebab-case` target name).

## Planned scope and exact deliverables

1. **Second-layer alias wrappers in `cfg/ali/sta`**
   - Add private wrappers: `_ffl_err_go`, `_ffl_err_bin`, `_ffl_err_core`, `_ffl_err_gen`, `_ffl_err_ops`, `_ffl_err_src`, `_ffl_err_utl`, `_ffl_err_cycle`.
   - Add public aliases: `ffl-err_go`, `ffl-err_bin`, `ffl-err_core`, `ffl-err_gen`, `ffl-err_ops`, `ffl-err_src`, `ffl-err_utl`, `ffl-err_cycle`.
   - Keep cycle scope aligned with parity pipelines: root `go`, `bin`, `lib/*`, `src`, `utl`.

2. **`ana_err` doc-pipeline compatibility in `lib/gen/ana`**
   - Add/confirm `--json-dir <dir>` support so generator writes are collision-safe.
   - Add/confirm empty argument compatibility (`""`) from `aux_ffl` wrappers.
   - Preserve default behavior when `--json-dir` is omitted.

3. **New generator `utl/doc/generators/err`**
   - Invoke `ana_err -j --json-dir .tmp/doc/err`.
   - Parse analyzer JSON and render a stable markdown table for error-handling findings.
   - Write/update only the auto-generated section in `doc/ref/error-handling.md`.

4. **Orchestrator/config wiring**
   - Add target mapping `error-handling -> err` in `utl/doc/run_all_doc.sh`.
   - Add output and section mappings for `err` in `utl/doc/config/targets`.

5. **Reference docs updates**
   - Add `doc/ref/error-handling.md` with required auto-generated section markers.
   - Update `doc/ref/README.md` with the new pipeline and cycle parity mapping.
   - Update `utl/doc/README.md` with `err` generator and `.tmp/doc/err` namespace notes.

## File-level execution map

- `cfg/ali/sta`: new `ffl-err_*` wrappers and aliases.
- `lib/gen/ana`: `ana_err` options/compatibility behavior for doc generation.
- `utl/doc/generators/err`: new generator script.
- `utl/doc/run_all_doc.sh`: target registration.
- `utl/doc/config/targets`: output path + section key mapping.
- `doc/ref/error-handling.md`: new generated reference page scaffold.
- `doc/ref/README.md`: parity docs update.
- `utl/doc/README.md`: architecture and temp namespace update.

## Implementation phases

### Phase 1 - analyzer contract hardening

1. Validate current `ana_err -j` JSON structure and required fields.
2. Implement/confirm `--json-dir` support with default fallback unchanged.
3. Implement/confirm empty-argument handling compatibility with wrapper calls.

### Phase 2 - alias cycle parity

1. Add `_ffl_err_*` wrappers mirroring existing cycle conventions.
2. Add public `ffl-err_*` aliases and include `ffl-err_cycle`.
3. Confirm cycle breadth matches parity scope (go/bin/lib/src/utl).

### Phase 3 - generator implementation

1. Create `utl/doc/generators/err` with consistent generator contract.
2. Read analyzer JSON from `.tmp/doc/err` only.
3. Render deterministic markdown rows (stable ordering, consistent columns).

### Phase 4 - orchestration and documentation wiring

1. Register `error-handling` in orchestrator and target config.
2. Add new reference page scaffold with auto-generated block delimiters.
3. Update both readmes (`doc/ref/README.md`, `utl/doc/README.md`).

### Phase 5 - validation and parity proof

1. Syntax check changed scripts (`bash -n`).
2. Run `./utl/doc/run_all_doc.sh --list` and verify `error-handling` target presence.
3. Run `./utl/doc/run_all_doc.sh error-handling` and verify successful generation.
4. Run/inspect `_ffl_err_cycle -j` output and compare with `doc/ref/error-handling.md` rows.

## Validation checklist (operator-ready)

1. `bash -n lib/gen/ana`
2. `bash -n cfg/ali/sta`
3. `bash -n utl/doc/generators/err`
4. `bash -n utl/doc/run_all_doc.sh`
5. `./utl/doc/run_all_doc.sh --list`
6. `./utl/doc/run_all_doc.sh error-handling`
7. `./val/lib/gen/ana_err_test.sh`
8. Optional parity sweep: `./utl/doc/run_all_doc.sh functions variables dependencies module-dependencies test-coverage scope-integrity error-handling`

## Acceptance criteria

- `error-handling` appears in doc generator target list.
- `doc/ref/error-handling.md` is generated with non-empty analyzer-derived rows.
- `_ffl_err_cycle` exists and runs across parity scope without missing wrapper entries.
- Cycle output and reference markdown content are row-parity aligned for the same scope.
- Existing reference pipelines continue to generate without regressions.

## Risks and mitigations

- JSON shape mismatch risk between `ana_err` and new generator.
  - Mitigation: freeze expected keys in generator parser and fail clearly on missing keys.
- Alias drift risk (private wrappers present but public aliases missing, or inverse).
  - Mitigation: update wrappers and public aliases in one patch and verify via `ffl-*` listing.
- Temp-data cross-contamination risk in `.tmp/doc`.
  - Mitigation: force namespaced writes/reads under `.tmp/doc/err` only.
- Regression risk for existing doc targets.
  - Mitigation: run optional full doc regeneration after `error-handling` passes.

## Rollback plan

1. Remove `err` target wiring from `utl/doc/run_all_doc.sh` and `utl/doc/config/targets`.
2. Remove `utl/doc/generators/err` and `doc/ref/error-handling.md`.
3. Remove `ffl-err_*` aliases/wrappers from `cfg/ali/sta`.
4. Revert `ana_err` compatibility changes only if they were introduced solely for this pipeline.

## Handoff note

Execution is intentionally out of scope for this document update. This file is
the full implementation plan and validation contract for manual execution.
