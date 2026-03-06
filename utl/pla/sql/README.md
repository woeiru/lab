# SQL Assets (`utl/pla/sql`)

- `001_init_schema.sql`: core SQLite schema for entities, relations, states,
  config snapshots/bindings, and implementation plans.
- `010_seed_reference.sql`: idempotent seed data for entity and relation types.

Apply in lexical order for deterministic setup.
