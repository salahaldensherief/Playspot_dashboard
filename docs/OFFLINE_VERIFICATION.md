# Offline verification

2026-09-30, Flutter 3.44.1 / Dart 3.12.1: 150 offline tests passed after cashier and permissions changes.

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

Cashier renders at 360, 600, 768, 1024 and 1440 viewports, Arabic/English, text scales 1.0 and 1.6. At viewport 600 with 16 px margins, the available 568 px uses the narrow layout. Modal details are captured through the Navigator. These are production widgets with offline fixtures, not a complete logged-in end-to-end run.

100 input sessions over ten simulated one-second ticks: workspace and details builds remained zero; 70 clock leaf builds. Timings are Windows debug widget-test host measurements, not phone GPU/frame performance.

Booking currently has no server collected/due amount fields: these remain explicitly unavailable. Open-ended total remains provisional until the server finalizes. This does not verify deployed contracts or provide operational offline booking/synchronization.
