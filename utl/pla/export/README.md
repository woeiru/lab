# Exports (`utl/pla/export`)

This directory stores generated markdown snapshots for review and archiving.

## Export Types

| File or Pattern | Type | Producer | Scope |
| --- | --- | --- | --- |
| `summary-default.md` | Workspace overview | `./utl/pla/cli export-md` (default path) | Counts and recent records across the whole planning DB |
| `summary-<label>.md` (for example `summary-showcase1.md`) | Workspace overview | `./utl/pla/cli export-md <db_path> <output_path>` | Same structure as `summary-default.md`, written to a canonical labeled filename |
| `inventory-summary.md` | Workspace overview (legacy compatibility) | Auto-mirrored when running default `./utl/pla/cli export-md` | Compatibility alias for workflows that still read the previous default filename |
| `present-*-detail.md` (for example `present-showcase1-detail.md`) | Present-state detail | One-off/manual export helper | Deep snapshot view for one selected `present` state (metadata + file inventory + hashes) |

## Notes

- Canonical default snapshot path: `utl/pla/export/summary-default.md`.
- Canonical labeled snapshots should use `utl/pla/export/summary-<label>.md`.
- Transition note: the CLI also mirrors default exports to `utl/pla/export/inventory-summary.md` until the legacy alias is formally removed.
- Regenerate overview exports with: `./utl/pla/cli export-md`.
- The detailed `present-*-detail.md` format is currently ad hoc and not yet a built-in CLI subcommand.
