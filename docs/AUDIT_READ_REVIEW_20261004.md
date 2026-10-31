# Dashboard audit verification — 2026-10-04

The general audit page now uses the scoped `get_audit_logs` RPC deployed from the canonical Mobile backend repository. Missing-service and authorization failures no longer turn into false empty lists or header-only CSV exports. All five recorded event sources use stable prefixed IDs and time/ID cursors. Booking timelines include cancellation events and linked room events.

The owner menu/page follows `audit.view`; a revoked owner grant is not bypassed by the owner role. Super administrators explicitly request global scope even if stale account data contains a lounge ID. Scope/filter refresh, disposal and late pagination/export replies are guarded. Returning a filter to All clears its previous value, date ranges include the final day's events, and payout/tournament filters are available.

Known event actions and entity types are translated across table/mobile/timeline views; system actors use the existing Arabic/English label. Unknown event codes remain visible with a translated wrapper so the UI does not fabricate an event meaning. Actor names, entered reasons and technical event IDs remain recorded data. CSV is deliberately machine-oriented with stable English column headings and original action codes.

Verification:
- Full offline suite: 942 passed, `flutter test --no-pub --exclude-tags live --concurrency=2` (71s). Live-tagged tests remain excluded locally. CI runs the repository's existing workflow separately.
- Scoped audit suite: 33 passed, including actual widget interactions for All-filter clearing, super-admin stale lounge scope, revoked owner permissions, CSV batches beyond 5,000, failure propagation, invalid event parsing and five async race/disposal regressions.
- Release web build succeeded (71.3s). Analyzer/formatter results are recorded in the task workspace logs; baseline whole-project formatting differences are not mass-reformatted.
- Native backend suite: 18 checks passed in an isolated PostgreSQL 17 fixture with rollback; see the canonical backend review for scope and limitations.
- Actual owner browser showed persisted audit events in English, then Arabic RTL at 1440 and 360. `get_audit_logs` network POSTs returned HTTP 200. No browser JS errors were reported. Screenshots in the task workspace: `work/audit-owner-live-en-settled.png`, `work/audit-owner-final-ar-1440.png`, `work/audit-owner-final-ar-360.png`.

This phase did not create bookings, collect payments, close hosted shifts, submit KYC decisions, mutate bans or alter original workspaces. Mobile emulator/UI verification has not begun. Audit source completeness, active-room/session server concurrency, isolated end-to-end KYC decisions, offline replay/conflicts and complete Mobile/runtime performance review remain separate outstanding work; these checks do not certify production readiness.

Final analyzer: 52 informational lints, zero warnings/errors (267.4s). Whole-project read-only format check: 1,020 files, 358 baseline differences; no baseline formatting rewrites were applied. Changed audit Dart files were formatted separately.
