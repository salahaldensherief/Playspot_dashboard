# Offline verification

Default flutter test runs local unit/widget/contract tests only.
Live database tests are tagged live and skipped unless explicitly enabled with
--dart-define=PLAYSPOT_RUN_LIVE_TESTS=true. They are not part of offline validation.

Excluded live tests:
- test/features/marketing/live_realtime_rls_security_test.dart
- test/features/marketing/query_promotions_test.dart

Integration verification on 2026-10-01: 182 offline tests passed; analyze returned
22 informational lint findings, no errors or warnings. This does not prove full
backend integration or implementation of offline writes/synchronization.

Environment-generated plugin registrants, test_cache_box.bak and unused offline
package additions are excluded from this UI integration. Original worktree files
are preserved. Offline persistence dependencies require a separate working feature.

Offline-cashier branch verification after fixed-session reconciliation on
2026-10-01: 343 offline tests passed, including 157 offline-cashier tests. The same
two live tests remained skipped. Analyze returned 22 pre-existing infos, no errors
or warnings (exit 1 because informational lints remain). Formatter passed on all
changed Dart files. No new generated plugin or test_cache_box.bak changes were
included. This validates the persistence/parser/command foundation and synthetic
native RPC contracts; the real cashier UI still uses online repositories.

Permit/lifecycle verification completed across 2026-10-01/02: 432 offline tests
passed, including 246 offline-cashier cases; the same two live cases stayed skipped.
Analyze returned 21 pre-existing informational lints, no warnings/errors (exit 1
because infos remain). Formatter and diff whitespace checks passed.
No environment-generated plugin or test-cache changes were included.

The cashier widget fixture now injects a deterministic clock that also reaches
its mobile details sheet. Its upcoming session no longer becomes past at 23:30
on the developer's real clock. All 20 width/language/text-scale combinations and
the existing clock rebuild/conflict assertions passed. 28 PNGs were captured at
360/600/768/1024/1440 with Arabic/English, Tajawal and text scale 1.0/1.6. The
Windows debug widget measurement loaded 100 sessions for 10 simulated seconds:
zero workspace/details rebuilds, 70 clock-leaf rebuilds, 207066 host microseconds.
These are synthetic widget renders and host work, not real device frame timings
or production cashier end-to-end screenshots. Visual details-layout improvements
and real offline read/action integration remain separate work.

Responsive details verification on 2026-10-02: 455 offline tests passed, including
246 offline-cashier foundation cases. The two live tests remain skipped. Analyze
has 21 existing informational findings and no warnings/errors after fixing the
new guard's braces. No generated plugin files or test_cache_box.bak were changed.

The session workspace uses separate rail, split view, sheet, header, customer,
financial and activity components. Manage is reachable before scrolling at all
five widths with Arabic text scale 1.6. Facts use directional responsive columns.
Open-time elapsed duration no longer increases deadline urgency. Upcoming bookings
and requests are scoped to the current lounge/resource. Removing the owning
workspace closes its exact details route, without popping unrelated routes.

The layout/group/grid suites cover 46 cases. Twenty Arabic/English width and
text-scale combinations plus eight mobile sheets produce 28 PNGs under the task
outputs/cashier-details-20261002 directory. RTL/Tajawal and enlarged text were
visually inspected in final desktop and mobile captures.

The latest debug Windows widget measurement loads 100 sessions for 45 simulated
seconds, crossing three classification deadlines: zero workspace/details builds,
360 SessionLiveClock builds and 1,072,227 host microseconds. This is synthetic
widget work, not browser/device frame performance. Confirmed collected/due values
remain unavailable until the canonical backend read adapter is connected; the UI
does not invent them. Full offline UI operation and hosted integration remain
unfinished and the feature PR stays draft.

Auth storage/lifecycle verification on 2026-10-02: the full dashboard suite now
has 480 passing offline tests, including 248 offline-cashier cases and 23 new
secure-auth storage cases. Two live tests remain skipped; analyze has 21 existing
infos and no warnings/errors. Mobile's corresponding storage phase has 206
passing tests and 109 existing infos, with no errors/warnings.

Same-account SIGNED_IN now invalidates old HTTP requests and journal references,
while TOKEN_REFRESHED preserves the active identity. A regression exposed opening
a journal after awaiting an outdated closing future; opening now drains the
current closing chain before allocation. Saved records survive this transition.
Two real Android plugin probe processes passed; details/limits are documented in
SECURE_AUTH_STORAGE.md. No hosted SQL, live tests or dev/main merge was performed.
