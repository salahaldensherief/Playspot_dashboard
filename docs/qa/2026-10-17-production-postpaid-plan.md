# Production postpaid rollout plan — not executed

## Scope and prerequisites

Production project `tgpdexoitemmpruepgyt` remains unchanged. Do not replay the
Mobile migration directory or deploy this by pointing a demo script at production.
The user requested a separate plan, not production execution.

1. Verify current remote Mobile/Dashboard dev heads and the exact deployed app
   versions. Audit the actual production function definitions, grants, triggers,
   migration ledger and connected services read-only. Compare them with the
   reviewed canonical cash-start source; abort on unreviewed drift.
2. Resolve accounting blockers in isolated tests before recommending release:
   partial deposits must collect only the real remaining amount, already-paid
   extensions/orders must not infer money received, and the historical EGP130
   canteen/shift difference needs an evidenced explanation. The successful local
   50→75→105 no-deposit scenario does not certify these cases.
3. Verify server-authoritative collected/due read contracts for the actual UI;
   never replace “Not confirmed” with guessed balances. Check settlement after
   completion through the real Dashboard, and customer history/reviews through
   Mobile. Add missing server planned-time enforcement with approved business
   rules; the current Dashboard clock gate is not RPC authorization.
4. Rehearse cash/noncash/refund, permission/tenant boundaries, closed/missing
   shifts, room conflicts, repeated/concurrent start, extensions, canteen totals,
   session close and idempotent settlement in the owned sandbox. Include online
   and offline authority paths without weakening writer guards.
5. Complete real-app visual/accessibility checks in Arabic/English at desktop and
   narrow widths. Verify local/hosted endpoint and public-key pairing, Auth/FCM/
   location/analytics effects and client build configuration independently.

## Controlled production execution, only after separate authorization

6. Prepare a precise two-function migration adapted only to verified production
   drift, with narrow execute grants preserved, precondition hashes, lock timeout
   and statement timeout. Capture previous definitions/ACLs and confirm an actual
   backup/restore procedure. Document the deployment and app-version sequence.
7. Schedule a quiet window with the venue operator. Review open sessions, unpaid
   balances and writer authority read-only; do not silently release/acquire writers
   or edit accounting rows. Obtain authorization for the named project and exact
   reviewed deployment as the last execution gate.
8. Apply only the reviewed migration through tracked deployment tooling. Verify
   definitions/grants and migration ledger, then observe approved real operator
   actions. Do not manufacture a financial transaction as a smoke test.
9. Monitor permission/shift/room failures and reconciliation. If rollback is
   required, first inspect sessions created under postpaid rules: restoring old
   functions alone may strand unpaid bookings. Agree on a safe drain/rollback
   plan; never rewrite receipts or balances to make checks pass.

Completion means evidence from the deployed applications and backend, not merely
green tests, a successful migration response or a polished demo recording.
