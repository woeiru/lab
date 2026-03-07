# Implementation Plan: Enhancing `lib/gen/ana` for Terminal Analysis and API Documentation

## 1. Overview
The `ana` module (`lib/gen/ana`) currently provides excellent introspection for function signatures (`ana_fun`/`ana_laf`), variable configuration occurrences (`ana_var`/`ana_acu`), and basic markdown stats (`ana_lad`).

However, for a complete codebase overview in the terminal, and as a robust data-retrieval API for the `val/doc` documentation generator, we are missing key data points around **dependencies**, **test coverage**, **error handling**, and **scope safety**.

This document outlines a proposal for five new `ana` functions designed to be executed in the terminal and pipe structured data (JSON) to the documentation generator. Existing `ana` functions remain completely untouched to maintain current stability.

## 2. Identified Data Gaps

Currently missing from the `ana` data model:
1. **Module & Binary Dependencies**: Which host commands (`docker`, `pvesh`, `zfs`) and internal files does a module rely on?
2. **Test Traceability**: What tests cover a specific module, and how many assertions do they make?
3. **Error Boundaries**: What exit/return codes does a function throw, and what are its standard `aux_err`/`aux_warn` failure points?
4. **Scope Integrity**: Which variables are dynamically exported or mutate global state vs. safe `local` variables?
5. **Reverse Dependencies (Call Graphs)**: What high-level scripts rely on a given foundational utility?

## 3. Proposed New Functions

### 3.1 `ana_dep` (List Module Dependencies)
**Purpose**: Extracts external script imports and required host binaries.
* **Terminal UX**: `ana_dep lib/ops/pve`
* **Mechanics**:
  * Scans for `source` and `.` statements to build a sourcing tree.
  * Parses `aux_chk "command" "<binary>"` and `command -v` to list required host executables.
* **API / `val/doc` Benefit**: Auto-generates a "Prerequisites & Dependencies" table for the module's Markdown documentation and a repository-wide Dependency Graph (DAG).

### 3.2 `ana_tst` (Test Coverage Traceability)
**Purpose**: Maps library modules to their validation test suites.
* **Terminal UX**: `ana_tst lib/ops/srv`
* **Mechanics**:
  * Resolves the target file to its counterpart in `val/` (e.g., `val/lib/ops/srv_test.sh`).
  * Parses the test file to count BDD-style `it "should..."` or standard test blocks.
  * (Optional) Reads the last test execution status if logs are available.
* **API / `val/doc` Benefit**: Embeds a "Validation Summary" directly into the `doc/ref/` documentation, improving trust in the code.

### 3.3 `ana_err` (Error & Exit Code Analytics)
**Purpose**: Identifies potential failure modes and return codes for functions.
* **Terminal UX**: `ana_err lib/ops/pve pve_cdo` (or an entire file)
* **Mechanics**:
  * Uses regex to extract `return X` and `exit Y` explicitly mapped inside functions.
  * Extracts logging assertions like `aux_err`, `aux_warn`, `aux_val` failures.
* **API / `val/doc` Benefit**: Automatically populates the "Returns / Error Codes" section of API references, ensuring developers know exactly how to handle errors (e.g., `0` for Success, `1` for Params, `2` for Runtime).

### 3.4 `ana_scp` (Variable Scope & Integrity Analysis)
**Purpose**: Identifies global variables, constants, and potential scope leaks.
* **Terminal UX**: `ana_scp lib/gen/sec`
* **Mechanics**:
  * Detects `readonly` declarations and UPPERCASE globals mapping to environment constants.
  * Optionally flags assignments inside functions that lack `local` prefix.
* **API / `val/doc` Benefit**: Generates an "Environment State Mutated" table in the docs, highlighting side-effects of operations.

### 3.5 `ana_rdp` (Reverse Dependency Call Graph)
**Purpose**: Discovers what scripts depend on the target.
* **Terminal UX**: `ana_rdp lib/core/tme`
* **Mechanics**:
  * Performs a codebase-wide scan across `lib/ops/`, `src/set/`, and `bin/` to find invocations of the exported functions from the target file.
* **API / `val/doc` Benefit**: Adds a "Used By" section in `doc/ref/functions.md` to show architectural relationships and blast radius.

## 4. Implementation Strategy

**Parallel Execution Analysis & Notes**
This plan **CAN** be executed in parallel to save time. The proposed functions (`ana_dep`, `ana_tst`, `ana_err`, `ana_scp`, `ana_rdp`) are logically independent—each analyzes a distinct aspect of the codebase (dependencies, tests, errors, scope, and reverse-dependencies) without relying on the others.

To safely execute in parallel:
* **Concurrent Development:** Assign each `ana_XYZ` function (and its internal `_ana_XYZ_...` helpers) to a separate track or agent.
* **Conflict Mitigation:** Since all functions will be added to `lib/gen/ana`, coordinate append operations or use separate git branches to avoid merge conflicts.
* **Independent Validation:** The test files (`val/lib/gen/ana_XYZ_test.sh`) are entirely separate, allowing parallel test execution without interference.
* **Collapsed Phasing:** The phased rollout below can be ignored if resources permit parallel implementation; all phases can be tackled simultaneously.

1. **Format Standards**: Like existing `ana_laf`, all new functions must support:
   * A terminal-friendly tabular view.
   * A `-j` (JSON) mode specifically to serve as the data retriever for `val/doc`.
2. **Placement**: Add these to the end of `lib/gen/ana` using the standard `ana_XYZ` prefix. Keep internal logic in `_ana_XYZ_...` helpers.
3. **Rollout Order (Can be collapsed if parallelized)**:
   * Phase 1: `ana_dep` and `ana_tst` (highest immediate value for documentation scaffolding).
   * Phase 2: `ana_err` (critical for API contracts).
   * Phase 3: `ana_rdp` and `ana_scp` (advanced analysis/linting).
4. **Validation**: Each new function requires a test script (e.g., `val/lib/gen/ana_dep_test.sh`) ensuring both terminal output and JSON modes are accurate without regressions to the legacy parsers.

## 5. Next Steps
Review the proposed functions and metrics. Upon approval, begin implementing Phase 1 functions directly inside `lib/gen/ana` with companion tests under `val/`.
