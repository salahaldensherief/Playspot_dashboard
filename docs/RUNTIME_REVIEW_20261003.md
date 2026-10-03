# Dashboard runtime review — 3 October 2026

## Completed and verified

- Existing Chrome session: super-admin login, KYC empty state (get_lounge_review_requests HTTP 200), lounge management list, and create-lounge required-field validation. No real owner account was created.
- Owner/manager login: active shift and seven-room occupancy visible; detailed-booking dialog displays actual 60/80 EGP hourly rates. No financial transaction or booking was submitted.
- Cashier login reproduced a route race: the pending screen persisted after the approved lounge arrived because the cashier personal setup flag was false. The guard now exits for approved staff without requiring owner onboarding; pending and inactive lounge gates remain enforced. Four regression cases passed.
- Management queries now include pending/suspended venues, count non-deleted rooms across API pages, use typed owner-ID filters, and propagate failed reads. Revenue/discovery RPCs no longer mask a failed management read. Six contract tests passed.
- Management displays room-based pricing instead of an invented zero-dollar lounge rate, uses approval/activity for status independently of online opening, and exposes the existing address field.
- Shift actions remain in the shared shell; duplicated page banners removed.
- Shared debug HTTP instrumentation records operation, correlation ID, HTTP status, safe error code, elapsed time and byte count. No request body, header, query value, credential or private storage path is logged. Six diagnostics tests passed. Realtime WebSocket and native plugin traffic are outside this HTTP instrumentation.
- Live update-user-location Edge Function version 3 deployed with verify_jwt=true. Geocoder failure no longer blocks valid-coordinate persistence; caller verified by Auth, writes use caller-scoped RLS, no client-supplied user ID is trusted. Nine Node tests passed (19 including existing owner provisioning).
- Authenticated live read confirmed 2 visible non-deleted lounges including 1 pending/inactive venue, canonical super-admin authority true, and invalid-coordinate request rejected HTTP 400. No migrations applied in this review.

## Verification evidence

- Flutter full suite: 805 passed, 2 live tests skipped.
- Flutter analyze: no errors or warnings; 44 informational lints before two new brace lints were corrected. Scoped analysis after changes: no issues.
- Changed Dart files formatting check passed; git diff --check passed.
- Screenshots and sanitized request metadata are in the task workspace outputs directory; originals were not modified.
- Existing browser renderer stopped responding after its original dev server stopped. New worktree server uses the same port; new tab is used for post-fix checks. Successful old screenshots do not by themselves prove new UI verification.

## Post-fix runtime checks

- Release Web build succeeded in 153.1 seconds. Same-port local preview recovered browser verification without running Mobile.
- Cashier reached lounge-admin/dashboard automatically with personal setup=false, approved venue and current shift displayed once. Direct super-admin/lounges navigation redirected back to lounge-admin/dashboard.
- Active-session read HTTP 400 reproduced as PGRST200 (no bookings→profiles relationship). Corrected select also removes nonexistent canteen_order_items.price and extras.unit_price, uses batched RLS-scoped profile enrichment, and preserves authorization errors instead of emitting a degraded fallback list. Four new contract tests passed; corrected authenticated live select returned HTTP 200. Full suite before these four additions: 805 passed, 2 skipped; changed-scope analysis passed.
- Dashboard CI at d1844f1 and Mobile CI at f37c286 completed successfully.

## Remaining review

- Remaining role-action flows and onboarding creation/approval against isolated records.
- Old-runtime location 502 and booking-read 400 causes fixed above. Session-transition 401 requests still require lifecycle review.
- Owner phone and lounge phone are separate form inputs but provisioning contract still conflates them; requires coordinated API/server follow-up.
- Full widget-by-widget localization and responsive visual review still ongoing.
- Mobile navigation/runtime review intentionally paused while Dashboard is running; mobile and dashboard are not run together.
- Offline cashier foundations are not proof of complete offline operations/synchronization. No production-readiness certification from these tests.

## Responsive typography and locale review

- Actual management screenshots exposed a 360px title/action overflow, Arabic glyphs missing in explicit Orbitron headings, and labels remaining in the previous language until navigation. Adaptive page headers, explicit Tajawal fallback, and inherited locale dependencies address those causes without requiring a Cubit emission.
- Room counts, owner email and mobile management details no longer shrink below 14px. Status badges use 14px; the mobile card title wraps within its available space and details wrap together. Sidebar navigation and role labels retain readable sizes across breakpoints.
- Removed the breakpoint-dependent ScreenUtilInit key: changing width must not remount the router subtree. Actual resize checks retained the authenticated management route across 360, 600, 768, 1024 and 1440px.
- Twenty Arabic/English management layout cases passed at those five widths and text scales 1.0/1.6. A separate locale-switch regression verifies header, table pricing and top-bar role labels change immediately with no Cubit emission. Existing platform-scope regression remains enforced; locale observation does not require a localization provider for the super-admin empty branch switcher.
- Final full suite: 830 passed, 2 live tests skipped. Final analyze: no errors or warnings, 44 informational lints. Release Web build succeeded in 73.8 seconds; changed-file formatting and git diff checks passed.
- Actual browser screenshots: dashboard-management-final-ar-{360,600,768,1024,1440}.png and dashboard-role-locale-switch-ar.png in the task outputs directory. A live language toggle updated the page, table and role label without navigation. Text scaling was verified by widget tests, not by an OS accessibility-setting test.
- This verification covers management and shared typography/locale fixes; it does not certify every feature translation, offline cashier synchronization, or production readiness. No real account, booking or financial transaction was created during these browser checks.
