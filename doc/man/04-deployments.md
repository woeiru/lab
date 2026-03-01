# 04 - Deployments and Runbooks

This guide explains how deployment runbooks in `src/set/` are structured and executed.
These scripts orchestrate multi-step infrastructure actions by calling `ops` functions.

## 1. Prerequisites and Safety

- Load runtime first in the current shell (`lab`) before using runbooks.
- Verify configuration context (`SITE_NAME`, `ENVIRONMENT_NAME`, `NODE_NAME`) before execution.
- Treat runbook execution as state-changing: many sections modify real infrastructure.

Recommended pre-checks:

```bash
./go status
env_status
```

## 2. Runbook Structure (`src/set/*`)

Each runbook (for example `src/set/h1`) usually follows this pattern:

1. define script-local path helpers (`DIR_SH`, `FILE_SH`),
2. source `src/set/.menu`,
3. source `src/dic/ops`,
4. declare `MENU_OPTIONS` (`section_id -> section_function`),
5. implement section functions (typically `*_xall`) that call `ops ... -j`,
6. delegate argument handling to `setup_main "$@"`.

Example section style:

```bash
a_xall() {
    ops pve dsr -j
    ops usr adr -j
    ops pve rsn -j
}
```

## 3. Execution Modes

### Interactive mode (`-i`)

```bash
./src/set/h1 -i
```

Interactive mode uses `src/set/.menu` for guided section selection and display options.

### Direct mode (`-x <section>`)

```bash
./src/set/h1 -x a
```

Direct mode executes one section immediately (for example `a_xall`) and is the common automation path.

## 4. Operational Workflow (Recommended)

1. Validate context and config (`env_status`, `bash -n` on edited files).
2. Start with one bounded section (`-x <section>`) before wider runs.
3. Use DIC preview/help for unfamiliar calls (`ops <module> <function>`, `--help`).
4. Move to interactive mode when selecting multiple sections manually.

## 5. Authoring a New Runbook

Create a new file in `src/set/` and follow existing runbooks (`h1`, `c1`, `t1`) as reference.

Minimal pattern:

```bash
#!/bin/bash
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"

source "${DIR_SH}/.menu"
source "${DIR_SH}/../dic/ops"

declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"

a_xall() {
    ops sys ipa -j
}

if [ $# -eq 0 ]; then
    print_usage
else
    setup_main "$@"
fi
```

## 6. Validate Runbook Changes

Syntax-check changed runbooks:

```bash
bash -n src/set/h1
```

Then validate with increasing scope:

```bash
./val/run_all_tests.sh src
./val/run_all_tests.sh integration
```

Run full suite for broad refactors:

```bash
./val/run_all_tests.sh
```

## 7. Troubleshooting and Recovery

### `Invalid section` or section not found

- Confirm section ID exists in `MENU_OPTIONS`.
- Confirm mapped function exists and name matches exactly.

### `ops` commands fail inside a runbook

- Ensure runtime is loaded (`lab`).
- Validate module/function names with `ops --list` and `ops <module> --list`.
- Check config variables required by target functions.

### Runbook behavior differs by host

- Confirm hostname-prefixed values in `cfg/env/*` match `hostname -s`.
- Confirm active node context in `cfg/core/ecc` and `env_status` output.

## 8. Related Docs

- Next: [05 - Writing Modules](05-writing-modules.md)
- DIC usage details: [03 - CLI Usage and the DIC](03-cli-usage.md)
- Architecture context: [doc/arc/05-deployment-and-config.md](../arc/05-deployment-and-config.md)
