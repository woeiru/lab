# Repository Utilities (`utl/`)

**The Out-of-Band Tooling:** The `utl/` directory contains standalone helper scripts that maintain the repository and its infrastructure codebase, rather than managing the deployed infrastructure itself. It provides essential generators and internal configuration helpers.

## Directory Structure

```text
utl/
├── cfg/    # Internal Configuration Helpers
├── doc/    # Auto-Documentation Generators
└── sec/    # Internal Security Helpers
```

## Core Tools

### `doc/` (Documentation Generators)
The framework heavily relies on self-documenting code. The generators in `utl/doc/` parse function usage (`aux_use`), technical comments (`aux_tec`), and variable assignments across the repository to statically generate the Markdown reference documentation.

**Key Components:**
- `run_all_doc.sh`: The main orchestrator that resolves generator dependencies.
- `generators/func`: Extracts function metadata to write `doc/ref/functions.md`.
- `generators/var`: Identifies and maps variable usage to write `doc/ref/variables.md`.

**Important Note:** The files in `doc/ref/` should **never** be manually edited. Always update the source code comments and run the generator.

## Usage Examples

**Generate all reference documentation:**
```bash
./utl/doc/run_all_doc.sh functions variables
```

**Generate individually:**
```bash
./utl/doc/run_all_doc.sh functions   # Updates doc/ref/functions.md
./utl/doc/run_all_doc.sh variables   # Updates doc/ref/variables.md
```

## Further Reading

To understand the architecture and how these utilities analyze code dependencies and performance:

- **Reference:** [Functions Reference](../doc/ref/functions.md)
- **Reference:** [Variables Reference](../doc/ref/variables.md)
- **Manual:** [05 - Writing Modules](../doc/man/05-writing-modules.md) (covers adding `aux_use`/`aux_tec` comments)

---
**Navigation**: Return to [Main Lab Documentation](../README.md)
