# Dashboard verification checkpoint — 2026-10-04

This is a verified testing checkpoint, not a declaration that every feature is
production-ready. Mobile frontend review is delegated separately by the user.

## Completed in this checkpoint

- Super-admin home Add Lounge now navigates to the actual wired provisioning
  flow. Removed the unused dialog with no save callback and a shared default
  password. A GoRouter widget regression verifies navigation.
- Practical email validation accepts long TLDs and plus addressing and rejects
  malformed hostnames/local parts.
- Onboarding location supports manual coordinates when GPS is denied, restores
  the saved venue coordinates without replacing them with current-device GPS,
  rejects nonfinite/out-of-range values and clears invalid saved coordinates.
  Manual edits take precedence over late GPS responses; leaving the step is
  safe. All location text is translated in Arabic/English.
- Offline cashier has a route, encrypted Hive journal, stable GetStorage device
  ID, existing secure-key storage, fixed-duration reservations, start/end,
  catalog sales and integer-cent cash collection. Arabic/Persian cash digits
  and decimal separator are supported. Writer permissions remain server-owned.
- Writer heartbeat survives route changes. Auth request guards drain replayed
  historical auth events, detect real session changes and bound uncertain HTTP
  requests with a timeout. Pending work is retained on failure.
- Cached server receipts overlay local booking totals only when local sequence
  matches and no newer pending command exists. Conflicts remain visible and
  block unsafe return to online mode.

## Actual verification

- Whole offline-allowed Flutter suite: **1047 passed**, concurrency 1. Live DB
  marketing tests remain excluded: `query_promotions_test.dart` and
  `live_realtime_rls_security_test.dart` (tag `live`).
- Final whole-project analyze: no errors/warnings; 52 existing info diagnostics.
  Focused onboarding analyze also passed. Verification output is retained
  outside Git in the task workspace.
- Four location regression tests passed, included in the 1047 total.
- Full formatter check is not clean: 353 baseline files would be reformatted.
  `--output=none` did not modify them. Changed files are formatted; unrelated
  files are preserved.
- Final production JavaScript release build succeeded (129.8 seconds). Existing
  Wasm dependency warnings do not mean the JavaScript build failed.
- Local browser/native PostgreSQL integration: prepared offline writer,
  disconnected browser, created EGP100 reservation, started it, added EGP15 sale,
  collected EGP30 and ended it. Five pending commands persisted across reload;
  no server operation existed before sync. After sync: five receipts, one
  booking, one cash receipt; EGP115 total, EGP30 paid, EGP85 remaining. Repeated
  sync did not duplicate operations. Confirmed online bootstrap disabled local
  write controls and heartbeat continued. This used synthetic local DB data,
  not live financial records.
- Arabic Tajawal browser captures at widths 360/600/768/1024/1440 are in the task
  workspace. They precede the final responsive card-column refinement; do not
  represent them as screenshots of that final refinement.
- Live synthetic provisioning verified owner login and onboarding entry, pending
  inactive closed venue. Both fixture account and venue were removed with exact
  identity checks. No fake identity document was submitted for approval.

## Remaining production gates

1. Automatic online-to-offline takeover after an unplanned disconnection is not
   complete. Successful explicit preparation must not be confused with automatic
   cutover. Never silently flip cached writer authority after uncertain requests.
2. Manager reconciliation needs a scoped, auditable server contract and complete
   UI. Current conflicts are preserved with localized review guidance; deleting
   an outbox or rewriting a rejected receipt is not a valid resolution.
3. Complete real-browser KYC upload/submission/accept/reject and all-role acceptance
   testing. Account access correction verifies onboarding entry, not that flow.
4. Open-ended sessions, advanced pricing and starting a new offline shift are
   outside the verified fixed-session offline workspace. Multi-device LAN is a
   future optional feature, as agreed by the user.
5. Security advisor baseline findings, final CI and the separate Mobile frontend
   review still require explicit assessment before a production sign-off.

No generated plugin files or `test_cache_box.bak` were included. Original
checkouts were not changed; no force push/reset/main update was used.
