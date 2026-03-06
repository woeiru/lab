# Operations Layer (`utl/ply/ops`)

This folder is reserved for operation modules that expose validated actions to
agents and scripts (instead of direct table/file mutations).

Current CLI-backed v1 operations:

- `import-present`
- `create-state`
- `upsert-entity`
- `set-state-entity`
- `plan-implementation`

Planned next operations:

- `select-desired`
- `apply-plan`
