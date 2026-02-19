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

# Generate AI documentation for a target directory
./ai/ai_doc_generator /home/es/lab/lib/ops
```

## Structure
- `run_all_doc.sh`: top-level orchestration for documentation tasks.
- `generators/`: non-AI generators (functions, variables, hub, stats).
- `ai/ai_doc_generator`: AI-assisted README/documentation generation.
- `intelligence/`: analysis modules used by AI generation flows.
- `config/.doc_config`: local configuration for doc generation.

## Common Tasks
- Regenerate documentation after structural changes.
- Run targeted generators during incremental changes.
- Use `--dry-run` before broad generation in active branches.

## Troubleshooting
- Verify scripts are executed from `utl/doc/` or with correct absolute paths.
- Check executable permissions on generators and orchestrator scripts.
- Review script output and `.log/` artifacts if generation fails.

## Related Docs
- [Documentation System Deep Dive (full reference)](../../doc/dev/documentation-system-deep-dive.md)
- [Documentation Hub](../../doc/README.md)
- [README Style Guide](../../doc/dev/readme-style-guide.md)
