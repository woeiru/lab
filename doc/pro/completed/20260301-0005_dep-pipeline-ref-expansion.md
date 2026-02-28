# DEP Pipeline Expansion (Completed)

## Goal

Add a fourth reference pipeline at parity with LAF/ACU/RDP by integrating `ana_dep` into:

- alias cycle API (`ffl-dep_*`, `ffl-dep_cycle`)
- documentation generation (`utl/doc/generators/dep`)
- reference output (`doc/ref/module-dependencies.md`)

## Implemented Scope

1. **Second-layer alias wrappers in `cfg/ali/sta`**
   - Added: `_ffl_dep_go`, `_ffl_dep_bin`, `_ffl_dep_core`, `_ffl_dep_gen`, `_ffl_dep_ops`, `_ffl_dep_src`, `_ffl_dep_utl`, `_ffl_dep_cycle`
   - Added public aliases: `ffl-dep_go`, `ffl-dep_bin`, `ffl-dep_core`, `ffl-dep_gen`, `ffl-dep_ops`, `ffl-dep_src`, `ffl-dep_utl`, `ffl-dep_cycle`
   - Cycle scope is the broadest practical code scope: root `go`, `bin`, `lib/*`, `src`, `utl`.

2. **`ana_dep` compatibility and doc-pipeline support in `lib/gen/ana`**
   - Added `--json-dir <dir>` support to `ana_dep`.
   - Added compatibility handling for empty flag arguments (`""`) passed by `aux_ffl` wrappers.

3. **New generator `utl/doc/generators/dep`**
   - Uses `ana_dep -j --json-dir .tmp/doc/dep`.
   - Renders a markdown table of per-module script imports and host commands.
   - Updates `doc/ref/module-dependencies.md` auto-generated section.

4. **Orchestrator/config wiring**
   - Added generator target `module-dependencies` -> `dep` in `utl/doc/run_all_doc.sh`.
   - Added `dep` output/section mappings in `utl/doc/config/targets`.

5. **Reference docs updates**
   - Added new reference page: `doc/ref/module-dependencies.md`.
   - Updated pipeline parity docs in `doc/ref/README.md`.
   - Updated generator architecture docs in `utl/doc/README.md`.

## Execution and Validation

- Ran `./utl/doc/run_all_doc.sh module-dependencies` and verified successful generation.
- Ran `./utl/doc/run_all_doc.sh --list` and confirmed `module-dependencies` appears in targets.
- Validated DEP cycle execution through loaded function path via `_ffl_dep_cycle -j`.

## Outcome

- Fourth reference pipeline is now operational at parity scope with existing LAF/ACU/RDP doc pipelines.
- Topic is closed and moved from active tracking to completed.
