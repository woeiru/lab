# Lib Architecture Review Evidence

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 10:47
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-plan.md, wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, doc/ref/functions.md, doc/ref/module-dependencies.md, doc/ref/reverse-dependecies.md, doc/ref/scope-integrity.md, doc/ref/error-handling.md, doc/ref/test-coverage.md, doc/ref/variables.md, doc/ref/stats/actual.md

## Triage Decision

- Why now: The architecture review output is needed to prioritize `lib/` refactoring and stabilization work.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: The review method and output format directly shape the next engineering decisions and execution sequence.

## Evidence Matrix

1. Function inventory (`doc/ref/functions.md`)
   - Strength: clear three-layer structure (`core`, `gen`, `ops`) with distinct module groups.
   - Risk: `ops` dominates scale (162/345 functions, about 47%) and size footprint (13691/18799, about 73%).
2. Direct dependencies (`doc/ref/module-dependencies.md`)
   - Strength: `core` modules are mostly dependency-light and host-command-light.
   - Risk: host command breadth is concentrated in runtime modules (`ops/ssh`, `ops/usr`, `ops/sto`, `ops/sys`) and `ops/pve` shows cross-layer import pressure.
3. Reverse dependencies (`doc/ref/reverse-dependecies.md`)
   - Strength: shared helper surface is consistent and discoverable.
   - Risk: `gen/aux` is a high fan-in hub (2816 aggregate calls), increasing blast radius for helper changes.
4. Scope integrity (`doc/ref/scope-integrity.md`)
   - Strength: many modules keep explicit env constants and readonly declarations.
   - Risk: findings show concentrated mutation/leak hotspots (123 global-mutated, 154 local-leak entries across `lib/*`, with highest concentration in `gen/ana` and selected `ops/*`).
5. Error handling (`doc/ref/error-handling.md`)
   - Strength: broad use of explicit return paths and standardized helper-based error reporting.
   - Risk: large error-path volume in a few ops modules signals complexity and maintenance burden concentration.
6. Test mapping (`doc/ref/test-coverage.md`)
   - Strength: most `lib/*` modules are mapped to concrete test scripts, with high counts in `ops/dev` and `gen/ana`.
   - Risk: mapped coverage does not equal confidence in this snapshot because status remains unknown.
7. Variable usage (`doc/ref/variables.md`)
   - Strength: global anchors like `LAB_DIR` and logging/temp paths are reused consistently.
   - Risk: high usage of environment-derived defaults implies stronger coupling between ops behavior and config shape.

## Traceability Notes

1. Complexity and quality-gate context is corroborated by `doc/ref/stats/actual.md`.
2. Coupling and dependency interpretation relies on `doc/ref/reverse-dependecies.md` and `doc/ref/module-dependencies.md` together.
3. Risk concentration statements are based on counts and module rankings from generated reference tables, not implementation deep dives.

## Open Questions

1. Should `gen/aux` be split into stable API vs internal helper tiers to reduce global fan-in risk?
2. Should `ops` modules with highest host-command breadth get explicit boundary wrappers for external command calls?
3. What minimum coverage/status gate should block architecture-sensitive refactors in high-risk modules?
