# Utilities (`utl/`)

## Navigation
- [Repository Root](../README.md)
- [Documentation Hub](../doc/README.md)

## Purpose
`utl/` contains utility tooling that supports repository operations, especially documentation and utility configuration workflows.

## Quick Start
```bash
# Documentation utility entrypoint
cd /home/es/lab/utl/doc
./run_all_doc.sh --list
```

## Structure
- `utl/doc/`: documentation generation system and orchestrators.
- `utl/cfg/`: utility-specific configuration assets.

## Common Tasks
- Use `utl/doc/` scripts to regenerate indexes, metrics, and README content.
- Keep utility configuration scoped to `utl/cfg/`.

## Troubleshooting
- Verify utility commands are run from their expected working directory.
- Check execution permissions for utility scripts.

## Related Docs
- [Documentation Utility README](./doc/README.md)
- [Repository Root](../README.md)
- [Documentation Hub](../doc/README.md)
