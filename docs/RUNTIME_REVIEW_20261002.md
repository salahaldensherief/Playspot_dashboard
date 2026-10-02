# Runtime and dashboard review — 2026-10-02

This review addresses the supplied October 2 dashboard logs and excessive layout
spacing. Source integration into dev is not hosted database deployment.

## Implemented behavior

- Policy repository returns domain entities rather than a covariant model list.
  Empty policy lookup uses an entity default. Editor drafts survive action state
  updates. Regression tests cover the reported firstWhere TypeError.
- Cashier text uses cashier.label, retaining the cashier translation namespace.
  Navigation and the reported runtime labels have Arabic and English entries.
- Shared avatars preserve identity placeholders when remote image decoding fails.
- Request and shift data sources propagate authorization errors instead of
  attempting weaker table fallbacks. Shift overview reads the canonical opened_at,
  expected_cash and digital_sales fields; unknown counts remain unknown. Errors
  never imply an inactive shift or an all-clear operations summary.
- Loyalty missions read loyalty_missions/reward_points. Referrals use actual
  referrer_id/referred_id/reward_claimed fields and an independent authorized
  profile lookup. Deleted synthetic statistics and customers. A failing section
  leaves other successful sections usable, with retry and honest unavailable UX.
- Lounge dashboard columns flow independently, with 16px gaps and compact ordering
  on narrow/large-text layouts. KPIs respond to available width. Room status uses
  server rooms rather than fabricated room names and cosmetic toggle switches.
  Revenue intelligence derives clearly labeled loaded, completed and paid booking
  facts; absent invoices never produce fabricated percentages or averages.
- Request subscriptions stop when the shell is disposed or the account changes.
  Lounge switches clear private data. Stale pages and attendance failures cannot
  restore another lounge's state. Watch callbacks and cancelled debounce timers
  ignore obsolete work. Four failures were reproduced on the previous source and
  passed after the change.
- Logout clears private UI immediately; asynchronous profile, lounge and GPS
  responses are tied to their original auth generation. Old location failures
  cannot log out a newer account. Successful retries clear the earlier error.
- Location invokes the configured Supabase client (API key and access token) rather
  than a separate hardcoded HTTP endpoint. Invalid coordinates fail before I/O.
  400/401/403/422 never trigger a direct-write retry. A 5xx city lookup outage may
  save only the caller's coordinates through RLS, preserving the existing city;
  an empty/denied write is an error. Account changes invalidate pending responses.
- Super admin lounge selection does not call the staff-only live shift overview
  path. No execute grant or role privilege was broadened.

## Evidence and scope

Flutter tests use synthetic HTTP/repositories and local widget rendering. Two
explicit live database tests remain disabled unless PLAYSPOT_RUN_LIVE_TESTS is
set: test/features/marketing/query_promotions_test.dart and
live_realtime_rls_security_test.dart. They were not executed against production.
The 10 native widget screenshots cover Arabic RTL, bundled Tajawal and Material
icons, widths 360/600/768/1024/1440, and text scales 1.0/1.6. They use a deterministic
empty-bookings/seven-room fixture and show the implemented Flutter widgets. They
are not authenticated live browser screenshots or a browser end-to-end result.
See the accompanying delivery report for final counts, CI, commits and artifacts.

Only generated plugin line-ending changes were produced by pub get; after a
content-equivalence check they were restored in this worktree. No generated plugin
file or test_cache_box.bak is included in UI commits. Original checkouts were not
modified. Changed Dart files are formatted; pre-existing full-tree formatting
debt is reported instead of mass reformatting unrelated source.

## Hosted facts verified read-only

The selected project is play spot / tgpdexoitemmpruepgyt. Current authenticated
execute grants exist for get_active_lounge_requests_page and
get_pending_extension_requests. Their definitions perform caller/resource checks.
The supplied earlier 42501 log does not justify granting anonymous access.
get_lounge_live_shift_overview explicitly excludes super admins and requires a
lounge member. The client must respect this operational boundary.

get_lounge_review_requests and get_loyalty_dashboard_stats are absent from the
hosted catalog. Versioned KYC SQL exists in the mobile repository at
supabase/review/migrations/20261001110000_versioned_lounge_review.sql, outside the
automatic migration path, with a contract and local fixture tests. It remains
review-only and has not been applied. Never substitute customer lounge reviews
for KYC decisions or client-computed statistics for an authorized server aggregate.

The deployed update-user-location function returns 502 when its reverse-geocoding
provider fails. Client transport and write-result handling are repaired, but
provider availability and correct city resolution still require a monitored
staging/live check. No hosted Edge Function was redeployed in this phase.

Invalid login credentials (400) and deletion of a missing promotion (P0002) are
business rejections, not successful operations. They should not be hidden.

## Release constraints

No hosted SQL, migrations, force pushes, hard resets or main merge were performed.
Offline cashier source and local reconciliation fixtures do not establish that
every UI mutation and cache bootstrap works offline against the deployed backend.
Missing contracts, complete offline scenarios, production RLS/grants, hosted KYC,
real browser sign-in and device/profile performance remain release requirements.
The current dev delivery is for testing, not a production readiness declaration.
