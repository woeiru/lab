# Homelab Playground Utilities (`utl/pla`)

`utl/pla` is a local-first planning playground for homelab entities.

It models inventory, current config-derived state, prototype scenarios, desired
targets, and generated implementation plans in SQLite.

## Layout

```text
utl/pla/
├── cli          # CLI entrypoint for DB/bootstrap/planning tasks
├── data/        # Local SQLite database files and runtime artifacts
├── export/      # Human-readable markdown snapshots for git review
├── ops/         # Operation contracts and future command modules
└── sql/         # Schema and seed SQL
```

## Commands

Initialize schema and seed reference types:

```bash
./utl/pla/cli init-db
```

Import `cfg/env` into a new present-state snapshot:

```bash
./utl/pla/cli import-present
```

Write a markdown summary from the database:

```bash
./utl/pla/cli export-md
```

Create desired/prototype states and generate implementation plans:

```bash
./utl/pla/cli create-state ./utl/pla/data/ply.db desired desired-site1 present-20260306-013604
./utl/pla/cli upsert-entity ./utl/pla/data/ply.db service svc-traefik "Traefik"
./utl/pla/cli set-state-entity ./utl/pla/data/ply.db desired-site1 svc-traefik included
./utl/pla/cli plan-implementation ./utl/pla/data/ply.db present-20260306-013604 desired-site1
```

Optional positional arguments:

```bash
./utl/pla/cli init-db /path/to/ply.db
./utl/pla/cli import-present /path/to/ply.db /path/to/cfg/env present-site1
./utl/pla/cli create-state /path/to/ply.db prototype proto-a present-site1 candidate
./utl/pla/cli export-md /path/to/ply.db /path/to/report.md
```

## Notes

- `cfg/env/` remains the live configuration surface.
- The playground DB stores planning data and generated plan artifacts.
- Use markdown exports for readable diffs alongside SQLite updates.
- The CLI uses Python's standard `sqlite3` module, so no external SQLite binary
  is required.

## Further Reading

- [08 - Planning Workspace](../../doc/man/08-planning-workspace.md) for operator workflow.
- [09 - Planning Subsystem Architecture](../../doc/arc/09-planning-subsystem.md) for subsystem boundaries and runtime flow.
- [Repository Utilities (`utl/`)](../README.md) for utility-layer overview.
