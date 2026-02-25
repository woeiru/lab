# User Walkthrough Redesign Plan

## Objective
Rewrite the `doc/man` folder completely to create a structured, end-to-end user walkthrough for the infrastructure automation framework. The previous documentation was fragmented into alphabetized concepts (`configuration.md`, `deployment.md`, etc.). The new structure will follow a progressive learning path, starting from installation and leading up to advanced module development.

## Implementation Steps

1. **Clear old documentation**
   - Delete all `.md` files in `doc/man/` (these will be replaced by the new numbered walkthrough files).

2. **Create New Walkthrough Files**
   - `01-introduction.md`: What this framework is, core concepts (Bash-only, DIC, `lib/ops`, `cfg/env`).
   - `02-installation.md`: Requirements, cloning, running `./go init`, `lab-on`/`lab-off`/`lab`, and `./go status`.
   - `03-configuration.md`: Environment structure, site config (`cfg/core/ecc`), hostname-specific variables in `cfg/env/`, and declarative arrays.
   - `04-cli-usage.md`: The `lab` command environment, raw bash functions vs the `ops` DIC interface, DIC modes (`-j`, `-x`, hybrid).
   - `05-deployments.md`: Understanding `src/set/` scripts, interactive menus (`-i`), sections, and headless execution (`-x`).
   - `06-writing-modules.md`: How to write a new module in `lib/ops/`, naming conventions, documentation blocks (`aux_use`), tests, and return codes.
   - `07-security-and-logging.md`: Best practices for secrets (via `lib/gen/sec`), log levels (`aux.log`, JSON, CSV), and debug outputs.

3. **Update Links**
   - Check `doc/README.md` and update index links to point to the newly structured files.

## Guidelines
- Follow the repository's tone: technically precise, concise, no emoji headings, no marketing filler.
- All code paths and CLI examples must reflect the actual codebase (`./go`, `src/dic/ops`, `bin/ini`, `cfg/env`, etc.).
