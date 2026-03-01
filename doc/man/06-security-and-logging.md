# 06 - Security and Logging

This guide explains how to handle secrets safely and how to produce auditable logs
across runtime, ops modules, and deployment flows.

## 1. Security Baselines

- Never hardcode secrets in `cfg/env/*`, `lib/ops/*`, or `src/set/*`.
- Assume runbooks and ops actions can affect real infrastructure.
- Validate dependencies and parameters before executing state changes.
- Use explicit execution gates (for example `-x`) for high-impact actions.

## 2. Secret Management (`lib/gen/sec`)

Use `lib/gen/sec` helpers instead of custom ad-hoc password logic.

Common functions:
- `sec_generate_secure_password [length] [exclude_special]`
- `sec_store_secure_password <var_name> [length] [exclude_special]`
- `sec_init_password_management [password_dir]`
- `sec_load_stored_passwords [password_dir]`

Compatibility aliases also exist (`generate_secure_password`, `store_secure_password`, etc.).

Example:

```bash
sec_init_password_management
DB_PASSWORD="$(sec_generate_secure_password 24)"
```

Storage expectations:
- password directories should be `700`,
- individual password files should be `600`,
- avoid printing secrets to terminal logs.

## 3. Safe Handling Patterns in Modules

For sensitive or destructive code paths:
- use `mktemp` for temporary files,
- clean up with traps,
- validate required commands with `aux_chk`,
- fail fast with explicit return codes,
- log intent and outcome via `aux_*` helpers.

## 4. Logging Layers

### Operational logging (`lib/gen/aux`)

Primary helpers for `lib/ops/*`:
- `aux_info`
- `aux_warn`
- `aux_err`
- `aux_dbg`
- `aux_audit`
- `aux_business`

Use context metadata where relevant:

```bash
aux_info "passthrough started" "component=gpu,operation=passthrough,status=started"
```

### Core runtime logging (`lib/core/lo1`)

`lo1` is used heavily during initialization/orchestration (`bin/ini`, `bin/orc`).

- Main file: `${LOG_DIR}/lo1.log`
- Toggle terminal/file behavior with `lo1_setlog on|off`.

### Error logging (`lib/core/err`)

`err` centralizes structured error processing and reporting.

- Main file: `${LOG_DIR}/err.log`
- Key helpers include `err_process`, `err_handler`, `err_print_report`.

## 5. AUX Log Formats and Destinations

`AUX_LOG_FORMAT` controls structured output behavior for aux logging:

- `human` (default) -> `${LOG_DIR}/aux.log`
- `json` -> `${LOG_DIR}/aux.json`
- `csv` -> `${LOG_DIR}/aux.csv`
- `kv` / `keyvalue` -> `${LOG_DIR}/aux.log`

Example:

```bash
AUX_LOG_FORMAT=json ops pve vpt -j
```

## 6. Validate Security/Logging Changes

For module-level edits:

```bash
bash -n lib/gen/sec
bash -n lib/gen/aux
bash -n lib/core/lo1
bash -n lib/core/err
```

Then run relevant tests:

```bash
./val/run_all_tests.sh lib
./val/run_all_tests.sh integration
```

## 7. Troubleshooting

### Logs not written to files

- Confirm `LOG_DIR` is set and writable.
- Confirm runtime was initialized (`lab`).
- Check format selection (`AUX_LOG_FORMAT`).

### Excessive debug output

- Set `OPS_DEBUG=0` unless actively debugging.
- Tune verbosity environment variables in `cfg/core/ric` as needed.

### Password files created in unexpected directory

- Check `sec_get_password_directory` behavior on current host permissions.
- Pass explicit directory to `sec_init_password_management <dir>` when deterministic location is required.

## 8. Related Docs

- Manual start: [01 - Installation and Initialization](01-installation.md)
- Module authoring: [05 - Writing Modules](05-writing-modules.md)
- Architecture context: [doc/arc/07-logging-and-error-handling.md](../arc/07-logging-and-error-handling.md)
