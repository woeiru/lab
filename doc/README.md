# Documentation Hub

## Navigation
- [Repository Root](../README.md)
- [Documentation Hub](README.md)

## Purpose
`doc/` is the canonical documentation tree for architecture, operations, CLI usage, development references, and infrastructure workflows.

## Documentation Index

### Domain Entrypoints
- Administration: [doc/adm/README.md](./adm/README.md)
- CLI: [doc/cli/README.md](./cli/README.md)
- Development: [doc/dev/README.md](./dev/README.md)
- Infrastructure as Code: [doc/iac/README.md](./iac/README.md)

### Architecture
- [doc/arc/architecture-map.md](./arc/architecture-map.md)
- [doc/arc/architecture-backlog.md](./arc/architecture-backlog.md)
- [doc/arc/src-architecture-deep-dive.md](./arc/src-architecture-deep-dive.md)

### Issue Reports
- [doc/issue/001-gpu-hook-trigger-bug.md](./issue/001-gpu-hook-trigger-bug.md)
- [doc/issue/002-filepath-pve-legacy-reference.md](./issue/002-filepath-pve-legacy-reference.md)
- [doc/issue/003-dic-injection-flag-failure.md](./issue/003-dic-injection-flag-failure.md)

### Generated Documentation Sink
- [doc/dev/generated-doc-injections.md](./dev/generated-doc-injections.md)

## Common Tasks
- Use domain READMEs first, then open deep-dive files only when needed.
- Regenerate auto-injected sections with `./utl/doc/run_all_doc.sh`.

## Troubleshooting
- If a doc link is stale, resolve from this hub and update the referring README.
- If generated sections are outdated, rerun the doc generator and verify marker blocks.

## Related Docs
- [Repository Root](../README.md)
