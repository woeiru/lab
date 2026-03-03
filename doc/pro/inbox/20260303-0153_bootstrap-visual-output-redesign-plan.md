# Bootstrap Visual Output Redesign

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-03
- Links: bin/ini, bin/orc, lib/core/lo1, lib/core/tme, lib/core/err, lib/core/col, cfg/core/ric

## Goal

Redesign the bootstrap terminal output to be visually professional, minimal,
and efficient — replacing the current verbose, multi-producer, inconsistently
styled output with a compact, state-of-the-art display that communicates
system readiness in as few lines as possible.

## Context

The current bootstrap produces output from five independent producers, each
with its own formatting rules, color systems, and stream choices:

| Producer | Format | Color | Stream |
|---|---|---|---|
| `ini_log()` | `└─ {message} [{time}]` | None | stderr |
| `ver_log()` | `    └─ {message} [{time}]` | Hardcoded orange 208 | stderr |
| `lo1_log()` normal | `{indent}{color} {time} {message}` | Viridis depth palette | stderr |
| `lo1_log()` special | ` {color}━ {message}` | Viridis depth palette | stdout |
| `err_print_report()` | ` ━ {header}` / `   └─ {detail}` | None | stderr |
| `tme_print_timing_report()` | Tree with `└─` and `[✓]` | TME rainbow palette | stdout (off by default) |
| Opening/closing banners | ` ─────────────── ` / ` ━ Initialization completed in Xms` | None | stderr |

Problems with the current output:

1. **Verbose by default.** A clean boot emits ~30-50 lines of tree-formatted
   log messages that scroll past faster than anyone can read. Every module
   load, every stub registration, every component gets its own line.
2. **Inconsistent styling.** Three separate color palettes (Viridis, TME
   rainbow, hardcoded orange), two stream targets (stdout/stderr mixed within
   the same logical phase), and three prefix styles (`└─`, `━`, plain).
3. **No visual hierarchy.** Phase transitions look identical to detail lines.
   The user cannot quickly distinguish "system is ready" from "loading module
   gpu".
4. **Redundant information.** Messages like "Starting X" followed by
   "X completed" for trivial sub-second operations add noise, not signal.
5. **Error report always shown.** The clean-boot path prints a full
   "0 errors, 0 warnings" report block — six lines of output to say nothing
   happened.

## Scope

In scope:

1. Redesign `ini_log()` terminal output format (the `echo "└─ ..."` path).
2. Redesign `lo1_log()` terminal output format during bootstrap phase.
3. Redesign `err_print_report()` to suppress on zero issues or compact to
   one line.
4. Redesign opening/closing banners in `bin/ini`.
5. Unify stream usage (pick stderr consistently for all bootstrap output).
6. Integrate with existing verbosity controls (`MASTER_TERMINAL_VERBOSITY`,
   per-producer switches).
7. Preserve all file-based logging unchanged (ini.log, err.log, tme.log).

Out of scope:

- Changing the timing report (`tme_print_timing_report`) — already off by
  default, and useful as-is when explicitly enabled.
- Changing runtime `lo1_log` behavior outside bootstrap context.
- Changing the sourcing chain, module loading logic, or initialization order.
- Modifying `cfg/core/ric` verbosity variable definitions.

## Risks

- **Interactive shell safety.** All output touches stderr in a sourced
  context. Formatting changes must not break pipe chains or terminal state.
- **Backward compatibility.** Users or scripts may parse current output
  (unlikely but possible). The verbosity kill switches provide mitigation.
- **Color terminal support.** Any new color usage must degrade gracefully
  on dumb terminals (respect `NO_COLOR`, `TERM=dumb`).
- **Performance regression.** The bootstrap is performance-sensitive
  (sub-500ms target). New formatting must not add measurable overhead.
- **Coordination with theme pipeline.** The OpenCode terminal color palette
  integration plan (20260301-1641) defines a semantic color system. This
  redesign should use hardcoded minimal colors now but be structured so
  semantic tokens can replace them later without another rewrite.

## Next Step

Design the target output mockup — define exactly what a successful cold boot
and a successful cached boot should look like on terminal (character by
character), then validate the design before touching code.
