# Reference Docs

This folder contains generated reference tables that mirror the terminal analyzers.

## Files

- `functions.md`: function inventory and metadata generated from `ana_laf`
- `variables.md`: variable usage/cross-folder analysis generated from `ana_acu`
- `dependencies.md`: reverse dependency mapping generated from `ana_rdp`
- `module-dependencies.md`: direct module dependency mapping generated from `ana_dep`
- `test-coverage.md`: test traceability mapping generated from `ana_tst`
- `scope-integrity.md`: variable scope integrity mapping generated from `ana_scp`
- `error-handling.md`: return/exit/error-log mapping generated from `ana_err`

## Source of Truth

Reference output is expected to match the analyzer cycle aliases in `cfg/ali/sta`:

- `ffl-laf_cycle` -> functions pipeline
- `ffl-acu_cycle` -> variables pipeline
- `ffl-rdp_cycle` -> dependencies pipeline
- `ffl-dep_cycle` -> module dependency pipeline
- `ffl-tst_cycle` -> test coverage pipeline
- `ffl-scp_cycle` -> scope integrity pipeline
- `ffl-err_cycle` -> error handling pipeline

## Regenerate

Run from repository root:

```bash
./utl/doc/run_all_doc.sh
```

Or regenerate one reference only:

```bash
./utl/doc/run_all_doc.sh functions
./utl/doc/run_all_doc.sh variables
./utl/doc/run_all_doc.sh dependencies
./utl/doc/run_all_doc.sh module-dependencies
./utl/doc/run_all_doc.sh test-coverage
./utl/doc/run_all_doc.sh scope-integrity
./utl/doc/run_all_doc.sh error-handling
```

## Pipeline Notes

- Generators live under `utl/doc/generators/`.
- Auto-generated table blocks are replaced between:
  - `<!-- AUTO-GENERATED SECTION: ... -->`
  - `<!-- END AUTO-GENERATED SECTION -->`
- Intermediate JSON files are written to:
- `.tmp/doc/laf/` for functions
- `.tmp/doc/acu/` for variables
- `.tmp/doc/rdp/` for dependencies
- `.tmp/doc/dep/` for module dependencies
- `.tmp/doc/tst/` for test coverage
- `.tmp/doc/scp/` for scope integrity
- `.tmp/doc/err/` for error handling

For full architecture and generator behavior, see `../../utl/doc/README.md`.

## Required Parity With `cfg/ali/sta` Cycles

The expected behavior is strict parity between cycle aliases in `cfg/ali/sta`
and the generated markdown outputs in this folder.

- `_ffl_laf_cycle` output must match `functions.md`
- `_ffl_acu_cycle` output must match `variables.md`
- `_ffl_rdp_cycle` output must match `dependencies.md`
- `_ffl_dep_cycle` output must match `module-dependencies.md`
- `_ffl_tst_cycle` output must match `test-coverage.md`
- `_ffl_scp_cycle` output must match `scope-integrity.md`
- `_ffl_err_cycle` output must match `error-handling.md`

In practice, this means no missing rows and no extra rows in `doc/ref/*.md`
relative to their corresponding cycle output.
