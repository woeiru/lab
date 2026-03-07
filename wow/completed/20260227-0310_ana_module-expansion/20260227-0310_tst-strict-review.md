# Strict Senior Review: `ana_tst` Implementation

Date: 2026-02-27
Scope: `lib/gen/ana` (`ana_tst`), `val/lib/gen/ana_tst_test.sh`

## Validation executed

- `bash -n lib/gen/ana` -> pass
- `bash -n val/lib/gen/ana_tst_test.sh` -> pass
- `./val/lib/gen/ana_tst_test.sh` -> fail (5/8)

## Status update (implemented)

### Resolved

1) JSON escaping and output generation in normal paths -> **partially resolved**
- JSON file is generated and basic schema fields are present.
- Current implementation still has strict `-j` cleanliness regressions (see remaining findings).

2) Baseline usage/table contract -> **resolved**
- Usage without args and standard table output are working for known targets.

3) No-test-found fallback messaging -> **resolved**
- `ana_tst` reports no-test scenarios instead of hard-failing.

## Remaining findings by severity

### High

1) No-match counter regression still present
- Impact: counter handling still fails in zero-match fixtures, causing test failure and inconsistent output contract.
- Evidence: `No-match counters bug` test failing in `val/lib/gen/ana_tst_test.sh`.
- Recommended fix: normalize counter default to `0` and avoid arithmetic on empty values.

2) Basename collision mapping still unresolved
- Impact: target-to-test mapping can select wrong mirrored test path when duplicate basenames exist.
- Evidence: `Ambiguous basename collisions` test failing.
- Recommended fix: enforce mirrored path resolution before basename fallback.

### Medium

3) `-j` mode emits non-JSON terminal artifacts
- Impact: downstream consumers expecting clean JSON mode output may break.
- Evidence: `Strict -j cleanliness` test failing.
- Recommended fix: suppress table separators/terminal formatting while `-j` is active.

### Low

4) Missing fixture coverage for complex path/quote cases
- Impact: future regressions in path normalization and JSON-safe output may slip through.
- Recommended fix: add fixtures for spaces/quotes and nested path mirroring.

## Top 3 fixes to do next

1. Fix no-match counter handling and arithmetic defaults.
2. Enforce mirrored path mapping to eliminate basename collision errors.
3. Make `-j` mode strictly clean (JSON-only + status line).
