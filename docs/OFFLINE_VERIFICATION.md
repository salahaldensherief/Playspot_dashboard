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
