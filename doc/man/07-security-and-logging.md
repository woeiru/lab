# 07 - Security and Logging

The framework provides built-in mechanisms for securely handling sensitive data and generating detailed, structured logs of all operational activity.

## Security Practices

The framework prioritizes secure file permissions, safe temporary file patterns, and the avoidance of hardcoded secrets.

### 1. Handling Secrets

**Never hardcode secrets** in configuration files (`cfg/env/`), modules (`lib/ops/`), or deployment scripts (`src/set/`).

The `lib/gen/sec` module provides utilities for generating and securely storing passwords and sensitive material.

- **Password Generation:** Use `sec_generate_secure_password` (or compatibility alias `generate_secure_password`) to create secure passwords (e.g., from `/dev/urandom`).
- **Secure Storage:** Store secrets in files with `chmod 600` permissions. The framework enforces secure file permissions for sensitive material automatically.
- **Safe Execution:** Prefer safe temp-file patterns (`mktemp`) and cleanup traps when handling sensitive data during module execution.

### 2. Guarding Destructive Operations

Operational modules in `lib/ops/` that modify state or execute potentially destructive commands (e.g., deleting a ZFS dataset or removing a container) must be auditable and guarded by explicit user confirmation or strict parameter validation.

- Always validate dependencies before execution.
- Use structured error reporting helpers (`aux_err`, `err_process`) to surface issues clearly.

## The Logging System

The framework relies on a multi-tiered logging architecture, primarily driven by `lib/gen/aux` and `lib/core/lo1`.

### 1. Operational Logging (`aux_*`)

All modules in `lib/ops/` must use the structured logging functions provided by `lib/gen/aux` instead of raw `echo` or `printf`.

- `aux_info "Starting process..."`
- `aux_warn "Disk space low"`
- `aux_err "Process failed"`
- `aux_dbg "Variable value: $x"`
- `aux_audit "User $USER modified config"`
- `aux_business "Order processed"`

These helpers ensure consistent formatting and allow the framework to route logs to multiple destinations based on the `AUX_LOG_FORMAT` environment variable.

### 2. Log Destinations and Formats

The `AUX_LOG_FORMAT` variable determines how logs are written to disk. The default is `human`, which writes standard text output to `aux.log`.

Other formats include:

- **`json`**: Structured JSON with cluster metadata (writes to `aux.json`). Ideal for ingestion into Fluentd or Filebeat.
- **`csv`**: Comma-separated values with headers (writes to `aux.csv`). Useful for data analysis tools.
- **`kv`**: Key-value pairs (writes to `aux.log`).
- **`human`**: Default terminal format (writes to `aux.log`).

Include context as key-value pairs in the context argument when logging complex operations:
```bash
aux_info "passthrough started" "component=gpu,operation=passthrough,status=started"
```

### 3. Core Infrastructure Logging (`lo1.log`)

The `lib/core/lo1` module handles advanced, hierarchical logging for the core infrastructure (e.g., the orchestrator `bin/orc` and the initialization controller `bin/ini`).

- It features call-stack depth caching and timing integration.
- The format is typically `HH:MM:SS.NN └─ message`.
- You can toggle this logging on or off using `lo1_setlog on|off`.

### 4. Error Logging (`err.log`)

A centralized error and warning repository managed by `lib/core/err`.

- The format is `[SEVERITY] YYYY-MM-DD HH:MM:SS - [component] message`.
- It captures stack traces and handles `ERR` traps globally.

By understanding the security tools and logging architecture, you can build auditable, robust infrastructure modules. This concludes the user walkthrough.
