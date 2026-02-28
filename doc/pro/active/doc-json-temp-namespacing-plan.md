# Doc JSON Temp Namespacing Plan

- Status: active
- Owner: es
- Created: 2026-02-28
- Scope: `utl/doc`, `utl/doc/generators`, `lib/gen/ana`, `.tmp/doc`

## Goal

Harden doc generation by namespacing analyzer JSON outputs so `ana_laf -j`,
`ana_acu -j`, and `ana_rdp -j` do not collide in `.tmp/doc`.

## Why this is needed

- Current flow is correct (`ana_* -j` -> JSON -> `doc/ref/*.md`) but fragile if
  multiple analyzers emit the same basename (for example `lib/core/err.json`).
- Collisions can cause stale or wrong data to be rendered into reference docs.
- Namespacing improves determinism, debugging, and rerun safety.

## Target model

Use analyzer-specific temp trees:

- `.tmp/doc/laf/`
- `.tmp/doc/acu/`
- `.tmp/doc/rdp/`

Each generator reads only its own namespace.

## Implementation plan

### Phase 1 - contract and path helpers

1. Define canonical namespace paths in one place (generator-local constants or
   shared helper).
2. Keep backward-compatible fallback handling during transition.
3. Ensure cleanup logic is namespace-aware and does not remove unrelated data.

### Phase 2 - generator wiring

1. Update `utl/doc/generators/func` to read from `.tmp/doc/laf` only.
2. Update `utl/doc/generators/var` to read from `.tmp/doc/acu` only.
3. Update `utl/doc/generators/rdp` to read from `.tmp/doc/rdp` only.
4. Keep non-fatal analyzer behavior where intended (`|| true` patterns).

### Phase 3 - analyzer output routing

Preferred:

1. Add optional output namespace/path flag in `ana_laf`, `ana_acu`, `ana_rdp`.
2. Route JSON writes directly into analyzer-specific namespace directories.

Fallback:

1. Continue current analyzer output path.
2. Move generated JSON into namespace directory immediately after each call.

### Phase 4 - orchestration and docs

1. Verify `utl/doc/run_all_doc.sh` remains unchanged functionally.
2. Update `utl/doc/README.md` with namespace behavior.
3. Add quick troubleshooting note for stale JSON cleanup.

### Phase 5 - validation

1. `bash -n lib/gen/ana`
2. `bash -n utl/doc/generators/func`
3. `bash -n utl/doc/generators/var`
4. `bash -n utl/doc/generators/rdp`
5. `./utl/doc/run_all_doc.sh --dry-run`
6. `./utl/doc/run_all_doc.sh functions variables dependencies`
7. Verify outputs updated correctly:
   - `doc/ref/functions.md`
   - `doc/ref/variables.md`
   - `doc/ref/dependencies.md`

## Done criteria

- No JSON filename collisions across analyzers.
- Each generator consumes only analyzer-specific namespace data.
- Generated `doc/ref` files match analyzer JSON consistently across reruns.
- Readme documents the namespaced temp-data behavior.

## Risks and notes

- Analyzer flag changes can affect other callers; keep defaults unchanged.
- Transition should preserve current command UX and output file locations.
- Avoid destructive cleanup outside `.tmp/doc/{laf,acu,rdp}`.
