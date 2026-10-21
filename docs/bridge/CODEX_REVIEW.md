# Codex review handoff — PlaySpot Bridge onboarding v1 (NOT SHIPPED)

Related backend proposal in mobile repository: docs/bridge/ARCHITECTURE_PROPOSAL.md on feature/bridge-backend-contract-20261021.
Dashboard files:
- lib/features/integrations/domain/services/bridge_setup_planner.dart
- test/features/integrations/domain/services/bridge_setup_planner_test.dart
- docs/bridge/questionnaire.v1.json
- docs/bridge/INSTALLATION_GUIDE_AR.md

## Exact implementation status
- DONE: A PURE DART advice-only classifier for native OS / API / Local Agent / Hybrid / assessment, with fail-closed flags (instantBookingAllowed and sessionControlAllowed are ALWAYS false until a verified backend activates the integration).
- DONE: Unit tests authored for no system, documented API, missing atomic reservation, Windows Agent, offline host, no supported interface, Hybrid, missing permission, unsupported session controls.
- DONE: Versioned question catalog (Arabic and English) with conditional display metadata, including explicit "unknown" answers; no credentials collected.
- DONE: Highly simplified Arabic human setup guide for API, Windows and Hybrid, with explicit limitations and non-existent installer notices.
- NOT DONE: Actual Flutter form wiring, persistence, UI localization/validation, onboarding step change, owner/staff delegation enforcement, backend migrations, Vendor Adapters, functioning Local Agent executable, credential vault/pairing, bookings, session dispatch, live tests, deployment.
- NO CHANGE to production/demonstration Supabase DB. NO change to any existing 9-step onboarding flow, to avoid breaking onboarding before Codex reviews schema/API/UX.
- NO FLUTTER ANALYZE or flutter test run in this workspace (Dart/Flutter SDK unavailable). CI/checks still required.

## CRITICAL REVIEW REQUEST
1. Compare proposed architecture with current dev backend and production Supabase; do not trust filenames alone.
2. Confirm mapping from JSON answers (string "true"/"false"/"unknown") into nullable Dart booleans; unknown must stay null, not false.
3. Verify form conditional logic (multiple visibleWhen conditions are AND). No future answer may imply permissions or activation.
4. Evaluate BridgeSetupPlanner logic for contradictions, particularly "API localNetwork requires Agent", "Hybrid requires separate session commands", and missing vendor permission. Add cases for missing API docs and unknown Windows OS.
5. Never show a successful connection because "technicalPilotCandidate" was returned. UI says "needs engineering review".
6. Use AppStrings / easy_localization and existing dashboard form widgets for AR/EN RTL/LTR, accessibility and draft safety; do not hardcode Arabic into production widget.
7. Decide whether integration survey belongs in existing 9-step owner onboarding or as a post-KYC owner-only optional setup flow. DO NOT silently change existing step count.
8. Implement a server-side draft/review record only after a reviewed migration in the MOBILE repo; never store vendor credentials in LoungeDraftParams or browser local cache.
9. Enforce actor authorization and lounge scope in server RPCs; UI checks never enough. Cashiers may supply metadata but cannot approve pairing.
10. Ensure Native PlaySpot, current booking RPC, holds, sessions, pricing, and cashier offline protocol remain backward compatible.
11. Review latest Supabase breaking changes: October 12, 2026 TLS cipher changes starting Nov 10; avoid planning Agent for unsupported Windows TLS.
12. Investigate production send-system-announcement unauthorized audience: current prod source accepted owner/admin role while dashboard dev has canonical is_super_admin authorization and regression tests. Decide and test secure release independent of Bridge.
13. Investigate demo financial custody/settlement schema absent on prod; don't merge demo into production without contract/ledger review.
14. Run formatting, flutter analyze, unit/widget tests, JSON parse validation and staging integration tests. Report commands, output, and any blockers.
15. Keep any new code in focused PRs targeting dev. No production or demo mutations until explicit safe rollout.

## REQUIRED SERVER TESTS BEFORE INTEGRATION ACTIVATION
- cross-tenant attempts / replay / revocation
- atomic reservation of same external room from two sources
- lost ACK after vendor success, vendor down/timeouts, webhook duplication
- post-vendor-reservation PlaySpot checkout failure and safe compensation
- repeated session/charge actions must not duplicate effects
- stale availability cannot be marketed as bookable
- API credentials never in client, survey, logs or GitHub
- manual confirmation fallback for closed/read-only vendor
- authorized central operator only can activate/disable connector

## Suggested next steps
First: REVIEW architecture/unknowns with one real vendor API + one Windows POS vendor.
Second: IMPLEMENT server-side integration state in source-of-truth migration (mobile repo) plus secure preview RPCs, tests.
Third: WIRE the questionnaire UX and persistence after server contract approved.
Fourth: BUILD ONE real adapter and Local Agent proof of concept, not a universal magic connector.
Fifth: PILOT + reconcile + rollback, then consider activation and marketing claims.