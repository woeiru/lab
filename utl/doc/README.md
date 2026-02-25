# Documentation Generation System

The `utl/doc` system provides automated documentation generation across the infrastructure. It extracts metadata from source files, processes function definitions, evaluates configurations, and renders standardized Markdown output to the `/doc` hierarchy and module `README.md` files.

## System Architecture

The documentation system is organized into distinct processing engines:

- `run_all_doc.sh`: The main orchestrator that resolves dependencies, parallelizes generation, and orchestrates the documentation update process.
- `generators/`: Core static documentation generators.
  - `func`: Extracts function metadata and builds the master functions list (`doc/arc/functions.md`).
  - `hub`: Rebuilds the autonomous index in the root `doc/README.md`.
  - `var`: Identifies and documents configuration variable hierarchies in `doc/arc/variables.md`.
  - `stats`: Analyzes the codebase to provide system metrics.
- `intelligence/`: Deep analysis modules for codebase metrics.
  - `perf`: Extracts performance characteristics.
  - `deps`: Maps inter-module and script dependencies.
  - `test`: Evaluates validation test coverage.
  - `ux`: Analyzes interface design and usability indicators.
- `ai/`: Implements the `ai_doc_generator` using a 13-phase context gathering process to provide automated, context-aware README creation with various backend supports (mock, ollama, openai, gemini).
- `config/`: Contains documentation targets and system preferences.
  - `settings`: Master configuration for parallelization, pathing, and output locations.
  - `targets`: Defines output mapping rules.

## Core Workflows

### Standard Regeneration

Run the orchestrator without arguments to process all static generators according to the dependency graph:

```bash
cd /home/es/lab/utl/doc
./run_all_doc.sh
```

### Targeted Execution

Generators can be triggered individually. The orchestrator will automatically resolve and execute required upstream dependencies (e.g., calling `hub` will automatically execute `func` and `var` if needed).

```bash
./run_all_doc.sh func
./run_all_doc.sh var
./run_all_doc.sh hub
```

### AI Documentation Engine

The `ai_doc_generator` processes specific subdirectories to update their respective `README.md` files using contextual intelligence. The `AI_SERVICE` environment variable controls the backend.

```bash
# Generate documentation using the default mock backend
./ai/ai_doc_generator /home/es/lab/lib/ops

# Use explicit backend (mock, ollama, openai, gemini)
AI_SERVICE=ollama ./ai/ai_doc_generator /home/es/lab/lib/ops
```

### Configuration and Environment

System behavior is defined in `config/settings`. Overrides can be provided via environment variables during execution:

- `LAB_DIR`: Root repository directory (defaults to `/home/es/lab`).
- `DOC_DIR`: Target directory for generated output (defaults to `/home/es/lab/doc`).
- `VERBOSE`: Boolean to toggle verbose execution logging.
- `AI_SERVICE`: Target backend for the AI generator (`mock`, `ollama`, `openai`, `gemini`).

## Dependency Handling

The orchestrator enforces a strict dependency resolution path. Modifying or adding new generators requires updating the dependency graph defined in `run_all_doc.sh` to ensure inputs are generated prior to processing downstream targets.

For custom generators, place the script inside `generators/`. It will be automatically discovered by the orchestrator list command:

```bash
./run_all_doc.sh --list
```
