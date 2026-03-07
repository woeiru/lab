# Documentation Hub

Central documentation hub for the Lab Environment Management System.

Contents are organised by purpose: `man/` for operational guides (user/admin audience), `arc/` for architectural references (developer/architect audience), and `ref/` for auto-generated reference documentation (variables and functions).

## Documentation Index

### Operational Documentation (`doc/man/`)
**Purpose**: How to use, configure, and operate the Lab Environment Management System. Audience: system administrators, operators, CLI users.

- **[01 - Installation and Initialization](man/01-installation.md)** - Requirements, cloning, system initialization, and environment activation.
- **[02 - Environment and Configuration](man/02-configuration.md)** - The configuration hierarchy, active context, hostname-specific variables, and declarative arrays.
- **[03 - CLI Usage and the DIC](man/03-cli-usage.md)** - Direct Bash function execution vs the DIC CLI, DIC execution modes, and parameter injection.
- **[04 - Deployments and Runbooks](man/04-deployments.md)** - Structure of section-based set scripts, interactive mode, and headless execution.
- **[05 - Writing Modules](man/05-writing-modules.md)** - Module conventions, naming, parameters, validation, self-documenting comments, and tests.
- **[06 - Security and Logging](man/06-security-and-logging.md)** - Handling secrets safely, guarding destructive operations, and the multi-tiered logging architecture.
- **[07 - Dev Session Attribution Workflow](man/07-dev-session-attribution-workflow.md)** - Emitting identity attribution events for OpenCode sessions, strict vs best-effort reporting, and troubleshooting.
- **[08 - Planning Workspace](man/08-planning-workspace.md)** - Local planning workflow with `utl/pla` for state modeling, delta planning, and markdown exports.

### Architectural Documentation (`doc/arc/`)
**Purpose**: How the system is designed, module structure, system context, and dependency flows. Audience: developers, architects.

- **[00 - Architecture Overview](arc/00-architecture-overview.md)** - System paradigm, directory layout, high-level execution flow, and three-layer deployment architecture.
- **[01 - Bootstrap and Orchestration](arc/01-bootstrap-and-orchestration.md)** - `./go` entrypoint, `bin/ini` initialization sequence, and `bin/orc` component orchestrator.
- **[02 - Core Primitives and General Utilities](arc/02-core-and-gen.md)** - `lib/core` and `lib/gen` layers: logging, error handling, security, and cross-cutting utilities.
- **[03 - Operational Modules](arc/03-operational-modules.md)** - Pure function paradigm, naming conventions, safety/idempotency patterns, and dual-mode execution.
- **[04 - Dependency Injection Container](arc/04-dependency-injection.md)** - DIC architecture, hierarchical parameter resolution, injection strategies, and execution modes.
- **[05 - Deployment and Configuration Layer](arc/05-deployment-and-config.md)** - `.menu` framework, hostname-based deployment scripts, and configuration hierarchy.
- **[06 - Testing and Validation](arc/06-testing-and-validation.md)** - BDD test framework, master test runner, and syntax/compliance linting.
- **[07 - Logging and Error Handling](arc/07-logging-and-error-handling.md)** - Two-phase logging architecture, hierarchical verbosity, and standardized return codes.
- **[08 - Workflow Architecture](arc/08-workflow-architecture.md)** - Agent workflow coordination architecture for `doc/pro` state transitions.
- **[09 - Planning Subsystem Architecture](arc/09-planning-subsystem.md)** - `utl/pla` command flow, SQLite model boundaries, and planning artifact lifecycle.

### Reference Documentation (`doc/ref/`)
**Purpose**: Auto-generated compressed reference context for symbol lookup, dependency tracing, and codebase navigation. Audience: developers, module authors, automation agents.

- **[Pure Functions Reference](ref/functions.md)** - Library structure overview, module inventory, and auto-generated function metadata table for all `lib/` modules.
- **[Variable Usage Reference](ref/variables.md)** - Environment variables and their usage patterns across the system.
- **[Module Dependencies](ref/module-dependencies.md)** - Per-module script imports and required host commands.
- **[Reverse Dependencies](ref/reverse-dependecies.md)** - Reverse call/import relationships across the codebase.
- **[Test Coverage Map](ref/test-coverage.md)** - Function-to-test traceability table.
- **[Scope Integrity](ref/scope-integrity.md)** - Variable scope and leakage analysis map.
- **[Error Handling Map](ref/error-handling.md)** - Return/exit/error logging behavior map.

## Reference Contract

- Canonical generated reference context is `doc/ref/`.
- `wow/` is planning workflow content and is not a canonical reference source.
- If generated reference docs diverge from code, source code is the source of truth.
- After structural changes (function signatures, dependencies, variable maps, test mappings), regenerate `doc/ref/`.

## Supplementary Documentation

### Project Planning (`wow/`)
Planning documents organised by lifecycle state.

- `pro/inbox/` — New ideas and proposals awaiting triage
- `pro/queue/` — Prioritized items ready to be started
- `pro/active/` — Work in progress
- `pro/active/waivers/` — Temporary policy waivers for active work (owner + expiry + removal criteria)
- `pro/completed/` — Completed plans
- `pro/dismissed/` — Dismissed proposals
- `pro/experiments/` — Exploratory work and validation notes
- `pro/agentic-workflow-prompts.md` — Prompt templates for agentic workflows
- `pro/check-workflow.sh` — Workflow validation script

## Reference Documentation Tools

The `doc/ref/` files are auto-generated by `utl/ref`. Run these to refresh them:

```bash
# Regenerate all reference docs
./utl/ref/run_all_doc.sh
```

Or regenerate selected references:

```bash
# Update function metadata table (writes to doc/ref/functions.md)
./utl/ref/generators/func

# Update variable usage documentation (writes to doc/ref/variables.md)
./utl/ref/generators/var

# Update repository metrics (writes STATS.md + doc/ref/stats/actual.md)
./utl/ref/generators/stats --update
```

## Stats Generator and Flaky-Test Signals

The stats generator includes a `test_health` section with optional flaky-test
heuristics designed to surface unstable validation suites without running the
full test pipeline by default.

### Outputs

- Human summary: `STATS.md`
- Machine snapshot: `doc/ref/stats/actual.md`
- Snapshot history: `doc/ref/stats/<timestamp>.json`

### Flaky-related options

```bash
# Include flaky severity in hard CI gate
./utl/ref/generators/stats --update --ci-gate-flaky

# Opt-in flaky sampling (N repeated runs per sampled suite)
./utl/ref/generators/stats --json --sample-tests --sample-runs=3

# Configure per-suite budget (repeatable): SUITE:OSCILLATION:VARIANCE
./utl/ref/generators/stats --json \
  --flaky-suite-budget=val/core/agents_md_test.sh:1:1

# Apply default budget profile (none|strict|balanced|relaxed)
./utl/ref/generators/stats --json --flaky-budget-profile=balanced
```

### Environment variables

- `STATS_FLAKY_SUITE_BUDGETS` - comma-separated `SUITE:OSC:VAR` entries.
- `STATS_FLAKY_BUDGET_PROFILE` - one of `none`, `strict`, `balanced`, `relaxed`.

### Budget precedence

1. Explicit per-suite entries (`--flaky-suite-budget` and `STATS_FLAKY_SUITE_BUDGETS`).
2. Profile defaults (`--flaky-budget-profile` and `STATS_FLAKY_BUDGET_PROFILE`).

This means profile presets provide baseline defaults, while explicit per-suite
entries override those defaults for targeted suites.
