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
