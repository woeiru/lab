# Spec Hierarchy and Enforcement Improvement Plan

- Status: active
- Owner: es
- Started: 2026-02-27
- Updated: 2026-02-28
- Links: `lib/.spec`, `lib/core/.spec`, `lib/gen/.spec`, `lib/ops/.spec`, `doc/pro/active/spec-hierarchy-and-enforcement-plan.md`

## Quick resume snapshot (read this first)

Current phase:

- Phase 4 of 6: report-mode stabilization + strict-mode cutover preparation.

What is done:

- Global/module hierarchy refactor completed (`lib/.spec` global-only, `lib/ops/.spec` specialized).
- Rule-to-test matrix added and aligned with current `val/` coverage.
- Report-mode compliance runners are available for `core`, `gen`, and `ops`.
- `core` and `gen` scanner noise was reduced; `gen` hard failures were remediated to zero.
- `GLB-008` secret scanner added: `val/core/glb_008_secret_scan_test.sh`.

Where we are blocked or pending:

- One active `GLB-008` finding remains:
  - `lib/gen/inf:90` -> `declare -g CT_DEFAULT_PASSWORD="password"`
- Strict-mode default behavior is not yet wired as module policy.

Latest known report baseline:

- `core`: `Rule failures: 0`, warnings-only.
- `gen`: `Rule failures: 0`, warnings-only.
- `ops`: report suite green; coverage remains improvement-focused (validation/help are lowest).
- `GLB-008`: 1 potential match (above).

Exactly what to do next (in order):

1. Resolve or explicitly waive the `GLB-008` finding in `lib/gen/inf:90`.
2. Decide and implement module strict/report default behavior using cutover gates.
3. Re-run baseline commands and record new snapshot in this file.

Resume command set:

```bash
./val/core/std_compliance_test.sh --report
./val/lib/gen/std_compliance_test.sh --report
./val/lib/ops/std_compliance_test.sh --report
./val/core/glb_008_secret_scan_test.sh --report
```

Definition of ready-to-pause state:

- Snapshot section updated with latest numbers and date.
- Any open finding has either code fix or documented waiver (owner + removal date).
- Next 1-3 concrete actions are listed before pausing.

This plan turns the current hierarchy work into an enforcement-grade standards model.

## Goal

Deliver a professional, testable, and non-contradictory `.spec` framework where:

- `lib/.spec` is concise and global-only.
- Module specs are strict specializations (`core`, `gen`, `ops`) with no scope bleed.
- Validation rules in `val/` can be enforced gradually, then switched to strict mode.

## Why this is active now

Current `.spec` files have strong direction but are not yet fully enforcement-ready:

- `lib/.spec` mixes global baseline with deep `ops`-only policy and migration guidance.
- Some language is advisory where enforcement requires normative wording.
- Duplication across files increases drift risk.

## Scope

In scope:

- Refactor `.spec` content by scope and precedence.
- Normalize rule language to enforceable terms.
- Define a direct mapping from rules to compliance checks.

Out of scope:

- Runtime behavior refactors in `lib/ops`.
- Live infrastructure execution.

## Workstreams

## 1) Baseline normalization (`lib/.spec`)

1. Keep only global requirements that apply to all `lib/*` modules.
2. Remove module-specific deep policy from global file.
3. Convert broad guidance into short, testable rules.

Deliverable:

- A compact global baseline with explicit MUST/SHOULD semantics.

## 2) Module specialization tightening

1. Keep `lib/core/.spec` bootstrap-safe and minimal dependency focused.
2. Keep `lib/gen/.spec` helper/utility constraints and help-contract expectations.
3. Move all `ops`-exclusive standards into `lib/ops/.spec`.

Deliverable:

- Clear separation of concerns with no rule duplication.

## 3) Enforcement mapping to `val/`

1. Build a rule-to-test matrix (rule id -> test check).
2. Add report mode first for `core` and `gen` compliance checks.
3. Define strict-mode cutover criteria.

Deliverable:

- Enforceable checks aligned to documented rules.

## 4) Language and professionalism pass

1. Standardize normative terms (`MUST`, `SHOULD`, `MAY`) across all `.spec` files.
2. Eliminate conflicting statements and ambiguous exceptions.
3. Keep examples short and non-authoritative (rules first, examples second).

Deliverable:

- Consistent professional tone and interpretation-safe wording.

## Execution sequence

1. Draft target outline for `lib/.spec` (global-only).
2. Relocate `ops`-specific sections from `lib/.spec` to `lib/ops/.spec`.
3. Run a contradiction/duplication pass across all four `.spec` files.
4. Update compliance tests in report mode.
5. Remediate gaps module-by-module.
6. Switch enforcement to strict mode after pass criteria are met.

## Acceptance criteria

- No module-specific policy remains in `lib/.spec`.
- Each `.spec` states scope, inheritance, and conflict behavior.
- Every MUST rule is either already checked in `val/` or has a planned check.
- No contradictory rule pairs remain across global and module specs.

## Strict-mode cutover criteria

Cutover happens per module (not all-at-once) after two consecutive clean report runs.

`core` cutover gate:

- `./val/core/std_compliance_test.sh --report` shows `Rule failures: 0`.
- Warning budget: `<= 10` warnings, with no new warning classes introduced.
- A strict dry run (`./val/core/std_compliance_test.sh`) is green in CI/local validation.

`gen` cutover gate:

- `./val/lib/gen/std_compliance_test.sh --report` shows `Rule failures: 0`.
- Warning budget: `<= 20` warnings, and all warnings are explicitly categorized as:
  - compatibility entrypoints (`main`),
  - non-prefixed internal aliases,
  - advisory integration checks.
- A strict dry run (`./val/lib/gen/std_compliance_test.sh`) is green in CI/local validation.

`ops` cutover gate:

- `./val/lib/ops/std_compliance_test.sh --report` completes successfully and trend is non-regressive over two runs.
- Required floor before strict mode:
  - parameter validation >= `15%`
  - help-system coverage >= `35%`
  - error handling >= `85%`
  - documentation >= `95%`
  - aux integration >= `65%`
- A focused remediation list exists for the largest remaining gaps (validation/help).
- Strict mode is enabled only after floors are met and sampled strict dry run does not block core workflows.

Global cutover gate:

- `GLB-008` scanner exists (or has approved temporary waiver with owner/date).
- `val/core/log_contract_test.sh` remains green.
- No regression in module report totals versus previous accepted baseline.

Rollback rule:

- If a cutover causes repeated false positives or blocks unrelated work, switch module back to `--report` default, log the root cause in this plan, and re-run tuning before retrying strict mode.

## Risks and mitigations

- Risk: over-specification creates noisy failures.
  - Mitigation: keep baseline short; move guidance into docs, not normative spec.
- Risk: parser misses extensionless Bash function styles.
  - Mitigation: validate checks against representative files in `lib/core`, `lib/gen`, `lib/ops`.
- Risk: rollout churn in documentation blocks.
  - Mitigation: report-mode first, strict mode only after module cleanup.

## Immediate next actions

1. Draft the rule-to-test matrix for `val/` implementation.
2. Add or update compliance tests for `GLB-*` and `OPS-*` rule coverage in report mode.
3. Run module-level compliance checks and capture remediation gaps.

## Status checkpoint (2026-02-28)

Done:

- `lib/.spec` was reduced to global-only baseline with enforceable `GLB-*` rules.
- `lib/ops/.spec` now holds ops/DIC-specific `OPS-*` specialization rules.
- Rule-to-test matrix was added and linked to `val/` checks.
- Report-mode compliance entrypoints are available for `core`, `gen`, and `ops`.
- Scanner signal quality was improved for `core` and `gen` (false-positive reduction).
- First remediation pass completed in `lib/gen` (`ana`, `aux`, `env`) to clear current hard failures.

In progress:

- Align `ops` report quality with `core`/`gen` by reducing false positives in module-scoped checks.
- Triage `GLB-008` scanner findings and classify true positives vs accepted defaults.

Next:

1. Finish `ops` signal-quality pass and rerun report baseline.
2. Wire strict-mode cutover criteria into module default runner behavior.
3. Remediate or explicitly waive current `GLB-008` finding in `lib/gen/inf`.

## Proposed target outline for `lib/.spec` (global-only)

`lib/.spec` should be reduced to a short normative baseline that can be enforced across `lib/core`, `lib/gen`, and `lib/ops`.

Recommended final structure:

1. Purpose, scope, and precedence
   - Scope applies to all functions under `lib/*`.
   - Precedence rule: module `.spec` can tighten, never weaken global baseline.
2. Global naming and structure rules
   - Public function naming format.
   - Internal helper naming expectations.
   - Local variable style and quoting baseline.
3. Help and documentation contract
   - `--help`/`-h` handling requirement and return code.
   - 3-line `aux_use` extraction block requirement where `aux_use` is in use.
   - Technical block minimum headers (`Technical Description`, `Dependencies`, `Arguments`).
4. Validation and return-code contract
   - Parameter validation requirement (module-aware implementation).
   - Required return code meanings: `0`, `1`, `2`, `127`.
5. Dependency and error-handling baseline
   - Check dependencies before execution when external commands/resources are needed.
   - Error messages must be actionable and context-rich.
6. Safety baseline
   - Safe file update patterns for destructive edits.
   - No hardcoded secrets/credentials.
7. Logging baseline by module capability
   - Global principle only: structured logging required for operational messages in modules that provide logging helpers.
   - Keep exact logging policy details in module specs.
8. Testability requirement
   - Rules included in this file must be traceable to compliance checks or explicitly marked advisory.
9. Non-goals and exclusions
   - No module-specific workflow steps.
   - No migration schedule content.
   - No deep examples that can drift from rules.

## Content relocation map (`lib/.spec` -> destination)

Move out of `lib/.spec` into module/docs locations:

- `ops`-exclusive logging conversion guidance and examples -> `lib/ops/.spec`.
- `ops` operational category matrices and decision trees -> `lib/ops/.spec`.
- phased migration timelines and rollout playbooks -> `doc/pro/*` planning docs.
- environment profile examples (dev/prod/testing toggles) -> `doc/ref/` or module docs.

Keep in `lib/.spec` only if it applies to all `lib/*` modules without exception.

## Draft rule IDs for enforcement-ready baseline

- `GLB-001`: hierarchy and precedence defined.
- `GLB-002`: global naming convention for public functions.
- `GLB-003`: help flag handling returns `0`.
- `GLB-004`: invalid usage returns `1` with usage output path.
- `GLB-005`: technical block contains required section headers.
- `GLB-006`: external dependency checks required before use.
- `GLB-007`: return codes use canonical meanings (`0/1/2/127`).
- `GLB-008`: secrets must not be hardcoded.
- `GLB-009`: destructive file changes use safe write pattern.
- `GLB-010`: each MUST rule maps to a compliance check or documented waiver.

These IDs are intended to be consumed by the upcoming rule-to-test matrix in `val/`.

## Rule-to-test matrix (first implementation)

Global rules:

- `GLB-001` -> `val/core/std_compliance_test.sh` (naming checks), `val/lib/gen/std_compliance_test.sh` (naming checks), `val/lib/ops/std_compliance_test.sh` (module function naming patterns).
- `GLB-003` -> `val/core/std_compliance_test.sh` (help return behavior scan), `val/lib/gen/std_compliance_test.sh` (help return behavior scan), `val/lib/ops/std_compliance_test.sh` (help-system checks).
- `GLB-004` -> `val/lib/gen/std_compliance_test.sh` (invalid-usage path presence), `val/lib/ops/std_compliance_test.sh` (validation + usage behavior checks).
- `GLB-005` -> `val/core/std_compliance_test.sh` and `val/lib/gen/std_compliance_test.sh` (3-line usage block + technical sections).
- `GLB-007` -> `val/lib/ops/std_compliance_test.sh` (error/return code pattern checks).
- `GLB-008` -> planned follow-up scanner for secret hardcoding patterns (not yet implemented).
- `GLB-009` -> `val/lib/ops/std_compliance_test.sh` (error handling/explicit return path checks, partial coverage).
- `GLB-010` -> this matrix section + active checklist mapping (process gate).

Ops rules:

- `OPS-004` / `OPS-005` / `OPS-006` -> `val/lib/ops/std_compliance_test.sh` (parameter/help validation behavior).
- `OPS-007` / `OPS-008` / `OPS-010` -> `val/lib/ops/std_compliance_test.sh` (aux logging and logging pattern checks).
- `OPS-012` / `OPS-013` / `OPS-014` / `OPS-015` -> `val/lib/ops/std_compliance_test.sh` (validation, dependency, and return-code checks).
- `OPS-020` / `OPS-021` -> `val/lib/ops/std_compliance_test.sh` (documentation block checks).

Module-specific rollout:

- `lib/core`: report mode available via `./val/core/std_compliance_test.sh --report`.
- `lib/gen`: report mode available via `./val/lib/gen/std_compliance_test.sh --report`.
- `lib/ops`: report mode available via `./val/lib/ops/std_compliance_test.sh --report`.

## Exact extraction and cut list for current `lib/.spec`

This is the first-pass surgical map for moving `lib/.spec` to global-only content.

Status: executed on 2026-02-28. Line ranges in this section reference the pre-refactor snapshot and are retained for audit traceability.

### Keep in `lib/.spec` (with tightening)

- `lib/.spec:14` to `lib/.spec:35`
  - Keep hierarchy, scope, precedence, and conflict contract.
  - Tighten wording so enforceable statements are normative.
- `lib/.spec:38` to `lib/.spec:61`
  - Keep as compact global baseline (naming, help/doc contract, return codes, safety).
  - Remove module-coupled phrasing where it creates ambiguity.

### Move from `lib/.spec` to `lib/ops/.spec`

- `lib/.spec:63` to `lib/.spec:353`
  - Purpose and quality principles currently framed around operations/infrastructure behavior.
- `lib/.spec:355` to `lib/.spec:604`
  - Parameter validation standard section currently scoped to `ops`.
- `lib/.spec:605` to `lib/.spec:836`
  - Full structured logging standard and conversion examples.
- `lib/.spec:837` to `lib/.spec:1251`
  - Auxiliary integration framework, decision matrix, environment profiles, migration strategy.

### Move from `lib/.spec` to project docs (`doc/pro` or `doc/ref`)

- `lib/.spec:214` to `lib/.spec:238`
  - Implementation checklist (process guidance; not normative baseline spec).
- `lib/.spec:328` to `lib/.spec:335`
  - Implementation priority by module (rollout policy, not global rule).
- `lib/.spec:1231` to `lib/.spec:1251`
  - Week-based migration strategy (execution planning, not spec contract).

### Duplicate/overlap removal targets (after relocation)

- Remove duplicate naming and validation narratives that repeat existing baseline:
  - `lib/.spec:368` to `lib/.spec:377` (naming duplication)
  - `lib/.spec:378` to `lib/.spec:418` (validation duplication)
- Keep one canonical statement per rule in global baseline; examples move to module specs or docs.

### Contradiction fixes required during extraction

- Resolve baseline conflict between:
  - `lib/.spec:55` (core must not assume `aux_*` unless sourced)
  - `lib/.spec:845` onward (every function must include `aux_*` patterns)
- Resolve ambiguity of universal logging mandates by scoping strict logging requirements to `lib/ops/.spec`.
- Ensure `lib/.spec` does not prescribe module rollout order or operational categories.

### Output expected after this cut

- `lib/.spec` reduced to a concise global baseline (target: ~120-220 lines).
- `lib/ops/.spec` becomes the sole home for infrastructure-specific and DIC-heavy implementation policy.
- process-oriented guidance lives in `doc/pro/*`; reference examples live in `doc/ref/*` or module docs.
