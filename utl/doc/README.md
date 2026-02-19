# Lab Environment Documentation System

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../../doc/README.md)

## Purpose
`utl/doc/` automates documentation generation for code, structure, and metadata across the repository.

## Quick Start
```bash
cd /home/es/lab/utl/doc

# Run full documentation pipeline
./run_all_doc.sh

# List available generators
./run_all_doc.sh --list

# Inspect generated injection sink
cat /home/es/lab/doc/dev/generated-doc-injections.md
```

## Structure
- `run_all_doc.sh`: top-level orchestration for documentation tasks.
- `generators/`: generators (`func`, `var`, `hub`, `stats`).
- `intelligence/`: analysis helper modules for documentation quality/performance checks.
- `config/settings` and `config/targets`: doc system configuration.

## Common Tasks
- Regenerate documentation after structural changes.
- Run targeted generators during incremental changes (`functions`, `variables`, `stats`, `hub`).
- Use `--dry-run` before broad generation in active branches.

## Troubleshooting
- Verify scripts are executed from `utl/doc/` or with correct absolute paths.
- Check executable permissions on generators and orchestrator scripts.
- Confirm marker blocks exist in `doc/dev/generated-doc-injections.md` for each generator section.

## Related Docs
- [Utilities Root](../README.md)
- [Documentation System Deep Dive (full reference)](../../doc/dev/documentation-system-deep-dive.md)
- [Generated Injection Sink](../../doc/dev/generated-doc-injections.md)
- [Documentation Hub](../../doc/README.md)
- [README Style Guide](../../doc/dev/readme-style-guide.md)
