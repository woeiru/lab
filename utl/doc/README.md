# Documentation Generation System

The `utl/doc` system generates the auto-populated reference documentation under `doc/ref/`. It extracts metadata from source files, processes function definitions, and evaluates variable usage, rendering standardized Markdown output exclusively to `doc/ref/functions.md` and `doc/ref/variables.md`.

## Output Files

| Generator | Output file              | Content                                      |
|-----------|--------------------------|----------------------------------------------|
| `func`    | `doc/ref/functions.md`   | Function metadata table for all `lib/` modules |
| `var`     | `doc/ref/variables.md`   | Variable usage patterns across the system    |

## System Layout

- `run_all_doc.sh`: Orchestrator — resolves generator dependencies and drives execution.
- `generators/`: Static documentation generators.
  - `func`: Extracts function metadata and writes the master functions table to `doc/ref/functions.md`.
  - `var`: Identifies and documents variable usage hierarchies in `doc/ref/variables.md`.
  - `stats`: Analyzes the codebase to provide system metrics.
- `intelligence/`: Deep analysis modules used as inputs to the AI generator.
  - `perf`: Extracts performance characteristics.
  - `deps`: Maps inter-module and script dependencies.
  - `test`: Evaluates validation test coverage.
  - `ux`: Analyzes interface design and usability indicators.
- `config/`: Configuration files.
  - `settings`: Parallelization, pathing, and output location preferences.
  - `targets`: Source directory list and generator output file mappings.

## Usage

### Regenerate all `doc/ref/` files

```bash
./utl/doc/run_all_doc.sh functions variables
```

### Regenerate individually

```bash
./utl/doc/run_all_doc.sh functions   # updates doc/ref/functions.md
./utl/doc/run_all_doc.sh variables   # updates doc/ref/variables.md
```

### Configuration and Environment

System behavior is defined in `config/settings`. Key overrides:

- `LAB_DIR`: Root repository directory (defaults to `/home/es/lab`).
- `DOC_DIR`: Target directory for generated output (defaults to `/home/es/lab/doc`).
- `VERBOSE`: Set to `true` for detailed execution logging.
