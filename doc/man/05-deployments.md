# 05 - Deployments and Runbooks

Deployments are orchestrated using section-based scripts ("set scripts") located in `src/set/`. These are the primary runbooks used to provision nodes, configure hypervisors, and install software across the lab environment.

## The Structure of Set Scripts

Set scripts group logical infrastructure tasks into discrete, sequential sections.

For example, `src/set/h1` is the main runbook for a primary hypervisor node. Inside `src/set/h1`, you'll find functions named sequentially (e.g., `a_xall`, `b_xall`, `c_xall`).

- **`a_xall`**: Configure package managers and apt repositories.
- **`j_xall`**: Provision ZFS storage pools and datasets.
- **`q_xall`**: Create Proxmox containers or virtual machines.

The functions inside these sections rely entirely on the DIC (`ops <module> <function> -j`) to apply configurations automatically based on the environment defined in `cfg/env/`.
Each set script delegates to the shared runner by calling `setup_main "$@"`, keeping execution behavior consistent across nodes.

## Execution Modes

Set scripts can be executed interactively or headlessly, depending on whether you are running them manually or in a CI/CD pipeline.

### Interactive Mode (`-i`)

To run a deployment script interactively, use the `-i` flag:

```bash
./src/set/h1 -i
```

This utilizes the `src/set/.menu` framework to render a CLI menu. From this interface, you can:
- View the available deployment steps.
- Expand variables to see the exact execution context (what parameters the DIC will inject).
- Choose specific sections to run interactively.

### Direct Execution Mode (`-x`)

For automated pipelines or rapid daily usage, bypass the menu entirely using the `-x` flag. This executes a specific section headlessly.

```bash
./src/set/h1 -x a
```

This will instantly execute section `a_xall` without any prompts.

## Building Your Own Deployment

To create a custom deployment script for a new server or environment:

1. Create a new file in `src/set/` (e.g., `src/set/webserver`).
2. Source the shared set runner (`src/set/.menu`) and DIC entrypoint (`src/dic/ops`) at the top.
3. Define your deployment sections (e.g., `a_setup_nginx`, `b_copy_certs`).
4. Inside each section, use the DIC to invoke functions from `lib/ops/` using the `-j` flag.
5. Delegate execution to `setup_main "$@"` so `-i` and `-x` behavior stays consistent with existing set scripts.

## Validation After Changes

When editing deployment scripts or orchestration flow, validate in increasing scope:
- Syntax-check edited files with `bash -n <file>`.
- Run the nearest relevant test script directly when available.
- Run category/full validation for broader changes (`./val/run_all_tests.sh <category>` or `./val/run_all_tests.sh`).

Continue to [06 - Writing Modules](06-writing-modules.md) to understand how to extend the framework's capabilities with new `lib/ops/` functions.
