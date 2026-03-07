# doc/ref ACU-LAF-RDP generation plan

- Status: dismissed
- Owner: es
- Started: 2026-02-28
- Updated: 2026-02-28
- Links: none

## Dismissal Reason

Superseded by updated planning tracked in newer `doc/pro` workflow items.

## Goal

Bring `doc/ref` generation in line with the ACU/LAF/RDP analysis views by:

1. Updating the two existing reference outputs (`functions.md`, `variables.md`).
2. Adding a third sibling output for reverse dependencies.
3. Using direct `ana_* -j` execution (no alias dependency, no `aux_ffl` chaining in doc generators).

## Current implementation analysis

### What exists today

- `utl/doc/run_all_doc.sh` runs `functions`, `variables`, `dependencies`, `stats`.
- `utl/doc/generators/func` already calls `ana_laf -j` per file and writes `doc/ref/functions.md`.
- `utl/doc/generators/var` does not build `doc/ref/variables.md`; it currently runs `ana_acu -o` and prints terminal output.
- `doc/ref/functions.md` and `doc/ref/variables.md` both contain auto-generated sections, but metadata and command comments are stale/inconsistent.

### Gaps vs requested behavior

- No third `doc/ref` sibling file for RDP.
- No centralized cycle scope definition for ACU/LAF/RDP equivalents.
- Existing generator logic still references alias-style command comments.
- JSON output naming currently collides across analyzers for identical target files (for example, `ana_laf -j` and `ana_rdp -j` both write `<relative_path>.json`).

## Target model

### Output files (siblings)

- `doc/ref/functions.md` (LAF view)
- `doc/ref/variables.md` (ACU view)
- `doc/ref/reverse-dependecies.md` (RDP view)

### Source-of-truth scope file

Create `utl/doc/config/analysis_scopes` to define explicit scan matrices (not aliases):

- LAF cycle scope
  - targets: `lib/core`, `lib/ops`, `lib/gen`, `utl`
- ACU cycle scope
  - configs: `cfg/core`, `cfg/env`
  - callsites: `lib`, `src`, `utl`
- RDP cycle scope
  - target sets: `lib/core`, `lib/gen`, `lib/ops`
  - callsite profiles:
    - core -> `bin`, `lib`, `utl`
    - gen -> `bin`, `lib`, `src`, `utl`
    - ops -> `lib`, `src`, `utl`

This mirrors the `ffl-*_cycle` intent while keeping generation deterministic and configurable in one place.

## Implementation plan

### Phase 1: configuration and contract

1. Add `utl/doc/config/analysis_scopes` with arrays for ACU/LAF/RDP scan inputs.
2. Extend `utl/doc/config/targets`:
   - `GENERATOR_OUTPUT_FILES[rdp]="doc/ref/reverse-dependecies.md"`
   - optional section marker mapping for `rdp`.
3. Update `utl/doc/run_all_doc.sh` generator registry to include `rdp` target.

### Phase 2: make ACU generator real

1. Refactor `utl/doc/generators/var` to run `ana_acu -j` directly for configured scopes.
2. Parse JSON outputs and render a stable markdown section in `doc/ref/variables.md`.
3. Replace alias-style command marker with generator-native command metadata.
4. Keep markers:
   - `<!-- AUTO-GENERATED SECTION: DO NOT EDIT MANUALLY -->`
   - `<!-- END AUTO-GENERATED SECTION -->`

### Phase 3: harden LAF generator

1. Keep `ana_laf -j` execution but switch scope loading to `analysis_scopes`.
2. Remove dependence on alias command strings in header comments.
3. Ensure output is derived from JSON only (not terminal table parsing).

### Phase 4: add RDP generator and third file

1. Add `utl/doc/generators/rdp`.
2. Execute `ana_rdp -j` for every configured target/callsite profile pair.
3. Build `doc/ref/reverse-dependecies.md` with:
   - aggregate per module family
   - per-target function dependency tables
   - top dependents summary
4. Include standard auto-generated section markers for future refreshes.

### Phase 5: avoid JSON collisions

Implement analyzer-specific JSON namespaces under `.tmp/doc` during generator runs:

- `.tmp/doc/laf/`
- `.tmp/doc/acu/`
- `.tmp/doc/rdp/`

Approach options:

- Preferred: extend `ana_*` with optional output path/prefix flag for doc tooling.
- Fallback: move/rename generated JSON files immediately after each analyzer call.

### Phase 6: docs and operator UX

1. Update `utl/doc/README.md` to document `rdp` and scope-based config.
2. Add command examples:
   - `./utl/doc/run_all_doc.sh functions variables rdp`
   - `./utl/doc/run_all_doc.sh rdp`
3. Add a short note in each `doc/ref/*.md` file describing which analyzer drives it.

## Data model for markdown sections

Use consistent section blocks across all three files:

1. Generated metadata block (timestamp, generator path, scope profile).
2. Coverage summary block (targets scanned, totals).
3. Main analysis table(s).
4. Optional exceptions/warnings block (missing files, parse issues).

## Validation plan

Minimum validation after implementation:

1. `bash -n utl/doc/run_all_doc.sh`
2. `bash -n utl/doc/generators/func`
3. `bash -n utl/doc/generators/var`
4. `bash -n utl/doc/generators/rdp`
5. `./utl/doc/run_all_doc.sh functions variables rdp`
6. verify all three files updated:
   - `doc/ref/functions.md`
   - `doc/ref/variables.md`
   - `doc/ref/reverse-dependecies.md`

## Done criteria

- ACU/LAF/RDP reference generation is config-driven and does not depend on aliases.
- The two existing `doc/ref` files are regenerated from `ana_* -j` pipelines.
- Third sibling file exists and is wired into `run_all_doc.sh`.
- Output markers remain stable and re-runnable.
- JSON collision risk is removed.
