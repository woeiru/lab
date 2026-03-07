# Exports (`utl/pla/export`)

This directory stores generated markdown snapshots for review and archiving.

## Export Types

| File or Pattern | Type | Producer | Scope |
| --- | --- | --- | --- |
| `inventory-summary.md` | Workspace overview | `./utl/pla/cli export-md` (default path) | Counts and recent records across the whole planning DB |
| `*-overview.md` (for example `showcase-overview.md`) | Workspace overview | `./utl/pla/cli export-md <db_path> <output_path>` | Same structure as `inventory-summary.md`, written to a custom filename |
| `present-*-detail.md` (for example `present-showcase1-detail.md`) | Present-state detail | One-off/manual export helper | Deep snapshot view for one selected `present` state (metadata + file inventory + hashes) |

## Notes

- Default snapshot path: `utl/pla/export/inventory-summary.md`.
- Regenerate overview exports with: `./utl/pla/cli export-md`.
- The detailed `present-*-detail.md` format is currently ad hoc and not yet a built-in CLI subcommand.
