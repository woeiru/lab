# SCP Pipeline Expansion (Active Plan)

- Status: completed
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-04
- Links: cfg/ali/sta, lib/gen/ana, utl/doc/generators/scp, utl/doc/run_all_doc.sh, doc/ref/scope-integrity.md
- Created: 2026-03-01
- Scope: `cfg/ali/sta`, `lib/gen/ana`, `utl/doc/generators`, `utl/doc/run_all_doc.sh`, `utl/doc/config/targets`, `doc/ref`

## Goal

Add a sixth reference pipeline at parity with LAF/ACU/RDP/DEP/TST by integrating
`ana_scp` into:

- alias cycle API (`ffl-scp_*`, `ffl-scp_cycle`)
- documentation generation (`utl/doc/generators/scp`)
- reference output (`doc/ref/scope-integrity.md`)

## Why this matters

- Keeps analyzer-to-doc parity consistent across all reference pipelines.
- Makes scope integrity findings visible in generated docs, not only terminal output.
- Reduces drift between `cfg/ali/sta` cycle behavior and `doc/ref/*.md`.

## Non-goals

- No redesign of `ana_scp` analysis heuristics beyond compatibility flags needed for docs.
- No behavior changes to existing pipelines (`laf`, `acu`, `rdp`, `dep`, `tst`).
- No changes to live environment files under `cfg/env/`.

## Preconditions

1. `ana_scp` remains callable in both table mode and `-j` mode.
2. Existing doc generator chain (`utl/doc/run_all_doc.sh`) continues to run from repo root.
3. New target naming follows existing user-facing convention (`kebab-case` target name).

## Planned scope and exact deliverables

1. **Second-layer alias wrappers in `cfg/ali/sta`**
   - Add private wrappers: `_ffl_scp_go`, `_ffl_scp_bin`, `_ffl_scp_core`, `_ffl_scp_gen`, `_ffl_scp_ops`, `_ffl_scp_src`, `_ffl_scp_utl`, `_ffl_scp_cycle`.
   - Add public aliases: `ffl-scp_go`, `ffl-scp_bin`, `ffl-scp_core`, `ffl-scp_gen`, `ffl-scp_ops`, `ffl-scp_src`, `ffl-scp_utl`, `ffl-scp_cycle`.
   - Keep cycle scope aligned with parity pipelines: root `go`, `bin`, `lib/*`, `src`, `utl`.

2. **`ana_scp` doc-pipeline compatibility in `lib/gen/ana`**
   - Add/confirm `--json-dir <dir>` support so generator writes are collision-safe.
   - Add/confirm empty argument compatibility (`""`) from `aux_ffl` wrappers.
   - Preserve default behavior when `--json-dir` is omitted.

3. **New generator `utl/doc/generators/scp`**
   - Invoke `ana_scp -j --json-dir .tmp/doc/scp`.
   - Parse analyzer JSON and render a stable markdown table for scope integrity findings.
   - Write/update only the auto-generated section in `doc/ref/scope-integrity.md`.

4. **Orchestrator/config wiring**
   - Add target mapping `scope-integrity -> scp` in `utl/doc/run_all_doc.sh`.
   - Add output and section mappings for `scp` in `utl/doc/config/targets`.

5. **Reference docs updates**
   - Add `doc/ref/scope-integrity.md` with required auto-generated section markers.
   - Update `doc/ref/README.md` with the new pipeline and cycle parity mapping.
   - Update `utl/doc/README.md` with `scp` generator and `.tmp/doc/scp` namespace notes.

## File-level execution map

- `cfg/ali/sta`: new `ffl-scp_*` wrappers and aliases.
- `lib/gen/ana`: `ana_scp` options/compatibility behavior for doc generation.
- `utl/doc/generators/scp`: new generator script.
- `utl/doc/run_all_doc.sh`: target registration.
- `utl/doc/config/targets`: output path + section key mapping.
- `doc/ref/scope-integrity.md`: new generated reference page scaffold.
- `doc/ref/README.md`: parity docs update.
- `utl/doc/README.md`: architecture and temp namespace update.

## Implementation phases

### Phase 1 - analyzer contract hardening

1. Validate current `ana_scp -j` JSON structure and required fields.
2. Implement/confirm `--json-dir` support with default fallback unchanged.
3. Implement/confirm empty-argument handling compatibility with wrapper calls.

### Phase 2 - alias cycle parity

1. Add `_ffl_scp_*` wrappers mirroring existing cycle conventions.
2. Add public `ffl-scp_*` aliases and include `ffl-scp_cycle`.
3. Confirm cycle breadth matches parity scope (go/bin/lib/src/utl).

### Phase 3 - generator implementation

1. Create `utl/doc/generators/scp` with consistent generator contract.
2. Read analyzer JSON from `.tmp/doc/scp` only.
3. Render deterministic markdown rows (stable ordering, consistent columns).

### Phase 4 - orchestration and documentation wiring

1. Register `scope-integrity` in orchestrator and target config.
2. Add new reference page scaffold with auto-generated block delimiters.
3. Update both readmes (`doc/ref/README.md`, `utl/doc/README.md`).

### Phase 5 - validation and parity proof

1. Syntax check changed scripts (`bash -n`).
2. Run `./utl/doc/run_all_doc.sh --list` and verify `scope-integrity` target presence.
3. Run `./utl/doc/run_all_doc.sh scope-integrity` and verify successful generation.
4. Run/inspect `_ffl_scp_cycle -j` output and compare with `doc/ref/scope-integrity.md` rows.

## Validation checklist (operator-ready)

1. `bash -n lib/gen/ana`
2. `bash -n cfg/ali/sta`
3. `bash -n utl/doc/generators/scp`
4. `bash -n utl/doc/run_all_doc.sh`
5. `./utl/doc/run_all_doc.sh --list`
6. `./utl/doc/run_all_doc.sh scope-integrity`
7. `./val/lib/gen/ana_scp_test.sh`
8. Optional parity sweep: `./utl/doc/run_all_doc.sh functions variables dependencies module-dependencies test-coverage scope-integrity`

## Acceptance criteria

- `scope-integrity` appears in doc generator target list.
- `doc/ref/scope-integrity.md` is generated with non-empty analyzer-derived rows.
- `_ffl_scp_cycle` exists and runs across parity scope without missing wrapper entries.
- Cycle output and reference markdown content are row-parity aligned for the same scope.
- Existing reference pipelines continue to generate without regressions.

## Risks and mitigations

- JSON shape mismatch risk between `ana_scp` and new generator.
  - Mitigation: freeze expected keys in generator parser and fail clearly on missing keys.
- Alias drift risk (private wrappers present but public aliases missing, or inverse).
  - Mitigation: update wrappers and public aliases in one patch and verify via `ffl-*` listing.
- Temp-data cross-contamination risk in `.tmp/doc`.
  - Mitigation: force namespaced writes/reads under `.tmp/doc/scp` only.
- Regression risk for existing doc targets.
  - Mitigation: run optional full doc regeneration after `scope-integrity` passes.

## Rollback plan

1. Remove `scp` target wiring from `utl/doc/run_all_doc.sh` and `utl/doc/config/targets`.
2. Remove `utl/doc/generators/scp` and `doc/ref/scope-integrity.md`.
3. Remove `ffl-scp_*` aliases/wrappers from `cfg/ali/sta`.
4. Revert `ana_scp` compatibility changes only if they were introduced solely for this pipeline.

## Handoff note

Execution is intentionally out of scope for this document update. This file is
the full implementation plan and validation contract for manual execution.
