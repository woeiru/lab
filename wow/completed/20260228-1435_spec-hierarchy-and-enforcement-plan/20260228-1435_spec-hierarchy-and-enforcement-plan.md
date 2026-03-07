# Spec Hierarchy and Enforcement Improvement Plan

- Status: completed
- Owner: es
- Started: 2026-02-27
- Updated: 2026-03-07 16:02
- Links: `lib/.spec`, `lib/core/.spec`, `lib/gen/.spec`, `lib/ops/.spec`, `wow/completed/20260228-1435_spec-hierarchy-and-enforcement-plan/20260228-1435_spec-hierarchy-and-enforcement-plan.md`, `wow/active/waivers/waiver-register.md`

## Quick resume snapshot (read this first)

Current phase:

- Phase 5 of 6: strict-mode policy finalization + waiver burn-down.

What is done:

- Global/module hierarchy refactor completed (`lib/.spec` global-only, `lib/ops/.spec` specialized).
- Rule-to-test matrix added and aligned with current `val/` coverage.
- Report-mode compliance runners are available for `core`, `gen`, and `ops`.
- `core` and `gen` scanner noise was reduced; `gen` hard failures were remediated to zero.
- `GLB-008` secret scanner added: `val/core/glb_008_secret_scan_test.sh`.
- Strict dry runs are green for `core`, `gen`, and `ops` compliance runners.

Where we are blocked or pending:

- `GLB-008` has one active match and is now tracked under a temporary waiver:
  - `lib/gen/inf:90` -> `declare -g CT_DEFAULT_PASSWORD="password"`
- `ops` module is still below strict cutover floors for validation/help coverage.

Latest known report baseline:

- `core`: `Rule failures: 0`, `Rule warnings: 9`.
- `gen`: `Rule failures: 0`, `Rule warnings: 20`.
- `ops`: report suite green; coverage currently `2%` validation, `24%` help, `86%` error, `99%` docs, `65%` aux.
- `GLB-008`: 1 potential match (above).

Exactly what to do next (in order):

1. Keep `GLB-008` waiver active until replacement path lands (env/explicit password input).
2. Implement `lib/gen/inf` password-default remediation and remove waiver `WVR-2026-001`.
3. Raise `ops` validation/help coverage to meet strict cutover floors.

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

Current pause readiness: met (`2026-02-28`) with active waiver `WVR-2026-001` recorded and refreshed baseline captured.

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

## Module default enforcement policy (decision)

Decision date: `2026-02-28`

- `core`: strict default is allowed now (current gate met: `0` failures, `9` warnings, strict dry run green).
- `gen`: strict default is allowed now (current gate met: `0` failures, `20` warnings, strict dry run green).
- `ops`: keep report-first workflow until floor metrics are met (`validation >= 15%`, `help >= 35%`, others already at/above floor).
- Operational rule: direct strict runs remain available for all modules; policy gating in shared workflows should only flip to strict-by-default when cutover gates are satisfied.

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

1. Remove hardcoded `CT_DEFAULT_PASSWORD` path in `lib/gen/inf` and close waiver `WVR-2026-001`.
2. Improve `ops` parameter validation from `2%` to at least `15%`.
3. Improve `ops` help-system coverage from `24%` to at least `35%`.

## Status checkpoint (2026-02-28, refreshed)

Done:

- `lib/.spec` was reduced to global-only baseline with enforceable `GLB-*` rules.
- `lib/ops/.spec` now holds ops/DIC-specific `OPS-*` specialization rules.
- Rule-to-test matrix was added and linked to `val/` checks.
- Report-mode compliance entrypoints are available for `core`, `gen`, and `ops`.
- Scanner signal quality was improved for `core` and `gen` (false-positive reduction).
- First remediation pass completed in `lib/gen` (`ana`, `aux`, `env`) to clear current hard failures.
- Fresh baseline rerun completed (report + strict dry run):
  - `./val/core/std_compliance_test.sh --report` -> `Rule failures: 0`, `Rule warnings: 9`
  - `./val/lib/gen/std_compliance_test.sh --report` -> `Rule failures: 0`, `Rule warnings: 20`
  - `./val/lib/ops/std_compliance_test.sh --report` -> `2%` validation, `24%` help, `86%` error, `99%` docs, `65%` aux
  - `./val/core/glb_008_secret_scan_test.sh --report` -> `Potential secret matches: 1` (waived)
  - Strict dry runs: `./val/core/std_compliance_test.sh`, `./val/lib/gen/std_compliance_test.sh`, and `./val/lib/ops/std_compliance_test.sh` all exit successfully.

In progress:

- Raise `ops` validation/help coverage to strict-cutover floors.
- Track approved temporary `GLB-008` waiver and prepare removal change.

Next:

1. Implement replacement for hardcoded `CT_DEFAULT_PASSWORD` and remove waiver.
2. Land focused `ops` remediation for validation/help coverage floors.
3. Re-run two consecutive report baselines to confirm non-regression before strict-default expansion.

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
- phased migration timelines and rollout playbooks -> `wow/*` planning docs.
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

These IDs are consumed by the current rule-to-test matrix in `val/` and will be expanded incrementally.

## Rule-to-test matrix (first implementation)

Global rules:

- `GLB-001` -> `val/core/std_compliance_test.sh` (naming checks), `val/lib/gen/std_compliance_test.sh` (naming checks), `val/lib/ops/std_compliance_test.sh` (module function naming patterns).
- `GLB-003` -> `val/core/std_compliance_test.sh` (help return behavior scan), `val/lib/gen/std_compliance_test.sh` (help return behavior scan), `val/lib/ops/std_compliance_test.sh` (help-system checks).
- `GLB-004` -> `val/lib/gen/std_compliance_test.sh` (invalid-usage path presence), `val/lib/ops/std_compliance_test.sh` (validation + usage behavior checks).
- `GLB-005` -> `val/core/std_compliance_test.sh` and `val/lib/gen/std_compliance_test.sh` (3-line usage block + technical sections).
- `GLB-007` -> `val/lib/ops/std_compliance_test.sh` (error/return code pattern checks).
- `GLB-008` -> `val/core/glb_008_secret_scan_test.sh` (secret-like literal assignment scan, waiver-aware review process).
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

### Move from `lib/.spec` to project docs (`wow/` or `doc/ref`)

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
- process-oriented guidance lives in `wow/*`; reference examples live in `doc/ref/*` or module docs.

## Container password finding: what it actually is

The current `GLB-008` alert is not about a detected leaked production credential. It is about a hardcoded default value in code:

- `lib/gen/inf:90` sets `CT_DEFAULT_PASSWORD="password"`.

Why the scanner flags it:

- `GLB-008` policy forbids hardcoded secret-like assignments in `lib/*`.
- The scanner intentionally treats variables containing names like `PASSWORD`, `TOKEN`, `SECRET`, `API_KEY` as sensitive by default.
- A literal value such as `"password"` is interpreted as an insecure built-in credential pattern, even if intended as a bootstrap placeholder.

Why this matters operationally:

- If callers do not override this default, container creation paths can inherit a known weak credential.
- The risk is configuration drift: one forgotten override can leave reachable infrastructure with predictable auth.

What we are tackling in this phase:

- We are converting standards from advisory text into enforceable policy.
- This finding is the first concrete gate proving the enforcement model works.
- The task is to either remediate the code path or add a temporary waiver with owner/date/removal criteria.

## GLB-008 remediation decision and implementation plan

Current decision: apply a temporary waiver now, then remediate in a scheduled follow-up.

Target behavior (for waiver removal):

1. Replace the literal default assignment in `lib/gen/inf` with a non-hardcoded source (for example environment-backed empty default).
2. Ensure call sites fail safely when no password is provided (or require explicit override in environment config).
3. Re-run `./val/core/glb_008_secret_scan_test.sh --report` and capture baseline update in this document.

Approved temporary waiver entry:

- Rule: `GLB-008`
- Location: `lib/gen/inf:90`
- Current match: `declare -g CT_DEFAULT_PASSWORD="password"`
- Owner: `es`
- Approved by: `user direction in active planning session`
- Rationale: keep backward compatibility for current container-definition flows while strict enforcement is being rolled out in report mode.
- Risk level: medium (known weak default, mitigated by environment-specific overrides where present).
- Expiry date: `2026-03-31`
- Removal criteria: replace literal default with env/explicit input path and validate no regression in container definition flows.
- Tracking action: create remediation change in `lib/gen/inf` and rerun `./val/core/glb_008_secret_scan_test.sh --report`.

Verification snapshot (post-waiver documentation):

- Date: `2026-02-28`
- Command: `./val/core/glb_008_secret_scan_test.sh --report`
- Result: `Potential secret matches: 1` (waived match at `lib/gen/inf:90`).

Definition of done for this item:

- `GLB-008` report shows no unwaived match for `lib/gen/inf:90`.
- This plan records chosen approach (fix or waiver) and verification output date.
