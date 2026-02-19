# Developer Documentation

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

## Purpose
`doc/dev/` is the developer-facing reference area for architecture deep dives, function/variable references, validation internals, and documentation tooling.

## Child Docs
- [doc/dev/functions.md](./functions.md)
- [doc/dev/variables.md](./variables.md)
- [doc/dev/logging.md](./logging.md)
- [doc/dev/readme-style-guide.md](./readme-style-guide.md)
- [doc/dev/generated-doc-injections.md](./generated-doc-injections.md)
- [doc/dev/dic-deep-dive.md](./dic-deep-dive.md)
- [doc/dev/lib-ops-architecture-deep-dive.md](./lib-ops-architecture-deep-dive.md)
- [doc/dev/bin-bootstrap-deep-dive.md](./bin-bootstrap-deep-dive.md)
- [doc/dev/validation-system-deep-dive.md](./validation-system-deep-dive.md)
- [doc/dev/documentation-system-deep-dive.md](./documentation-system-deep-dive.md)

## Common Tasks
- Start with `functions.md` and `variables.md` for integration-level reference.
- Use deep-dive docs only when debugging subsystem internals.
- Use `generated-doc-injections.md` as the single generated-output sink.

## Troubleshooting
- If generated sections are stale, run `./utl/doc/run_all_doc.sh`.
- If references drift from implementation, verify `src/`, `lib/`, and `cfg/` READMEs first.

## Related Docs
- [Source Docs](../arc/src-architecture-deep-dive.md)
- [Documentation Hub](../README.md)
