# 03 - Operational Modules (`lib/ops`) (Current State)

`lib/ops/*` is the infrastructure action layer. These modules expose callable Bash functions (for example `pve_*`, `gpu_*`, `net_*`, `sys_*`) that are sourced into the runtime shell and then executed either directly or through DIC dispatch (`src/dic/ops`). The boundary is: `lib/ops` performs operations; configuration lookup and argument injection happen outside this layer.

## 1. Responsibilities and Boundaries

| Area | Primary files | Responsibility boundary |
| --- | --- | --- |
| Operational function modules | `lib/ops/*` (extensionless) | Implements concrete infrastructure actions (VM, GPU, network, storage, users, services). |
| Loader path | `bin/orc` (`source_lib_ops`) | Sources ops modules in sorted order, excluding docs/hidden files. |
| Invocation path | `src/dic/ops` (`ops_execute`) | Resolves `module/function` and calls `module_function` in sourced ops file. |
| Contract baseline | `lib/.spec`, `lib/ops/.spec` | Defines naming, validation, logging, return code expectations. |

## 2. Runtime/Load Sequence

### Actual call/load order

1. `bin/ini` calls `setup_components` in `bin/orc`.
2. `setup_components` runs `source_lib_ops` (currently optional component in the orchestrator table).
3. `source_lib_ops` scans `LIB_OPS_DIR` with `find ... | sort -z`, excluding docs (`*.md`, `*.txt`, `*.spec`, `README*`, hidden files), then sources each file via `source_helper`.
4. A caller triggers an operation, most commonly via DIC command shape `ops <module> <function> ...` from `src/set/*` sections.
5. `src/dic/ops` runs `ops_execute`:
   - validates module path (`LIB_OPS_DIR/<module>`),
   - sources that module file,
   - validates function existence (`<module>_<function>`),
   - executes directly (utility `*_fun|*_var`) or through injection (`ops_inject_and_execute`).
6. The target `module_function` in sourced `lib/ops/*` files performs checks and side effects (system/service/config changes) and returns status.

### End-to-end sequence

```mermaid
sequenceDiagram
    autonumber
    participant I as bin/ini
    participant O as bin/orc
    participant L as lib/ops/*
    participant S as src/set/* section
    participant D as src/dic/ops
    participant F as module_function

    I->>O: setup_components()
    O->>O: execute_component(source_lib_ops)
    O->>L: source_lib_ops() -> source_helper(file)
    O-->>I: ops libraries available in shell

    S->>D: ops module function -j
    D->>D: ops_execute(module,function,args)
    D->>D: ops_validate_operation()
    D->>L: source LIB_OPS_DIR/module
    D->>D: declare -f module_function?

    alt utility function (*_fun|*_var)
        D->>F: module_function user_args
    else injected execution
        D->>D: ops_inject_and_execute()
        D->>D: ops_get_function_signature()
        D->>D: ops_resolve_single_variable() per param
        D->>F: module_function final_args
    end

    F-->>D: return code
    D-->>S: return code
```

### Conceptual flow (quick view)

```mermaid
flowchart LR
    A[bin/orc sources lib/ops] --> B[ops functions available]
    B --> C[src/set task section]
    C --> D[src/dic/ops dispatch]
    D --> E[lib/ops module_function]
    E --> F[Infrastructure state change]
```

## 3. State and Side Effects

- `lib/ops/*` files are sourced into the active shell/session, so all function names become globally callable after load.
- `source_lib_ops` uses source-time execution per file; source-time side effects in modules run immediately when loaded.
- Operational functions are the layer most likely to mutate real systems (packages, services, network config, VM/CT state, storage).
- DIC path re-sources module files on execution (`ops_execute`), so idempotent source blocks are important.

## 4. Failure and Fallback Behavior

- In bootstrap, ops loading is wrapper-managed by `execute_component`; current orchestrator marks the component optional.
- In DIC execution, missing `LIB_OPS_DIR`, missing module file, or missing target function returns `1` from `ops_execute`.
- If signature analysis fails in `ops_inject_and_execute`, DIC falls back to passing user args directly.
- Unresolved injected parameters become empty values unless the target function validates and rejects them.
- Function-level return semantics are module-defined, but project specs target: `0` success, `1` usage/validation, `2` runtime failure, `127` missing dependency.

## 5. Constraints and Refactor Notes

- Most ops modules are extensionless files; tooling that assumes `*.sh` will miss this layer.
- DIC dispatch requires stable module/function naming (`module` file + `module_function` symbol).
- `bin/orc` currently sources `lib/ops` before `lib/gen`; source-time hard dependencies on gen helpers can be brittle unless explicitly sourced.
- `lib/ops/.spec` requires structured logging via `aux_*`, explicit validation/check patterns, and `-x` execution flag for action-only functions.
- Deployment manifests are coupled to DIC command semantics (`ops module function -j`) rather than direct function signatures.

## Maintenance Note

Update this document in the same PR when any of these change: `source_lib_ops` filtering/loading behavior, `ops_execute` dispatch rules, module naming contracts, or ops return-code/validation/logging expectations enforced by specs.
