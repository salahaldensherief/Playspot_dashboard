# Offline verification

2026-09-30, Flutter 3.44.1 / Dart 3.12.1: 123 tests passed.

Run from the dashboard root in PowerShell:

```powershell
$tests = @(rg --files test -g '*_test.dart' | Where-Object { $_ -notmatch '(live_realtime_rls_security|query_promotions)_test.dart$' })
flutter test --no-pub @tests
```

Excluded files (no live calls were made):

- `test/features/marketing/live_realtime_rls_security_test.dart` invokes a real promotion broadcast RPC.
- `test/features/marketing/query_promotions_test.dart` queries real promotions and lounge records.

The open-time policy test checks the RPC name independently of source whitespace,
then captures requests with an HTTP mock. It verifies all five parameter names and
values, payment-only table writes, and no table write after RPC denial. This tests
the client contract, not deployed RPC availability or authorization.

Generated plugin registrants changed only in line endings after Windows pub get.
They are environment artifacts and excluded from UI commits. Mobile
`test_cache_box.bak` changed from empty to `{}` during tests; it is a test cache,
not application source, and is also excluded. Lockfiles were unchanged.
