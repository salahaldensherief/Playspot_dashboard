# Cash play before collection

Baseline: `911752c82ddb9a99a0a4ac8f21fbe522c823ba65`.

Approved upcoming **cash** bookings can offer Start independently of collection in the booking card, cashier tile, station controls and details panel. Start time, session-control permission and server success checks remain. Cash collection is still available as a separate optional action. Unverified prepaid transfers, unknown unpaid methods, refunded and terminal bookings do not acquire the cash exception.

The immediate-start manual-booking form no longer labels its request as paid. Its explanatory text explicitly distinguishes starting play from receiving money. The backend must also install the companion Mobile candidate `20261016211005_cash_session_start_before_collection.sql`; changing button visibility alone is insufficient.

Validation: two cash visibility failures reproduced before the fix; cash/transfer visibility and eligibility regressions pass. The booking/permission subset passed **114 tests**; focused four-surface/start-failure coverage passed **10 tests**. Existing optional collection behavior was retained after its regression test exposed an initial omission. Analyzer passed; subsequent copy/eligibility edits are covered by focused tests. Real isolated local Auth/PostgREST completed the six checks below. Real browser verification is recorded separately when complete.

Local synthetic scenario: play EGP50 → approved 30-minute extension EGP25 → two drinks EGP30 → final EGP105. Before explicit collection: zero payment and cash-ledger entries. Completion retains EGP105 due. Explicit collection records EGP105 once; repetition creates no extra ledger entry.

This is source delivery, not a hosted database rollout. Production and cinematic Demo were not changed. Do not replay financial migrations blindly. Review prerequisite/deployed function definitions and authorize deployment separately. Open-time sessions and policies for prepaid bookings remain distinct; this does not make every payment method postpaid.
