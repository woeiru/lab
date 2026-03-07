# Documentation Overhaul Plan

Systematic rewrite of all README files and doc/ contents to match the precision and tone established in the root README.md.

## Guiding Principles

- No emoji headings or decorative formatting
- No vague marketing language, superlatives, or "success stories"
- Every statement must be verifiable against actual code
- Concise and scannable -- technical readers, not sales prospects
- Correct paths and commands only (many files reference nonexistent `./tst/`, `./entry.sh`, `./utl/doc-stats`, `./val/validate_system`)
- Preserve auto-generated section markers where `utl/doc` generators inject content

## Constraints: utl/doc Generator Targets

The following files contain auto-generated sections managed by `utl/doc/generators/`. The markers must be preserved exactly during rewrites so the generators can continue injecting content.

| Generator | Output File | Section Marker |
|-----------|-------------|----------------|
| `func` | `doc/man/functions.md` | `<!-- AUTO-GENERATED SECTION: DO NOT EDIT MANUALLY -->` |
| `hub` | `doc/README.md` | `<!-- AUTO-GENERATED SECTION: Documentation Structure -->` |
| `var` | `doc/man/variables.md` | `<!-- AUTO-GENERATED SECTION: DO NOT EDIT MANUALLY -->` |

The `stats` generator target for `README.md` is commented out in `utl/doc/config/targets` (lines 106, 118) and has already been removed from the root README.

## Inventory: All Files in Scope

### README Files (13 files, excluding root which is done)

Note: `doc/adm/`, `doc/cli/`, and `doc/dev/` subdirectories no longer exist -- their content files were consolidated into `doc/man/`. No README files exist for those former subdirectories.

| # | File | Lines | Severity | Notes |
|---|------|-------|----------|-------|
| 1 | `bin/README.md` | 170 | High | Emoji headings, inflated language, references `init` (file is `ini`), bloated best-practices filler |
| 2 | `cfg/README.md` | 147 | High | Emoji headings, vague features list, references nonexistent `ans/` subdir |
| 3 | `cfg/log/README.md` | 68 | Medium | Reasonable content but uses `#` on line 2 as plain text, could be tighter |
| 4 | `cfg/pod/shus/README.md` | 120 | Low | Operational runbook with real commands -- mostly fine, minor cleanup |
| 5 | `cfg/pod/qdev/README.md` | 452 | Low | Detailed procedural guide with real commands -- mostly fine, minor cleanup |
| 6 | `lib/ops/README.md` | 218 | Medium | Good architecture content but some fabricated code examples, could be tighter |
| 7 | `src/README.md` | 651 | Critical | Massively inflated (651 lines), badge decorations, duplicates `src/dic/README.md` content extensively, marketing language throughout |
| 8 | `src/dic/README.md` | 946 | Critical | Massively inflated (946 lines), fabricated debug output (`--doctor`, `--diagnose`, `--debug-interactive`, `OPS_TELEMETRY`, `OPS_MEMORY`, `OPS_PROFILE` -- none of these exist), emoji markers |
| 9 | `val/README.md` | 144 | High | Emoji headings, hardcoded test counts likely stale, phase roadmap filler |
| 10 | `val/lib/integration/README.md` | 35 | Medium | Emoji headings, inflated language ("enterprise development workflows") |
| 11 | `utl/doc/README.md` | 476 | Critical | Massively inflated (476 lines), marketing language ("success stories", "60x faster"), emoji throughout, references nonexistent `.doc_config` |
| 12 | `doc/README.md` | 71 | Medium | Contains auto-generated hub section (preserve markers), stale tool references (`utl/doc-hub`, `utl/doc-func`) |
| 13 | `doc/iac/README.md` | 167 | High | References nonexistent paths, stale deployment commands (`cd src/set/pve && ./pve`), emoji headings, fabricated metrics |

### doc/ Content Files (9 files)

Note: `doc/adm/` and `doc/cli/` and `doc/dev/` no longer exist. All content files are now under `doc/man/`.

| # | File | Lines | Severity | Notes |
|---|------|-------|----------|-------|
| 14 | `doc/man/configuration.md` | 345 | Medium | Needs path and accuracy audit |
| 15 | `doc/man/security.md` | 217 | Medium | References `./tst/validate_system`, `./tst/test_environment` |
| 16 | `doc/man/initiation.md` | 388 | Medium | Needs path and accuracy audit |
| 17 | `doc/man/verbosity.md` | 571 | Medium | Needs path and accuracy audit |
| 18 | `doc/man/functions.md` | 331 | Low | Mostly auto-generated -- preserve markers, audit manual sections only |
| 19 | `doc/man/logging.md` | 554 | Medium | Needs accuracy audit |
| 20 | `doc/man/variables.md` | 246 | Low | Mostly auto-generated -- preserve markers, audit manual sections only |
| 21 | `doc/iac/deployment.md` | 645 | Medium | Needs path and accuracy audit |
| 22 | `doc/iac/environment.md` | 276 | Medium | References `./tst/validate_system` multiple times |

### doc/fix/ Files (formerly doc/issue/)

Note: The `doc/issue/` directory does not exist. Issue tracking has moved to `doc/fix/`. Only one of the three original issue files has a clear successor (`001-gpu-hook-trigger-bug.md` → `doc/fix/pve_gpu-hook-trigger-bug.md`). Issues 002 and 003 have no corresponding files in `doc/fix/`.

| # | File | Lines | Severity | Notes |
|---|------|-------|----------|-------|
| 23 | `doc/fix/pve_gpu-hook-trigger-bug.md` | ? | Low | Successor to `001-gpu-hook-trigger-bug.md` -- audit for accuracy only |

## Common Problems Across All Files

1. **Nonexistent paths**: `./tst/`, `./entry.sh`, `./val/validate_system`, `./utl/doc-stats`, `./utl/doc-func`, `./utl/doc-hub`, `cd src/set/pve && ./pve`
2. **Emoji section headings**: Every file except `cfg/log/README.md` and `lib/ops/README.md`
3. **Marketing filler**: "Core Value Proposition", "Success Stories", "Strategic Value", badges, superlatives
4. **Duplicated content**: `src/README.md` duplicates most of `src/dic/README.md`
5. **Fabricated features**: `src/dic/README.md` documents `--doctor`, `--diagnose`, `OPS_TELEMETRY`, `OPS_PROFILE`, `OPS_MEMORY` which do not exist in the actual code
6. **Stale metadata**: Hardcoded dates, test counts, function counts that will drift
7. **Phantom directories**: References to `../user/`, `doc/dev/architecture.md`, `doc/dev/testing.md`, `doc/standards.md`, `doc/metaprompt.md` -- none of these exist. Note also that `doc/adm/`, `doc/cli/`, `doc/dev/` no longer exist as directories; their content is in `doc/man/`.

## Implementation Plan

Work is organized into 8 phases. Each phase groups files that share context so the agent can verify accuracy without switching domains. Phases are ordered by severity and dependency (files that other files link to come first).

### Phase 1: doc/README.md (hub)

**Files**: `doc/README.md`
**Effort**: Small
**Constraint**: Contains auto-generated section from `hub` generator -- preserve the injection markers exactly.

Tasks:
- Remove emoji headings
- Fix stale tool references (`utl/doc-hub` -> `utl/doc/generators/hub`, `utl/doc-func` -> `utl/doc/generators/func`)
- Remove duplicate "Last Updated" / "Generated By" blocks (appears twice)
- Clean up the manual prose around the auto-generated index
- Verify all linked files actually exist

---

### Phase 2: doc/ subdirectory READMEs

**Files**: `doc/iac/README.md`
**Effort**: Medium

Note: `doc/adm/README.md`, `doc/cli/README.md`, and `doc/dev/README.md` no longer exist -- those subdirectories were removed. Only `doc/iac/README.md` remains as a subdirectory README under `doc/`.

Tasks:
- Remove emoji headings
- Replace all `./tst/` references with correct `./val/` paths
- Replace `./entry.sh` with `./go init` / `lab-on` (or `./go on`)
- Replace `./val/validate_system` with `./val/run_all_tests.sh`
- Replace `./tst/test_environment` with `./val/run_all_tests.sh`
- Replace `./utl/doc-stats` with `./utl/doc/generators/stats`
- Remove references to nonexistent files (`doc/dev/architecture.md`, `doc/dev/testing.md`, `../user/`, `doc/standards.md`)
- Remove marketing filler ("Target Audience" with emoji, inflated metrics)
- Keep file focused: brief description + index of contents in that directory

---

### Phase 3: doc/ content files

**Files**: `doc/man/configuration.md`, `doc/man/security.md`, `doc/man/initiation.md`, `doc/man/verbosity.md`, `doc/man/logging.md`, `doc/iac/deployment.md`, `doc/iac/environment.md`
**Effort**: Medium-Large

Tasks:
- Audit all paths and commands against actual codebase
- Fix `./tst/` references to `./val/`
- Fix deployment script paths (verify `src/set/h1`, `src/set/c1`, etc. are correct)
- Remove filler and marketing language
- Remove emoji
- Verify function names and module references are current
- Do NOT touch auto-generated sections in `doc/man/functions.md` and `doc/man/variables.md` (only audit the manual header/footer around the markers)

---

### Phase 4: src/dic/README.md

**Files**: `src/dic/README.md`
**Effort**: Large (946 -> target ~200 lines)

This is the most inflated file. Needs a ground-up rewrite.

Tasks:
- Read the actual `src/dic/ops` source code to verify what features really exist
- Remove all fabricated features (`--doctor`, `--diagnose`, `--debug-interactive`, `OPS_TELEMETRY`, `OPS_PROFILE`, `OPS_MEMORY`, `OPS_CACHE`, `--cache-clear`, `--cache-stats`, `--validate=strict`)
- Keep accurate content: three execution modes (hybrid, `-j`, `-x`), parameter resolution hierarchy, signature analysis, array processing, `OPS_DEBUG=1` tracing
- Remove emoji markers
- Remove "paradigm shift" marketing language
- Reduce from 946 lines to roughly 150-250 focused lines
- Ensure code examples use real function signatures from actual code

---

### Phase 5: src/README.md

**Files**: `src/README.md`
**Effort**: Large (651 -> target ~80-120 lines)

Tasks:
- Remove badge decorations
- Remove "Core Value Proposition" and all marketing framing
- Eliminate duplication with `src/dic/README.md` -- this file should be a brief overview pointing to the two subdirectories
- Document `dic/` and `set/` at summary level only (3-5 lines each + link to their own READMEs)
- The ASCII architecture diagram is reasonable but oversized -- simplify
- Fix any path references
- Remove "Strategic Value and Operational Benefits" section entirely

---

### Phase 6: bin/README.md, cfg/README.md, val/README.md

**Files**: `bin/README.md`, `cfg/README.md`, `val/README.md`
**Effort**: Medium

`bin/README.md` tasks:
- Remove emoji headings
- Fix `init` -> `ini` filename reference
- Remove bloated "Best Practices", "Security Considerations", "Monitoring and Debugging" filler
- Keep: what `ini` does, what `orc` does, the initialization flow, key env vars
- Target ~40-60 lines

`cfg/README.md` tasks:
- Remove emoji headings
- Remove reference to nonexistent `ans/` subdirectory
- Fix description of `core/` files (`ecc` name -- verify actual file)
- Keep: directory listing with one-line descriptions, environment hierarchy explanation
- Target ~40-60 lines

`val/README.md` tasks:
- Remove emoji headings
- Remove stale hardcoded test counts and phase roadmap
- Remove "Migration Strategy" filler
- Keep: how to run tests, directory structure, framework basics
- Target ~40-60 lines

---

### Phase 7: lib/ops/README.md, utl/doc/README.md, val/lib/integration/README.md

**Files**: `lib/ops/README.md`, `utl/doc/README.md`, `val/lib/integration/README.md`
**Effort**: Medium-Large

`lib/ops/README.md` tasks:
- Already decent -- light cleanup
- Verify code examples against actual function signatures
- Remove any inaccurate examples
- Target ~150-180 lines (currently 218)

`utl/doc/README.md` tasks:
- Ground-up rewrite (currently 476 lines of marketing)
- Remove "Success Stories", "Team Impact", performance metrics claims
- Remove emoji throughout
- Document what actually exists: `run_all_doc.sh`, `generators/`, `intelligence/`, `ai/`, `config/`
- Reference actual config file name (verify `config/settings` vs `.doc_config`)
- Target ~80-120 lines

`val/lib/integration/README.md` tasks:
- Light cleanup -- remove emoji, trim language
- Target ~25 lines

---

### Phase 8: cfg/log/README.md, cfg/pod/shus/README.md, cfg/pod/qdev/README.md

**Files**: `cfg/log/README.md`, `cfg/pod/shus/README.md`, `cfg/pod/qdev/README.md`
**Effort**: Small

These are operational runbooks with real commands. Minimal changes needed.

`cfg/log/README.md` tasks:
- Fix the `#` on line 2 (should be markdown heading or removed)
- Light prose cleanup
- Target ~60 lines

`cfg/pod/shus/README.md` tasks:
- No structural changes -- this is a working runbook
- Consider whether hardcoded passwords should be removed or noted as examples
- Target: keep as-is with minor formatting cleanup

`cfg/pod/qdev/README.md` tasks:
- No structural changes -- this is a working runbook
- Light formatting cleanup only
- Target: keep as-is

---

### Phase 9: doc/fix/ files (audit only)

**Files**: `doc/fix/pve_gpu-hook-trigger-bug.md`
**Effort**: Small

Note: `doc/issue/` does not exist. The original three issue files (`001-gpu-hook-trigger-bug.md`, `002-filepath-pve-legacy-reference.md`, `003-dic-injection-flag-failure.md`) have no direct successors except for `doc/fix/pve_gpu-hook-trigger-bug.md`. Confirm with the user whether issues 002 and 003 were intentionally dropped or need to be recreated under `doc/fix/`.

Tasks:
- Read `doc/fix/pve_gpu-hook-trigger-bug.md` and verify paths/function names are still accurate
- Fix any stale references
- No style rewrite needed -- this is a fix tracker

## Execution Notes

- Each phase can be assigned to an agent independently
- Phases 1-3 should run before 4-5 (doc/ hub and subdirs are link targets for src/ READMEs)
- Phase 4 should run before Phase 5 (src/README.md references src/dic/README.md)
- Phases 6-8 are independent of each other
- Phase 9 is independent
- Note: `doc/man/functions.md` and `doc/man/variables.md` contain auto-generated sections -- preserve markers during Phase 3

Agent instructions for each phase should include:
1. Read the target file(s) and all source code they reference
2. Verify every path, command, function name, and feature claim against actual code
3. Rewrite following the tone of the root `README.md` (no emoji, no marketing, technically precise)
4. Preserve any `<!-- AUTO-GENERATED SECTION -->` markers exactly
5. Run `./val/run_all_tests.sh --quick` after changes to confirm nothing broke
6. Show the before/after line count to confirm reduction

## Summary

| Phase | Files | Current Lines | Target Lines | Priority |
|-------|-------|---------------|--------------|----------|
| 1 | doc/README.md | 71 | ~40 | High |
| 2 | doc/iac/README.md | 167 | ~50 | High |
| 3 | doc/man/ content files (7) + doc/iac/ content (2) | ~3000 | ~2000 | Medium |
| 4 | src/dic/README.md | 946 | ~200 | Critical |
| 5 | src/README.md | 651 | ~100 | Critical |
| 6 | bin/ cfg/ val/ READMEs | 461 | ~160 | High |
| 7 | lib/ops/ utl/doc/ val/lib/integration/ READMEs | 729 | ~350 | Medium |
| 8 | cfg/log/ cfg/pod/ READMEs | 640 | ~620 | Low |
| 9 | doc/fix/ (audit) | ~? | ~same | Low |
| **Total** | **23 files** | **~6700+** | **~3500** | |
