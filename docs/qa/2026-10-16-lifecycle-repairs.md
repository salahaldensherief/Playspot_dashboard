# Tournament UI repairs and Arabic copy — 16 October 2026

Source baseline: `571c50d040e9c1e7b10d24337d8e03f655a2404e`.

- Load selected participants/matches automatically; refresh reads rather than drawing again. Successful match actions reload authoritative tournament state without requesting geolocation.
- Preserve backend payment/registration/match states, score/order/proof fields and separate bronze matches. Paid entrants do not get a duplicate cash collection action.
- Obtain participant display names from the narrowly scoped `get_tournament_participant_names(uuid)` RPC, not unrelated private profiles. This new backend contract is in the companion Mobile migration repository and must be reviewed/deployed before releasing these client changes to hosted backends.
- Propagate rejected draws and failed reads/realtime requests. Independent dispute subscribers cannot cancel each other's channels; resolved/deleted disputes trigger correct reads with default replica identity.
- Count active seats instead of waitlisted/terminal records. Completion, awarding and draw refresh have separate callbacks. Completed/drawn participant withdrawal is hidden.
- Card/selector actions follow backend phase constraints: no advanced-phase editing, locked prize edits or completed/cancelled cancellation; deletion labels apply to drafts, while other eligible phases use cancellation. The backend still checks historical participant records and remains authoritative.
- Selector actions wrap responsively and use bundled Arabic font fallback. Arabic UI copy uses Modern Standard Arabic; permission display labels change without altering permission IDs or access rules.
- Windows CRLF-safe Edge test import stripping and SQL guard fixture comparisons; no SQL guard bypass.

## Verification and limits

Latest complete Flutter suite after Arabic/phase-control changes: **1243 passed, 2 skipped**. Tournament subset: **81 passed** after ten card regression failures were reproduced/fixed. Edge authorization/failure contracts: **85 passed**. Python script tests: **5 passed**. Analyzer clean; formatting clean. Contained JavaScript web release builds succeeded.

Actual local owner UI verified overview, tournament list, active-seat counts, paid roster, real final/bronze scores, Arabic title rendering and completed withdrawal guard. New card phase guards were also verified in the real browser without executing cancellation/deletion. A later overview reload displayed a partial-data warning; its individual failed reads remain to diagnose, so this is not a clean whole-overview certification. Post-action authoritative refresh has regression coverage but was not re-executed through a new transactional UI action.

All business integration tests use newly generated synthetic records in a separate contained LOCAL stack. Hosted production/cinematic Demo, Auth, financial records and Storage were preserved. No hosted SQL deployment occurred. Backend migration candidates and EGP130 reconciliation prerequisite review remain separate from client source delivery. External integrations and all non-tournament real-UI lifecycles remain open. Credentials/logs/screenshots stay outside Git.
