# TST Pipeline Expansion (Completed Plan)

- Status: completed
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-04
- Links: cfg/ali/sta, lib/gen/ana, utl/doc/generators/tst, utl/doc/run_all_doc.sh, doc/ref/test-coverage.md
- Created: 2026-03-01
- Completed: 2026-03-01
- Scope: `cfg/ali/sta`, `lib/gen/ana`, `utl/doc/generators`, `utl/doc/run_all_doc.sh`, `utl/doc/config/targets`, `doc/ref`

## Goal

Add a fifth reference pipeline at parity with LAF/ACU/RDP/DEP by integrating
`ana_tst` into:

- alias cycle API (`ffl-tst_*`, `ffl-tst_cycle`)
- documentation generation (`utl/doc/generators/tst`)
- reference output (`doc/ref/test-coverage.md`)

## Why this matters

- Keeps analyzer-to-doc parity consistent across all reference pipelines.
- Makes test traceability visible in generated docs, not only terminal output.
- Reduces drift between `cfg/ali/sta` cycle behavior and `doc/ref/*.md`.

## Non-goals

- No redesign of `ana_tst` output schema beyond compatibility flags needed for docs.
- No behavior changes to existing pipelines (`laf`, `acu`, `rdp`, `dep`).
- No changes to live environment files under `cfg/env/`.

## Preconditions

1. `ana_tst` remains callable in both table mode and `-j` mode.
2. Existing doc generator chain (`utl/doc/run_all_doc.sh`) continues to run from repo root.
3. New target naming follows existing user-facing convention (`kebab-case` target name).

## Planned scope and exact deliverables

1. **Second-layer alias wrappers in `cfg/ali/sta`**
   - Add private wrappers: `_ffl_tst_go`, `_ffl_tst_bin`, `_ffl_tst_core`, `_ffl_tst_gen`, `_ffl_tst_ops`, `_ffl_tst_src`, `_ffl_tst_utl`, `_ffl_tst_cycle`.
   - Add public aliases: `ffl-tst_go`, `ffl-tst_bin`, `ffl-tst_core`, `ffl-tst_gen`, `ffl-tst_ops`, `ffl-tst_src`, `ffl-tst_utl`, `ffl-tst_cycle`.
   - Keep cycle scope aligned with parity pipelines: root `go`, `bin`, `lib/*`, `src`, `utl`.

2. **`ana_tst` doc-pipeline compatibility in `lib/gen/ana`**
   - Add/confirm `--json-dir <dir>` support so generator writes are collision-safe.
   - Add/confirm empty argument compatibility (`""`) from `aux_ffl` wrappers.
   - Preserve default behavior when `--json-dir` is omitted.

3. **New generator `utl/doc/generators/tst`**
   - Invoke `ana_tst -j --json-dir .tmp/doc/tst`.
   - Parse analyzer JSON and render a stable markdown table for test traceability.
   - Write/update only the auto-generated section in `doc/ref/test-coverage.md`.

4. **Orchestrator/config wiring**
   - Add target mapping `test-coverage -> tst` in `utl/doc/run_all_doc.sh`.
   - Add output and section mappings for `tst` in `utl/doc/config/targets`.

5. **Reference docs updates**
   - Add `doc/ref/test-coverage.md` with required auto-generated section markers.
   - Update `doc/ref/README.md` with the new pipeline and cycle parity mapping.
   - Update `utl/doc/README.md` with `tst` generator and `.tmp/doc/tst` namespace notes.

## File-level execution map

- `cfg/ali/sta`: new `ffl-tst_*` wrappers and aliases.
- `lib/gen/ana`: `ana_tst` options/compatibility behavior for doc generation.
- `utl/doc/generators/tst`: new generator script.
- `utl/doc/run_all_doc.sh`: target registration.
- `utl/doc/config/targets`: output path + section key mapping.
- `doc/ref/test-coverage.md`: new generated reference page scaffold.
- `doc/ref/README.md`: parity docs update.
- `utl/doc/README.md`: architecture and temp namespace update.

## Implementation phases

### Phase 1 - analyzer contract hardening

1. Validate current `ana_tst -j` JSON structure and required fields.
2. Implement/confirm `--json-dir` support with default fallback unchanged.
3. Implement/confirm empty-argument handling compatibility with wrapper calls.

### Phase 2 - alias cycle parity

1. Add `_ffl_tst_*` wrappers mirroring existing cycle conventions.
2. Add public `ffl-tst_*` aliases and include `ffl-tst_cycle`.
3. Confirm cycle breadth matches parity scope (go/bin/lib/src/utl).

### Phase 3 - generator implementation

1. Create `utl/doc/generators/tst` with consistent generator contract.
2. Read analyzer JSON from `.tmp/doc/tst` only.
3. Render deterministic markdown rows (stable ordering, consistent columns).

### Phase 4 - orchestration and documentation wiring

1. Register `test-coverage` in orchestrator and target config.
2. Add new reference page scaffold with auto-generated block delimiters.
3. Update both readmes (`doc/ref/README.md`, `utl/doc/README.md`).

### Phase 5 - validation and parity proof

1. Syntax check changed scripts (`bash -n`).
2. Run `./utl/doc/run_all_doc.sh --list` and verify `test-coverage` target presence.
3. Run `./utl/doc/run_all_doc.sh test-coverage` and verify successful generation.
4. Run/inspect `_ffl_tst_cycle -j` output and compare with `doc/ref/test-coverage.md` rows.

## Validation checklist (operator-ready)

1. `bash -n lib/gen/ana`
2. `bash -n cfg/ali/sta`
3. `bash -n utl/doc/generators/tst`
4. `bash -n utl/doc/run_all_doc.sh`
5. `./utl/doc/run_all_doc.sh --list`
6. `./utl/doc/run_all_doc.sh test-coverage`
7. `./val/lib/gen/ana_tst_test.sh`
8. Optional parity sweep: `./utl/doc/run_all_doc.sh functions variables dependencies module-dependencies test-coverage`

## Acceptance criteria

- `test-coverage` appears in doc generator target list.
- `doc/ref/test-coverage.md` is generated with non-empty analyzer-derived rows.
- `_ffl_tst_cycle` exists and runs across parity scope without missing wrapper entries.
- Cycle output and reference markdown content are row-parity aligned for the same scope.
- Existing reference pipelines continue to generate without regressions.

## Risks and mitigations

- JSON shape mismatch risk between `ana_tst` and new generator.
  - Mitigation: freeze expected keys in generator parser and fail clearly on missing keys.
- Alias drift risk (private wrappers present but public aliases missing, or inverse).
  - Mitigation: update wrappers and public aliases in one patch and verify via `ffl-*` listing.
- Temp-data cross-contamination risk in `.tmp/doc`.
  - Mitigation: force namespaced writes/reads under `.tmp/doc/tst` only.
- Regression risk for existing doc targets.
  - Mitigation: run optional full doc regeneration after `test-coverage` passes.

## Rollback plan

1. Remove `tst` target wiring from `utl/doc/run_all_doc.sh` and `utl/doc/config/targets`.
2. Remove `utl/doc/generators/tst` and `doc/ref/test-coverage.md`.
3. Remove `ffl-tst_*` aliases/wrappers from `cfg/ali/sta`.
4. Revert `ana_tst` compatibility changes only if they were introduced solely for this pipeline.

## Completion note

Execution completed successfully. All planned deliverables were implemented,
validation checks passed, and the `test-coverage` generator target is wired at
parity with existing documentation pipelines.
