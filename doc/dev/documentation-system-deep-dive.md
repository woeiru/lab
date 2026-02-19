# Documentation System Deep Dive

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

## Purpose
This document describes the current `utl/doc` documentation generation system, including generator responsibilities, configuration, and output injection behavior.

## Current Architecture

### Module Layout
utl/doc/
├── run_all_doc.sh              # Orchestrator
├── config/
│   ├── settings                # Runtime settings (project root, output dirs)
│   └── targets                 # Generator targets, output files, section names
├── generators/
│   ├── func                    # Function metadata injection
│   ├── var                     # Variable usage injection
│   ├── hub                     # Documentation structure injection
│   └── stats                   # System metrics injection
└── intelligence/
    ├── deps
    ├── perf
    ├── test
    └── ux

### Orchestration Flow
1. `run_all_doc.sh` loads settings.
2. It resolves generator execution order (`functions`, `variables`, `stats`, `hub`).
3. Each generator writes into a dedicated marker section in a single sink file.

## Single Injection Sink
All generated sections are injected into:
- `doc/dev/generated-doc-injections.md`

### Section Mapping
Configured in `utl/doc/config/targets`:
- `func` -> `Function Metadata Table`
- `var` -> `Variable Usage Table`
- `hub` -> `Documentation Structure`
- `stats` -> `System Metrics`

Each section must exist with markers:
<!-- AUTO-GENERATED SECTION: Section Name -->
<!-- END AUTO-GENERATED SECTION -->

## Generator Responsibilities

### `func`
- Uses `ana_laf`-derived metadata to build function inventory.
- Injects into `Function Metadata Table` section.

### `var`
- Uses `ana_acu` for variable usage analysis against configured sources.
- Injects into `Variable Usage Table` section.

### `hub`
- Uses `ana_lad` output for doc tree structure analysis.
- Injects into `Documentation Structure` section.

### `stats`
- Generates markdown metrics table for configured target directories.
- Injects into `System Metrics` section.

## Configuration Model

### `config/settings`
Controls runtime behavior:
- project root resolution
- doc output directory
- verbosity and execution preferences

### `config/targets`
Controls:
- scan targets (`TARGET_DIRECTORIES`)
- output file mapping (`GENERATOR_OUTPUT_FILES`)
- section mapping (`GENERATOR_SECTIONS`)

## Operational Commands

# List generators
./utl/doc/run_all_doc.sh --list

# Preview execution order
./utl/doc/run_all_doc.sh --dry-run

# Run all generators
./utl/doc/run_all_doc.sh

# Run a subset
./utl/doc/run_all_doc.sh functions stats

## Troubleshooting
- If a generator fails, verify the target sink file exists and includes required marker blocks.
- If content is stale, run `./utl/doc/run_all_doc.sh` and re-open `doc/dev/generated-doc-injections.md`.
- If path resolution fails, verify `PROJECT_ROOT` and `DOC_OUTPUT_DIR` in `utl/doc/config/settings`.

## Related Docs
- [Documentation Utility README](../../utl/doc/README.md)
- [Generated Injection Sink](./generated-doc-injections.md)
- [README Style Guide](./readme-style-guide.md)
