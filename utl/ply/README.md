# Homelab Playground Utilities (`utl/ply`)

`utl/ply` is a local-first planning playground for homelab entities.

It models inventory, current config-derived state, prototype scenarios, desired
targets, and generated implementation plans in SQLite.

## Layout

```text
utl/ply/
├── ply          # CLI entrypoint for DB/bootstrap/planning tasks
├── data/        # Local SQLite database files and runtime artifacts
├── export/      # Human-readable markdown snapshots for git review
├── ops/         # Operation contracts and future command modules
└── sql/         # Schema and seed SQL
```

## Commands

Initialize schema and seed reference types:

```bash
./utl/ply/ply init-db
```

Import `cfg/env` into a new present-state snapshot:

```bash
./utl/ply/ply import-present
```

Write a markdown summary from the database:

```bash
./utl/ply/ply export-md
```

Create desired/prototype states and generate implementation plans:

```bash
./utl/ply/ply create-state ./utl/ply/data/ply.db desired desired-site1 present-20260306-013604
./utl/ply/ply upsert-entity ./utl/ply/data/ply.db service svc-traefik "Traefik"
./utl/ply/ply set-state-entity ./utl/ply/data/ply.db desired-site1 svc-traefik included
./utl/ply/ply plan-implementation ./utl/ply/data/ply.db present-20260306-013604 desired-site1
```

Optional positional arguments:

```bash
./utl/ply/ply init-db /path/to/ply.db
./utl/ply/ply import-present /path/to/ply.db /path/to/cfg/env present-site1
./utl/ply/ply create-state /path/to/ply.db prototype proto-a present-site1 candidate
./utl/ply/ply export-md /path/to/ply.db /path/to/report.md
```

## Notes

- `cfg/env/` remains the live configuration surface.
- The playground DB stores planning data and generated plan artifacts.
- Use markdown exports for readable diffs alongside SQLite updates.
- The CLI uses Python's standard `sqlite3` module, so no external SQLite binary
  is required.
