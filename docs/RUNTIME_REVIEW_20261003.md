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
- Owner contact separation is verified below; isolated live creation/approval still remains.
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

## Reactive lounge control

- Owner login exposed another lifecycle defect: the open/closed control checked a GetIt-backed entity permission before grants arrived and never observed their later arrival. The control now watches the provided PermissionsCubit and checks role and authenticated user ID against its current authoritative grant.
- Three regression cases (owner, manager, cashier) cover delayed grant arrival, revocation, and another actor's grants while the authentication Cubit stays unchanged. Permission and platform-scope suites: 73 passed; changed-scope analysis had no issues. Release Web build succeeded in 75.2 seconds.
- Actual owner screenshot dashboard-owner-status-reactive-settled.png shows the control arriving after permissions load, one active-shift banner, and seven available rooms. The control was not toggled; no venue availability or financial operation was changed by the test.
- GitHub CI for the typography commit 0e8b08b completed successfully.

## Dropdown Arabic rendering

- Runtime booking-filter labels rendered as missing-glyph boxes. DropdownButtonFormField was given an isolated TextStyle that discarded the theme font. CustomDropdown now derives its style from the theme body text, preserving Tajawal and a 14px size for both the selection and popup.
- Two regressions verify the inherited Arabic font and readable size at text scales 1.0/1.6, including opening the popup. Widget/shift/platform suites: 106 passed; changed-scope analysis had no issues. Release Web build succeeded in 76.4 seconds.
- Actual screenshot dashboard-booking-filters-ar-font-fixed.png shows Arabic room/status/date labels rendered correctly. Shift-summary Orbitron headings now include the same explicit Tajawal fallback as other headings.

## Owner and venue contacts

- The form's ownerPhone previously stopped at the Cubit, while the server stored the venue phone on the owner profile. The application contract now forwards distinct owner_phone and phone values. The versioned service-only finalizer stores owner phone on profiles.phone, venue phone on lounges.contact_phone, and the venue address on lounges.address plus the existing location field.
- Native PostgreSQL 17.11 fixture: 18 new-version checks and 14 existing-version checks passed, including disabled/banned administrator denial, no staff reassignment, service-only execution, idempotent retries, and old-caller replay compatibility. No existing application rows are rewritten.
- Edge handler: 11 tests passed; Flutter request-contract and Cubit forwarding: 6 passed. Scoped feature analysis reported five existing informational brace lints and no errors/warnings.
- Applied only 20261003185714_owner_lounge_contact_fields_v2.sql to the live project, then deployed create-lounge-owner version 2 with verify_jwt=true. Live catalog confirms empty search_path, client/anonymous EXECUTE denied, and service_role EXECUTE granted. An authenticated cashier request was denied HTTP 403/42501; the Edge create endpoint rejected the cashier HTTP 403 before account creation. No live owner account was created by these probes.
- Dashboard CI at 5eca80b succeeded. Actual cashier login retained cashier role; direct platform URL navigation redirected to the lounge dashboard. Existing owner shift was not closed and venue availability was not toggled.

## Room management access and Arabic data

- Room-view permission was incorrectly reused for add/edit/delete controls. The header and table now observe PermissionsCubit and require rooms_manage for mutations. Viewing the room list still uses the existing read gate.
- Room table headers, hourly prices, availability and status labels now use translations, and the primary room name follows the active locale. Price text and secondary data retain readable sizes; wrapping handles mobile text scaling. Occupancy ratios explicitly use left-to-right order, and the subtitle uses words rather than a reversible slash expression.
- The mobile table's old walk-in/end button changed room status without creating or finishing a booking. It now navigates to Live Operations, where actual booking/session commands are available. The table's availability switch is disabled for occupied rooms. This UI change does not claim to fix every server-side room-state transition.
- Eight Arabic/English access/layout cases passed at widths 360/1440 and text scale 1.6, covering read-only grants, management grants, and disabled occupied-room switches. Full suite before the final font/wrapping adjustments: 845 passed, 2 live tests skipped; the eight affected cases passed again after those adjustments. Changed-scope analysis has no issues.
- Real cashier room-list screenshot dashboard-cashier-rooms-readonly-settled.png confirms no add/edit/delete/toggle controls; the initial deep-link was redirected while grants loaded, then sidebar navigation succeeded. This exposes a remaining permission-loading deep-link race requiring separate review.
- Runtime also exposed UUIDs displayed as room space types: the client used slug options while the database references space_types UUIDs. The coordinated correction is described below; no catalog IDs or existing room types were rewritten.
- Dev CI succeeded at Dashboard 685ee24 and b7a7bff, and Mobile f1e7055. The Mobile commit contains only the verified backend migration and fixture test; generated plugin/cache artifacts remain excluded.

## Room space-type contract

- Added a typed domain catalog, data model and repository read for space_types(id,name,label). Room reads include the actual FK join, and the model uses the canonical name for grouping while preserving the UUID for writes. Cache-only metadata stays out of database update payloads.
- The selector displays translated catalog labels and retains the existing selected UUID. Creating a room requires an explicit valid selection; failed catalog loading offers retry and cannot silently assign open_area or upload images before selection validation. Open-area specifications use the selected catalog category rather than comparing a UUID with a slug.
- Room filtering groups canonical and legacy catalog names; table cells no longer expose unidentified UUIDs. Existing catalog rows, including legacy duplicates, remain unchanged.
- A valid cached catalog supports offline reads. PostgreSQL authorization/schema failures remain failures, malformed caches are rejected, and a late catalog response does not emit after Cubit disposal.
- Six model/read/cache/lifecycle regressions and two Arabic/English selector regressions passed. The selection tests verify translated labels, unchanged initial UUID and the actual UUID returned by choosing another type.
- Full Flutter suite: 853 passed, 2 live tests skipped. Room feature and tests analysis: no issues. Authenticated live catalog and joined-room probes both returned HTTP 200; those probes did not mutate application data.
- Release Web build succeeded in 74.6 seconds. Actual screenshot dashboard-room-types-final-settled.png shows translated room-type badges with their colors and no management controls for the cashier. Rendering requires waiting for auth/permission/data initialization; early screenshots and URLs can reflect a transitional state.
