# Documentation Generation System

The `utl/doc` system generates the auto-populated reference documentation under `doc/ref/`. It extracts analyzer metadata from source files and renders standardized Markdown output to `doc/ref/functions.md`, `doc/ref/variables.md`, `doc/ref/dependencies.md`, `doc/ref/module-dependencies.md`, `doc/ref/test-coverage.md`, and `doc/ref/scope-integrity.md`.

## Output Files

| Generator | Output file              | Content                                      |
|-----------|--------------------------|----------------------------------------------|
| `func`    | `doc/ref/functions.md`   | Function metadata table for all `lib/` modules |
| `var`     | `doc/ref/variables.md`   | Variable usage patterns across the system    |
| `rdp`     | `doc/ref/dependencies.md`| Reverse dependency mappings and call counts  |
| `dep`     | `doc/ref/module-dependencies.md`| Direct module dependencies (imports + commands) |
| `tst`     | `doc/ref/test-coverage.md`| Module-to-test traceability with counters and status |
| `scp`     | `doc/ref/scope-integrity.md`| Variable scope integrity findings (readonly/global/local leak) |

## System Layout

- `run_all_doc.sh`: Orchestrator — resolves generator dependencies and drives execution.
- `generators/`: Static documentation generators.
  - `func`: Extracts function metadata and writes the master functions table to `doc/ref/functions.md`.
  - `var`: Identifies and documents variable usage hierarchies in `doc/ref/variables.md`.
  - `rdp`: Builds reverse dependency tables in `doc/ref/dependencies.md`.
  - `dep`: Builds direct dependency tables in `doc/ref/module-dependencies.md`.
  - `tst`: Builds test traceability coverage tables in `doc/ref/test-coverage.md`.
  - `scp`: Builds scope integrity tables in `doc/ref/scope-integrity.md`.
  - `stats`: Analyzes the codebase to provide system metrics.
- `config/`: Configuration files.
  - `settings`: Parallelization, pathing, and output location preferences.
  - `targets`: Source directory list and generator output file mappings.

## Analyzer JSON Temp Namespacing

Documentation generators run analyzers in JSON mode and stage intermediate
artifacts under `.tmp/doc/` using analyzer-specific namespaces:

- `func` -> `ana_laf -j --json-dir .tmp/doc/laf`
- `var` -> `ana_acu -j --json-dir .tmp/doc/acu`
- `rdp` -> `ana_rdp -j --json-dir .tmp/doc/rdp`
- `dep` -> `ana_dep -j --json-dir .tmp/doc/dep`
- `tst` -> `ana_tst -j --json-dir .tmp/doc/tst`
- `scp` -> `ana_scp -j --json-dir .tmp/doc/scp`

This avoids JSON filename collisions between analyzers (for example,
multiple analyzers emitting `lib_core_err.json`) and keeps each generator
isolated to its own dataset.

### Troubleshooting stale intermediate data

If generated `doc/ref/*.md` output looks inconsistent with source changes,
clear namespaced analyzer artifacts and rerun docs:

```bash
rm -rf /home/es/lab/.tmp/doc/laf /home/es/lab/.tmp/doc/acu /home/es/lab/.tmp/doc/rdp /home/es/lab/.tmp/doc/dep /home/es/lab/.tmp/doc/tst /home/es/lab/.tmp/doc/scp
./utl/doc/run_all_doc.sh functions variables dependencies module-dependencies test-coverage scope-integrity
```

## Usage

### Regenerate all `doc/ref/` files

```bash
./utl/doc/run_all_doc.sh functions variables
./utl/doc/run_all_doc.sh functions variables dependencies module-dependencies test-coverage scope-integrity
```

### Regenerate individually

```bash
./utl/doc/run_all_doc.sh functions   # updates doc/ref/functions.md
./utl/doc/run_all_doc.sh variables   # updates doc/ref/variables.md
./utl/doc/run_all_doc.sh dependencies # updates doc/ref/dependencies.md
./utl/doc/run_all_doc.sh module-dependencies # updates doc/ref/module-dependencies.md
./utl/doc/run_all_doc.sh test-coverage # updates doc/ref/test-coverage.md
./utl/doc/run_all_doc.sh scope-integrity # updates doc/ref/scope-integrity.md
```

### Configuration and Environment

System behavior is defined in `config/settings`. Key overrides:

- `LAB_DIR`: Root repository directory (defaults to `/home/es/lab`).
- `DOC_DIR`: Target directory for generated output (defaults to `/home/es/lab/doc`).
- `VERBOSE`: Set to `true` for detailed execution logging.
