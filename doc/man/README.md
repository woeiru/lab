# Manual Docs Guide (`doc/man`)

This README defines the quality bar for user/operator manuals in `doc/man/`.
Use it as the writing standard when updating existing manuals or creating new ones.

## Purpose

Manual docs in this folder should be:
- task-oriented for day-to-day operators
- accurate to current code and runtime behavior
- safe by default for infrastructure workflows
- traceable to concrete commands, files, and functions

The manuals should explain how to use the system, while `doc/arc/` explains why the
system is structured the way it is.

## Canonical scope of this folder

- `01-installation.md`: clone/setup, shell initialization, activation, validation
- `02-configuration.md`: config hierarchy, active context, precedence, environment files
- `03-cli-usage.md`: direct function calls vs `ops` DIC execution modes
- `04-deployments.md`: set scripts under `src/set/`, interactive vs direct execution
- `05-writing-modules.md`: module authoring rules, validation patterns, and tests
- `06-security-and-logging.md`: secrets handling, destructive-safety rules, logging model
- `07-dev-session-attribution-workflow.md`: `dev` module session attribution flow, confidence interpretation, and recovery
- `08-planning-workspace.md`: local planning workspace flow (`utl/pla`) for snapshotting, target modeling, and plan artifacts
- `09-doc-pro-workflow-board.md`: manual `doc/pro` workflow operation, including parallel orchestration task flow

## Quality standard (required)

Each manual doc should include the following sections (or equivalent):

1. **Who this is for and what it solves**
   - One concise paragraph with user intent and scope boundaries.

2. **Prerequisites and safety boundaries**
   - Required tools, shell/runtime assumptions, and environment expectations.
   - Explicit note about whether commands are read-only, local-only, or state-changing.

3. **Step-by-step procedure with runnable commands**
   - Ordered steps with copy-paste-safe commands.
   - Prefer short command blocks over long scripts.

4. **Expected outcomes and validation**
   - What success looks like after each major step.
   - Include concrete validation commands when available.

5. **Failure handling and recovery guidance**
   - Common errors, likely causes, and the safest recovery path.
   - Distinguish usage/config errors from runtime/system failures.

6. **Related references**
   - Link to the next manual step and relevant architecture docs when helpful.

## Decision flow diagrams (when applicable)

When a manual doc presents multiple commands, modes, or execution paths that
the operator must choose between, include:

1. **A mermaid flowchart** that walks the reader through the decision points
   and maps each situation to the correct command.
2. **A summary table** immediately below the diagram with columns for command,
   when to use it, and side effects.

Place these after the introductory paragraph and before the prerequisites
section so the reader understands the command landscape before hitting any
procedure steps.

This is not required for linear single-path procedures (e.g., installation,
setup) -- only for docs where the reader's first question is "which command
do I use?"

Reference example: `07-dev-session-attribution-workflow.md` (Command Decision
Flow section).

## Writing style conventions

- Prefer current-state facts over aspirational language.
- Use concrete file/function names (`./go`, `cfg/core/ecc`, `ops gpu ptd -j`).
- Keep command examples minimal, deterministic, and executable as shown.
- Call out side effects clearly before destructive or state-changing actions.
- Keep prose concise and scannable with structured headings.
- Avoid repeating architecture internals unless needed for operator decisions.

## Command and snippet conventions

- Use fenced `bash` blocks for commands.
- Keep commands rooted at repository root unless stated otherwise.
- Use placeholders sparingly and name them clearly (`<site_name>`, `<node>`).
- For multi-mode commands, show the safest/default path first.
- Include at least one validation command in any procedural section.

## Traceability checklist (before merge)

For each changed manual doc, verify:

- [ ] Commands and flags exist and match current implementation.
- [ ] File paths and module names map to real files.
- [ ] Preconditions and side effects are explicitly stated.
- [ ] Validation steps are present and practical.
- [ ] Failure/recovery guidance is included for non-trivial procedures.
- [ ] Cross-links point to existing docs.

## Maintenance rule

If command contracts, configuration precedence, execution modes, or safety/logging
behavior changes in code, update the corresponding `doc/man/*.md` in the same PR.

Minimum expected pairings:
- `go`, `bin/ini`, `bin/orc` flow changes -> update `01-installation.md`
- `cfg/core/ecc` or `cfg/env/*` precedence/context changes -> update `02-configuration.md`
- `src/dic/*` or `ops` mode/usage contract changes -> update `03-cli-usage.md`
- `src/set/*` workflow or flags changes -> update `04-deployments.md`
- `lib/.spec`, `lib/ops/.spec`, `lib/ops/*` authoring contract changes -> update `05-writing-modules.md`
- `lib/gen/sec`, `lib/gen/aux`, `lib/core/lo1`, `lib/core/err` behavior changes -> update `06-security-and-logging.md`
- `utl/pla/*` command/workflow contract changes -> update `08-planning-workspace.md`
- `doc/pro/README.md`, `doc/pro/task/*`, or `doc/pro/check-workflow.sh` workflow contract changes -> update `09-doc-pro-workflow-board.md`

## Recommended update workflow

1. Read the target manual doc and its neighboring step docs.
2. Verify commands and behavior against source files.
3. Update prose to current-state, operator-facing guidance.
4. Add or refresh validation and recovery sections.
5. Run the traceability checklist above.

## Starter template for man docs

~~~md
# NN - Title

One-paragraph scope, audience, and boundaries.

## 1. Prerequisites and Safety

## 2. Procedure

### Step 1: ...
```bash
./go status
```

### Step 2: ...
```bash
ops <module> <function> -j
```

## 3. Validate

## 4. Troubleshooting and Recovery

## 5. Related Docs
~~~
