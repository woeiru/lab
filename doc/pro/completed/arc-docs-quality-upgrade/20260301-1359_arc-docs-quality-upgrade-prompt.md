# Arc Docs Quality Upgrade Prompt

- Status: completed
- Owner: es
- Started: n/a
- Updated: 2026-03-01
- Links: doc/arc/README.md, doc/arc/01-bootstrap-and-orchestration.md, doc/arc/00-architecture-overview.md, doc/arc/02-core-and-gen.md, doc/arc/03-operational-modules.md, doc/arc/04-dependency-injection.md, doc/arc/05-deployment-and-config.md, doc/arc/06-testing-and-validation.md, doc/arc/07-logging-and-error-handling.md

## Goal

Provide a reusable prompt to upgrade the remaining architecture docs to the same quality bar as the refined bootstrap doc.

## Prompt

```text
You are working in /home/es/lab.

Task:
Upgrade the remaining architecture docs under doc/arc/ to match the quality standard defined in doc/arc/README.md and the depth/style of doc/arc/01-bootstrap-and-orchestration.md.

Scope:
- doc/arc/02-core-and-gen.md
- doc/arc/03-operational-modules.md
- doc/arc/04-dependency-injection.md
- doc/arc/05-deployment-and-config.md
- doc/arc/06-testing-and-validation.md
- doc/arc/07-logging-and-error-handling.md
- Update doc/arc/00-architecture-overview.md only if cross-links, sequencing, or framing must change for consistency.

Requirements:
1) Accuracy first: trace claims to current code (no aspirational behavior).
2) For each doc, include:
   - clear execution flow and responsibilities
   - concrete code-traceable references (file/function names)
   - one detailed Mermaid diagram (function-level where applicable)
   - one conceptual quick-view Mermaid diagram
   - operational constraints, side effects, and coupling notes
   - explicit maintenance note describing what code changes should trigger doc updates
3) Keep terminology consistent across all arc docs.
4) Preserve existing architecture patterns; improve clarity and traceability.
5) Do not change runtime code unless strictly needed to fix documentation contradictions (if found, report separately instead).

Process:
- Read doc/arc/README.md first and treat it as the quality contract.
- Use doc/arc/01-bootstrap-and-orchestration.md as style and depth benchmark.
- Validate each statement against source files (go, bin/, lib/, src/, val/ as relevant).
- Ensure cross-doc links are coherent and non-duplicative.

Deliverables:
- Updated arc docs listed in scope.
- Brief change report with:
  - per-file summary of what was improved
  - any unresolved ambiguities or suspected code/doc mismatches
  - suggested next maintenance actions

Optional finish step:
- If requested, stage and commit docs with a message similar to:
  docs: upgrade remaining arc docs to quality standard
```
