> Review update, 21 October 2026: follow-up branch feature/bridge-security-review-20261021 fixes default-off preview gating, semantic draft restoration, generated conditional catalog, host routing and stale field handling. The checklist below is the ORIGINAL handoff, not the final test status. See REVIEW_20261021.md.

# Codex review handoff — PlaySpot Bridge onboarding v1 (NOT SHIPPED)

Related backend proposal in mobile repository: docs/bridge/ARCHITECTURE_PROPOSAL.md and docs/bridge/proposed_schema.sql on feature/bridge-backend-contract-20261021.
Dashboard files:
- lib/features/integrations/domain/services/bridge_setup_planner.dart
- test/features/integrations/domain/services/bridge_setup_planner_test.dart
- docs/bridge/questionnaire.v1.json
- docs/bridge/INSTALLATION_GUIDE_AR.md
- lib/features/integrations/presentation/widgets/bridge_readiness_step.dart
- test/features/onboarding/domain/entities/bridge_onboarding_draft_test.dart

## Exact implementation status
- DONE: A PURE DART advice-only classifier for native OS / API / Local Agent / Hybrid / assessment, with fail-closed flags (instantBookingAllowed and sessionControlAllowed are ALWAYS false until a verified backend activates the integration).
- DONE: Unit tests authored for no system, documented API, missing atomic reservation, Windows Agent, offline host, no supported interface, Hybrid, missing permission, unsupported session controls.
- DONE: Versioned question catalog (Arabic and English) with conditional display metadata, including explicit "unknown" answers; no credentials collected.
- DONE: Highly simplified Arabic human setup guide for API, Windows and Hybrid, with explicit limitations and non-existent installer notices.
- PROTOTYPE IN BRANCH (UNVERIFIED): Flutter BridgeReadinessStep is wired as optional step 8 in the 10-step lounge onboarding flow, Arabic and English bridge_step translations exist, and answers are stored only as browser-local integrationAnswers on LoungeDraftParams. Its output is advisory and NOT submitted to Supabase. Review the diff carefully; these additions were present on this branch at PR inspection.
- NOT DONE: Server-side answer persistence or approval, owner/staff delegation enforcement, backend migrations, vendor adapters, functioning Local Agent executable, credential vault/pairing, actual booking/session integrations, browser/widget tests, live tests, deployment.
- NO CHANGE to production/demonstration Supabase DB. The DASHBOARD BRANCH changes onboarding from 9 to 10 steps, so Codex must audit step transitions, draft restore, previous/next, final submit, translations, existing users, and whether onboarding should instead occur after KYC.
- NO FLUTTER ANALYZE or flutter test run in this workspace (Dart/Flutter SDK unavailable). Flutter CI/checks still required. Unit tests are authored but NOT claimed as passing.
- Backend proposal includes a **review-only SQL schema (not in migrations)** plus a Node in-memory protocol simulator, unit tests and CI workflow. These are not real vendor connectors.

## CRITICAL REVIEW REQUEST
1. Compare proposed architecture with current dev backend and production Supabase; do not trust filenames alone.
2. Confirm JSON and widget use consistent "yes"/"no"/"unknown" values, converted into Dart true/false/null. Unknown must stay null, not false.
3. Verify form conditional logic (multiple visibleWhen conditions are AND) and that yes/no/unknown map to true/false/null. JSON schema now aligns with widget option values. No answer may imply permissions or activation.
4. Evaluate BridgeSetupPlanner logic for contradictions, particularly "API localNetwork requires Agent", "Hybrid requires separate session commands", and missing vendor permission. Add cases for missing API docs and unknown Windows OS.
5. Never show a successful connection because "technicalPilotCandidate" was returned. UI says "needs engineering review".
6. Use AppStrings / easy_localization and existing dashboard form widgets for AR/EN RTL/LTR, accessibility and draft safety; do not hardcode Arabic into production widget.
7. New prototype inserts the survey as onboarding step 8 and moves review to 9. Decide whether it should remain in initial onboarding or move to optional post-KYC owner-only flow, and test all old draft restore and step count paths.
8. Implement a server-side draft/review record only after a reviewed migration in the MOBILE repo; never store vendor credentials in LoungeDraftParams or browser local cache.
9. Enforce actor authorization and lounge scope in server RPCs; UI checks never enough. Cashiers may supply metadata but cannot approve pairing.
10. Ensure Native PlaySpot, current booking RPC, holds, sessions, pricing, and cashier offline protocol remain backward compatible.
11. Review latest Supabase breaking changes: October 12, 2026 TLS cipher changes starting Nov 10; avoid planning Agent for unsupported Windows TLS.
12. Investigate production send-system-announcement unauthorized audience: current prod source accepted owner/admin role while dashboard dev has canonical is_super_admin authorization and regression tests. Decide and test secure release independent of Bridge.
13. Investigate demo financial custody/settlement schema absent on prod; don't merge demo into production without contract/ledger review.
14. Run formatting, flutter analyze, unit/widget tests, JSON parse validation and staging integration tests. Report commands, output, and any blockers.
15. Keep any new code in focused PRs targeting dev. No production or demo mutations until explicit safe rollout.
16. Ensure the static questionnaire catalog exactly matches the actual UI (including fields and conditional rules); either make catalog the source of truth or remove duplicated definitions after validation.
17. Validate proposed_schema.sql against a disposable PostgreSQL/Supabase project; do not treat review-only SQL as deployable migration. Ensure RLS, grants, cross-lounge trigger, schema drift and missing required audit/approval fields.
18. Run Node reference simulator tests with `node --test tools/bridge-reference/reference_legacy_system.test.mjs` in the mobile repository. Real API and Windows Agent remain absent.

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
Third: AUDIT and stabilize the existing questionnaire UI prototype; implement server-side persistence only after server contract and permissions approved.
Fourth: BUILD ONE real adapter and Local Agent proof of concept, not a universal magic connector.
Fifth: PILOT + reconcile + rollback, then consider activation and marketing claims.