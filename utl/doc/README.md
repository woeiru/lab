# Documentation Generation System

The `utl/doc` system generates the auto-populated reference documentation under `doc/ref/`. It extracts analyzer metadata from source files and renders standardized Markdown output to `doc/ref/functions.md`, `doc/ref/variables.md`, and `doc/ref/dependencies.md`.

## Output Files

| Generator | Output file              | Content                                      |
|-----------|--------------------------|----------------------------------------------|
| `func`    | `doc/ref/functions.md`   | Function metadata table for all `lib/` modules |
| `var`     | `doc/ref/variables.md`   | Variable usage patterns across the system    |
| `rdp`     | `doc/ref/dependencies.md`| Reverse dependency mappings and call counts  |

## System Layout

- `run_all_doc.sh`: Orchestrator — resolves generator dependencies and drives execution.
- `generators/`: Static documentation generators.
  - `func`: Extracts function metadata and writes the master functions table to `doc/ref/functions.md`.
  - `var`: Identifies and documents variable usage hierarchies in `doc/ref/variables.md`.
  - `rdp`: Builds reverse dependency tables in `doc/ref/dependencies.md`.
  - `stats`: Analyzes the codebase to provide system metrics.
- `config/`: Configuration files.
  - `settings`: Parallelization, pathing, and output location preferences.
  - `targets`: Source directory list and generator output file mappings.

## Usage

### Regenerate all `doc/ref/` files

```bash
./utl/doc/run_all_doc.sh functions variables
./utl/doc/run_all_doc.sh functions variables dependencies
```

### Regenerate individually

```bash
./utl/doc/run_all_doc.sh functions   # updates doc/ref/functions.md
./utl/doc/run_all_doc.sh variables   # updates doc/ref/variables.md
./utl/doc/run_all_doc.sh dependencies # updates doc/ref/dependencies.md
```

### Configuration and Environment

System behavior is defined in `config/settings`. Key overrides:

- `LAB_DIR`: Root repository directory (defaults to `/home/es/lab`).
- `DOC_DIR`: Target directory for generated output (defaults to `/home/es/lab/doc`).
- `VERBOSE`: Set to `true` for detailed execution logging.
