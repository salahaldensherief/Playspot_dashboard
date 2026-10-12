# Session-start cycle review — 12 October 2026

## Reproduced failures

- Approved unpaid booking: the cashier details collect action called an empty callback.
- Paid upcoming booking: the station drawer had no start action.
- Stale analytics rows overwrote fresher canonical booking rows, including the paid status that enables session start.
- Start readiness used a separate wall clock rather than the session clock. Start alerts were only checked on realtime events; truncating a negative time difference to whole minutes could alert before the start time.
- Failed booking actions hid loaded bookings and their controls. Start/payment dialogs closed before server confirmation.
- A malformed session-start response could acknowledge another booking as successful.

## Resulting behavior

Approved unpaid bookings lead to the existing payment flow. Paid upcoming bookings expose the existing start component in station controls, respecting the established 15-minute frontend readiness window. Fixed-duration sessions still require full payment and an open shift; open-time sessions keep their existing server policy. No booking is auto-started by a timer.

Canonical booking rows take precedence over supplementary analytics rows and are limited to the selected branch. Switching branches clears previous-scope rows; refreshing the same branch does not invalidate a pending command. A failed command keeps loaded bookings usable and shows the error.

Timers check start alerts and expired-session transitions from the latest loaded snapshot even without a new database event. Time parsing is shared between the booking entity and the start component, rejects malformed input, preserves seconds and understands timestamp input.

Payment/start dialogs stay open while requests are pending or fail. Session completion uses the existing authoritative completion command, including unpaid running sessions, and cancellation uses the existing confirmation component. Known shift/payment errors are localized in Arabic and English. Session-start acknowledgements must match both the requested booking ID and the running status.

## Verification and rollout

Regression tests reproduce the missing/ineffective controls, stale paid projection, readiness clock, early alert, hidden loaded data and invalid acknowledgement. Existing UI layout and style are retained; the missing start action uses existing components. Full Flutter, analyzer, format, Edge and web-build checks are required before dev merge. No Supabase schema or hosted data was changed for this repair. This is a verified repair of these scenarios, not a claim that every possible lifecycle path or legacy architecture issue has been eliminated.
