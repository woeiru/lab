## Strict Senior Review: `ana_rdp` Implementation

### Scope Reviewed
- Commit: `41f21ac4` (`lib/gen/ana`, `val/lib/gen/ana_rdp_test.sh`)
- Goal: Implement `ana_rdp` (Reverse Dependency Call Graph) per section 3.5

### Validation Run
- `bash -n lib/gen/ana` -> pass
- `bash -n val/lib/gen/ana_rdp_test.sh` -> pass
- `./val/lib/gen/ana_rdp_test.sh` -> pass (5/5)

### Findings (ranked by severity)

#### High
1. **Scope/constraint violation**
   - **Location:** `lib/gen/ana` (code after `ana_rdp`, starting around `ana_tst` and `ana_err` additions)
   - **Impact:** Change exceeds requested scope (requested: add `ana_rdp` without modifying existing behavior). Raises blast radius and review risk.
   - **Recommended fix:** Split into focused commits; keep this change to `ana_rdp` + companion `ana_rdp` tests only.

2. **Exported-function detection is incomplete**
   - **Location:** `lib/gen/ana` in `ana_rdp`, function extraction regex
   - **Impact:** Misses valid Bash forms like `function name() {` and spacing variants (`name () {`), causing false negatives in reverse dependency output.
   - **Recommended fix:** Expand regex to support optional `function` keyword and whitespace variants.

#### Medium
3. **Call matching may over/under-count**
   - **Location:** `lib/gen/ana` in grep scan (`grep -rcE "\b${func}\b"`)
   - **Impact:** Counts textual mentions in comments/strings and may include non-invocation contexts; analysis quality can degrade.
   - **Recommended fix:** Use stricter invocation-focused pattern and exclude comment/declaration matches.

4. **JSON generation lacks string escaping**
   - **Location:** `lib/gen/ana` JSON output block in `ana_rdp`
   - **Impact:** Special characters in strings can produce invalid JSON.
   - **Recommended fix:** Add `_ana_rdp_json_escape` helper and escape all string fields.

5. **Performance concern for large targets**
   - **Location:** `lib/gen/ana` loop running recursive grep per exported function
   - **Impact:** Scales poorly (`O(functions * files)`), can become slow for larger modules/repositories.
   - **Recommended fix:** Move to single-pass aggregation over candidate files.

#### Low
6. **Tests are narrow and environment-coupled**
   - **Location:** `val/lib/gen/ana_rdp_test.sh`
   - **Impact:** Assumes repository-specific call sites and does not validate JSON robustness deeply.
   - **Recommended fix:** Add fixture-based tests for deterministic behavior, no-dependency paths, and JSON validity checks.

7. **Internal helpers can leak into global shell scope**
   - **Location:** `lib/gen/ana`, helpers defined inside `ana_rdp`
   - **Impact:** In Bash, such function declarations persist globally after execution; potential namespace clutter.
   - **Recommended fix:** Define `_ana_rdp_*` helpers once at file scope or clean up with `unset -f` after use.

### Top 3 fixes to do first
1. Limit this change strictly to `ana_rdp` scope (split unrelated additions).
2. Fix function-export detection regex to cover valid Bash declaration variants.
3. Harden analysis output quality: invocation-aware matching + safe JSON escaping.
