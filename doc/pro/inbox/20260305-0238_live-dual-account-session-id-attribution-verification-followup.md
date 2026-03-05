# Live Dual-Account Session-ID Attribution Verification Follow-up

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-05 03:35
- Links: doc/pro/completed/20260305-0335_session-user-attribution-mismatch-issue/20260305-0211_session-user-attribution-mismatch-issue.md

## Goal

Capture live dual-account evidence that emitted attribution events include non-empty `session_id` and that `dev_osv` attributes each session to the correct authenticated account.

## Context

- The attribution resolver and emitters now support session-bound precedence and optional `session_id` metadata.
- Controlled replay against an in-memory clone of the real DB confirmed expected behavior when a session-bound event exists.
- Remaining gap is real runtime evidence from controlled sign-ins/events across two OpenAI accounts.

## Scope

In scope:

1. Generate two controlled sessions under different accounts with runtime attribution metadata including `OPENCODE_ATTR_SESSION_ID`.
2. Capture strict and best-effort `dev_osv` output after each run.
3. Verify per-session `USER` values align with authenticated account identity and attached event metadata.

Out of scope:

1. Additional resolver/DB schema changes.
2. Historical backfill beyond the controlled evidence window.

## Next Step

Run controlled dual-account sign-ins, emit session-bound runtime events, and archive resulting `dev_osv` evidence for closure.
