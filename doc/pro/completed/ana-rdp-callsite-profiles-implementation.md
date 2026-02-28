# ana_rdp Call-Site Profiles Implementation

- Status: completed
- Owner: es
- Started: 2026-02-28
- Updated: 2026-02-28
- Links: lib/gen/ana, cfg/ali/sta, val/lib/gen/ana_rdp_test.sh, doc/pro/completed/ana-module-expansion/plan.md

## Goal

Add profile-based call-site selection to `ana_rdp` so we keep explicit control
for advanced use while adding convenient wrappers for the common scans.

## Current Behavior

`ana_rdp` currently scans a fixed set of directories:

- `lib/ops`
- `src/set`
- `bin`

This is convenient but hardcoded, so callers cannot narrow or expand scope
without editing function internals.

## Decision

Use an `aux_ffl`-first model to stay consistent with existing chaining in
`cfg/ali/sta` (`fun-*`, `var-*`):

1. Keep `ana_rdp` core explicit and parameterized.
2. Provide convenience primarily through `aux_ffl` aliases/profiles.
3. Keep wrapper functions optional and minimal (only where alias argument
   placement becomes awkward).

## Proposed Interface

### Core

`ana_rdp [options] <target_file> [callsite_dir ...]`

- If one or more `callsite_dir` values are passed, scan only those.
- If no `callsite_dir` is passed, return usage error (`1`) to avoid implicit
  magic and force explicit intent.
- Keep `-j` behavior unchanged.

### Convenience profiles (preferred)

Use aliases that chain through `aux_ffl`, following existing repo patterns.

- `alias rdp-std='aux_ffl ana_rdp "" "$LIB_CORE_DIR" "$LIB_OPS_DIR" "$SRC_SET_DIR" "$DIR_BIN"'`
  - Runs reverse-dependency analysis for each file in `lib/core` against
    standard call sites.
- `alias rdp-core='aux_ffl ana_rdp "" "$LIB_CORE_DIR" "$LIB_OPS_DIR"'`
- `alias rdp-gen='aux_ffl ana_rdp "" "$LIB_GEN_DIR" "$LIB_OPS_DIR" "$SRC_SET_DIR" "$DIR_BIN"'`

### Optional single-target wrapper

If interactive single-file usage is common, keep one small helper:

- `ana_rdp_std <target_file> [-j]`
  - forwards to `ana_rdp` with standard call sites.

## Implementation Steps

1. Update argument parsing in `lib/gen/ana` `ana_rdp`:
   - collect positional args after target file into `search_dirs`.
   - validate each directory exists; reject invalid paths with clear error.
2. Remove the hardcoded directory assembly block from `ana_rdp`.
3. Add `aux_ffl` convenience aliases in `cfg/ali/sta` for profile-based bulk use.
4. Optionally add only `ana_rdp_std` wrapper in `lib/gen/ana` for single-target
   convenience.
5. Extend tests in `val/lib/gen/ana_rdp_test.sh`:
   - explicit call-site input works.
   - missing call-site args fails with return code `1`.
   - optional wrapper (if implemented) passes with expected scope.
   - `-j` still writes expected JSON file.

## Usage Examples

```bash
# Bulk profile via aux_ffl
rdp-core

# Explicit custom profile (single target)
ana_rdp lib/core/tme "$LAB_DIR/lib/ops" "$LAB_DIR/lib/gen"

# Optional single-target convenience helper
ana_rdp_std lib/core/tme -j
```

## Validation Plan

```bash
bash -n lib/gen/ana
bash -n val/lib/gen/ana_rdp_test.sh
bash val/lib/gen/ana_rdp_test.sh
```

## Risks and Mitigations

- Risk: Breaking current workflows that call `ana_rdp <target>` only.
  - Mitigation: publish `aux_ffl` profile aliases and optionally keep one
    `ana_rdp_std` helper for direct replacement.
- Risk: Convenience layer drift from existing conventions.
  - Mitigation: keep convenience in `cfg/ali/sta` via `aux_ffl` first.
- Risk: Path handling inconsistencies between relative and absolute paths.
  - Mitigation: normalize using existing `lab_dir` logic before comparisons.

## Done Criteria

- `ana_rdp` no longer relies on hardcoded search directories.
- Standard behavior is preserved via `aux_ffl` call-site profile aliases.
- Tests cover explicit input, wrappers, and JSON mode.
- Help/usage text reflects the new interface.
