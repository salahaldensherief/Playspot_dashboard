# Booking scenario review — 12 October 2026

Reproduced failures: failed approval restored an older unpaid list over a newer authoritative paid update; a late failure restored bookings from a previously selected branch; repeated taps dispatched the same mutation concurrently; voucher validation emitted after disposal.

Booking operations now leave authoritative booking and payment rows intact while the server commits. A per-booking mutation guard prevents concurrent repeats, and branch scope prevents late errors from another branch affecting the current view. Pagination ignores superseded responses. Voucher validation ignores disposed/outdated results. Cash is never displayed as paid before an authoritative update. Room swaps use the same guarded action path and cannot restore stale whole-list snapshots.

Regression tests cover these failures, page ordering and pending cash status. Existing UI layout, colors, labels and responsive changes from dev are preserved. AGENTS.md governs the focused fixes; no schema or monetary contract changed. Catalogue archive still requires the canonical Mobile migration before Dashboard deployment.

Whole-project analysis, tests and build results are recorded in the task status. Remaining legacy informational lint/format debt is reported explicitly rather than treating focused repairs as full compliance certification.
