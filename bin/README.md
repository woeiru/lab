# Binary/Executable Directory (`bin/`)

## Navigation
- [Repository Root](../README.md)
- [Documentation Hub](../doc/README.md)

## Purpose
`bin/` contains the bootstrap and orchestration entry scripts that initialize runtime configuration, load modules, and prepare the shell-integrated environment.

## Quick Start
# Initialize and integrate shell
./go init
./go on

# Verify runtime health
./go status
./go doctor

## Structure
- `bin/ini`: primary initialization controller.
- `bin/orc`: component orchestrator for config, aliases, and library loading.

## Common Tasks
- Use `./go on` after setup to enable managed shell integration.
- Use `./go off` to remove managed shell block cleanly.
- Review `.log/ini.log` and `.log/error.log` when bootstrap issues occur.

## Troubleshooting
- Ensure Bash 4+ and required core files under `cfg/core/` and `lib/core/` exist.
- Check write permissions for `.log/` and `.tmp/`.
- Re-run `./go doctor` to detect missing dependencies and mapping issues.

## Related Docs
- [Bootstrap Deep Dive (full reference)](../doc/dev/bin-bootstrap-deep-dive.md)
- [CLI Documentation](../doc/cli/README.md)
- [Library Modules](../lib/README.md)
- [Documentation Hub](../doc/README.md)
