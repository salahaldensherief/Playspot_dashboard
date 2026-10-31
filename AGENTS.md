# PlaySpot Dashboard: agent engineering rules

## Permanent agent continuity — mandatory for every task
Before PlaySpot engineering work, read the current snapshot and relevant evidence in the
[canonical Mobile/Backend handover](https://github.com/salahaldensherief/playspot_V2/blob/dev/docs/ANTIGRAVITY_FINAL_CODEX_HANDOFF.md)
(`docs/ANTIGRAVITY_FINAL_CODEX_HANDOFF.md` in the companion repository), then inspect
actual affected Git state. Reuse verified context; do not repeat broad audits.
After EVERY task, update that same handover with proportional changes, commits,
checks, decisions, blockers and the exact next step. Preserve historical decisions;
separate IMPLEMENTED, TESTED, INTEGRATED, DEPLOYED and ACCEPTED. A local commit or
passing CI is not deployment/acceptance. Never replace evidence with assumptions.
The GitHub link can lag local work: use the verified local canonical dev worktree
when delivery is blocked, and state this explicitly rather than creating another handover.

Current deployment boundary (1 November 2026): owner reports Vercel Production
Branch = dev; current project settings/Preview backend scope are NOT independently
verified. This supersedes older unconditional dev=Preview descriptions below.
No Dashboard push, Production-branch edit, hosted backend access or deployment.
Refund writes default OFF (`PLAYSPOT_MANUAL_REFUND_WRITES`); only explicitly
selected isolated local acceptance may enable them before a reviewed rollout.
See `docs/qa/2026-11-01-canonical-refunds.md`.

## Current dev consolidation scope — 31 October 2026
The latest owner directive supersedes earlier rollout authorization: local isolated dev consolidation only; no Production or hosted Staging connections, hosted changes, deployments, main changes or release PR merges. Preserve user edits, keys, disks and recovery assets. Dashboard dev push triggers Preview and requires fresh approval for its exact commit/effects.

Use risk-based verification: inspect cosmetic changes; focus tests on changed behavior/contracts; use real isolated authorization, concurrency and accounting checks for financial/Auth/database work. Group related changes, reuse exact unchanged evidence, and run broader checks only at the combined integration gate. Do not create tests for colors/constants, repeatedly rerun successful unchanged suites, refactor unrelated code or produce duplicate inventories. Efficiency must never weaken financial/security/recovery checks. Current bootstrap and evidence: tooling/dev-stack/README.md and docs/audits/DEV_CONSOLIDATION_20261031.md in the canonical Mobile repository.

## Current release/recovery boundary — 31 October 2026
The owner wants the real integrated PlaySpot system as the final destination; temporary fixtures are verification tools. Latest clarification prohibits Production connections or backup configuration changes because no restorable Production backup is verified. Hold Production migrations/main promotion/deployment and connected-runtime checks. Independent dev integration/CI and offline signed/Production-configured builds remain verification work only. See docs/audits/PRODUCTION_DELIVERY_GATE_20261031.md and canonical Mobile docs/audits/BACKUP_RECOVERY_INVENTORY_20261031.md. Preserve original user edits, disks, keys and backups. Google Play publication remains excluded.

## Owner-approved room equipment cards (29 October 2026)

The owner approved a targeted equipment-illustration treatment for RoomOccupancyCard/RoomOccupancyGrid. This does not approve the rejected whole-Dashboard redesign. Use structured RoomEntity categories and explicit activity names; VIP is a space type. Unknown/mixed equipment uses neutral artwork. Keep timers, prices and controls as Flutter widgets, with the existing server contracts; Open Time has elapsed time and no invented remaining-time progress. Original static SVG provenance and research are in `docs/design/EQUIPMENT_CARDS_20261029.md` and `assets/equipment/PROVENANCE.md`. The local fixture is synthetic and does not initialize Supabase. Preserve the shared clock and artwork repaint isolation. Dashboard dev push remains coupled to Vercel Preview; obtain the separate deployment authorization before pushing.

The refinement places native RoomSessionTimer text in console/PC screens and consistent overlays for other equipment; enlarged text expands below artwork. RoomCardsLayout aligns natural-height rows and must permit child height changes during loading/actions. Booking has no trustworthy collected/due amounts: label them unavailable rather than derive them from paymentStatus or totalPrice. Windows visual references require Flutter 3.44.1; the Windows equipment-visuals CI job gates quality, while behavioral/layout tests still run on Linux. Do not replace this with pixel tolerances or blindly regenerated references.

For Windows local runs, use `scripts/launch_local.ps1` and `docs/LOCAL_DEVELOPMENT_LAUNCH.md`. It rejects production endpoints and distinguishes the limited demo backend from a separately prepared development backend. A working login page or Auth token on the old demo schema does not validate the canonical financial contract.

Read this file before changing code. It is the single agent guidance for this Flutter Web dashboard. User instructions and verified product requirements take precedence. The companion Mobile app shares server and domain contracts; its presentation can differ.

## Understand the change

- Trace the real flow before editing: route/widget -> Cubit/state -> use case or repository -> data source -> Supabase RPC/table -> RLS -> response. Some existing features do not use every layer; follow their actual boundaries.
- Find the existing contract, tests, and related Mobile behavior. State the invariant and choose the layer that owns it. Fix a defect at its root cause rather than hiding it in the UI.
- Make focused changes. Do not refactor unrelated features or silently change public models, RPC payloads, or database behavior.
- Diagnose a bug before editing. Reproduce it with a test, trace, or concrete code path, then state the root cause. Inspect existing helpers and registrations before adding another implementation.

## SOLID and clean architecture

- **Single responsibility:** Keep widgets responsible for presentation, Cubits for state and orchestration, use cases/domain services for application rules, repositories for domain-facing data contracts, and data sources for external I/O and parsing. Split a class when it has independent reasons to change, not merely because it crosses a line count.
- **Open/closed:** Extend behavior through a strategy or policy when there are real interchangeable rules (for example, distinct permission or pricing policies). For a single simple case, prefer a clear function over a new abstraction.
- **Liskov substitution:** Implementations must honor repository contracts, including errors, nullability, ownership, and side effects. Do not make a subtype silently weaken an invariant.
- **Interface segregation:** Expose only operations a consumer needs. Avoid giant repository interfaces and placeholder methods that throw for unsupported operations.
- **Dependency inversion:** Domain rules depend on contracts, not Supabase, Flutter widgets, or concrete data sources. Wire implementations through the existing GetIt modules. Do not add an interface for a pure helper with one implementation unless a boundary or test seam calls for it.
- Keep dependencies pointing inward where the feature already uses `presentation / domain / data`. Do not import data models into domain business rules. Map backend DTOs at the data boundary. Do not build ceremonial layers in simple existing paths.
- Use a design pattern only when it solves a concrete variation or lifecycle problem. Prefer the current Cubit, repository, strategy, and dependency injection conventions; explain any new pattern in the PR.
- Keep feature dependency registrations in the existing GetIt modules. Register implementations behind domain contracts where a domain boundary exists, and remove dead registrations with their callers.

## Server authority and cross-client contracts

- Supabase owns booking conflicts, hold validity, checkout prices, payments, permissions, inventory, loyalty, and lifecycle transitions. Dashboard role controls are UX, not authorization. Never trust client-submitted financial or permission values.
- Keep Dashboard and Mobile aligned with the same server contract; their presentation may differ. Review RLS, grants, lounge scope, concurrency, idempotency, and state transitions when changing an RPC or schema. Never put a service-role key in a client.
- Prefer invoker privileges and RLS. Use `SECURITY DEFINER` only when justified, with explicit actor/resource authorization, a safe `search_path`, and narrow execute grants. Never force it merely to satisfy a folder or architecture rule.
- Treat production data as live. Test destructive and concurrency scenarios in staging or with isolated safe records; do not replay old migrations against production.
- Verify schema names, RLS, grants, and query scope before changing data access. Paginate potentially large lists. Cache stable reference data when it improves the actual loading path and preserves freshness.

## Routing and state lifecycle

- Scope Cubits to the route or shell that owns them. Share an existing Cubit with dialogs or overlays when needed, and avoid duplicate subscriptions or fetches during rebuilds.
- Keep auth and role navigation in the router's redirect flow. UI permission checks improve navigation but do not replace server authorization.
- Keep provider creation free of network side effects. Load data at the appropriate screen or Cubit lifecycle point, with explicit cancellation and stale-result handling.
- Make state transitions predictable and use value equality where it prevents redundant work. Add `buildWhen`, `listenWhen`, or selectors when the dependency is narrower than the whole state; avoid predicates that conceal necessary updates.

## Dashboard UI and accessibility

- The current `dev` Dashboard presentation is the approved baseline. The user rejected the station overview and live operations redesign proposed in Dashboard PR #75; it was closed without merge. Preserve the existing presentation unless a new design is reviewed and accepted. Keep functional fixes separate from visual redesigns.
- Use `AppStrings` and the translation files for user-facing text. Keep Arabic and English, RTL and LTR, and locale changes working. Use directional layout values where direction matters.
- Reuse shared buttons, text, tables, states, and design tokens when they fit the same interaction. Extract a component when it represents the same reusable pattern; do not centralize unrelated feature UI solely because it looks similar.
- Build responsive layouts from available constraints and test narrow widths and enlarged text. Avoid unbounded constraints, overflow, unnecessary whole-screen rebuilds, and perpetual animations.
- Make loading, empty, error, retry, disabled, focus, hover, and repeated-action states clear. Give icon-only actions accessible labels and usable hit targets.

## Clean code and verification

- Use names that express business meaning, small cohesive functions, guard clauses, immutable state, and localized user-facing strings. Keep Arabic/English, RTL/LTR, and responsive behavior working. Remove dead paths after verifying callers.
- Reuse existing logic when it represents the same invariant. Avoid premature utilities, rigid file/line caps, universal one-class-per-file rules, and abstractions that add indirection without benefit.
- Handle loading, empty, error, retry, cancellation, and repeated actions. Cancel subscriptions and ignore stale async results. Keep errors visible and actionable.
- Prefer guard clauses, expressive names, and focused functions. Split large widgets or classes by responsibility, not by fixed line counts. Delete commented-out code and temporary debugging output after verifying callers.
- Map external errors at the data boundary into the project's failure contract. Keep secrets and personal data out of logs. Declare directly imported packages in `pubspec.yaml` and explain dependency overrides.
- For a bug: reproduce -> identify root cause -> fix in the owning layer -> add a regression test -> verify. For new behavior, test the important business invariant and authorization/concurrency where relevant. Unit, widget, integration, browser, and RLS tests are all allowed; do not prohibit network-backed tests when an isolated environment exists.
- Run `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --no-fatal-infos`, and relevant `flutter test` suites when available. Report exactly what ran and what could not run. Keep changes in a focused PR and wait for CI before claiming verification.
- After each scoped change, update the relevant handoff or evidence document with the current commit, actual checks, and remaining blockers. Update this guide whenever the verified product direction changes.

## REQUIRED FIRST READ — CROSS-STACK SYSTEM ATLAS

Before a feature, UI/UX, data-flow, pricing, session, offline, security, or integration change, read **[docs/PLAYSPOT_SYSTEM_ATLAS.md](docs/PLAYSPOT_SYSTEM_ATLAS.md)**, then verify current `dev`, overlapping PRs, and the owning source/tests. The atlas is a dated map, not evidence that a Draft PR is merged or a database function is deployed. This `AGENTS.md` remains authoritative for repository-specific engineering rules.

For Open Time cashier start/close, validate the RPC result in the booking remote data source before any UI success. Start must confirm the requested `room_id`, a nonempty `booking_id`, `status: in_progress`, `is_open_time: true`, and parseable server `started_at`; close must confirm `success: true`, the requested `booking_id`, and `status: completed`. These client checks do not validate deployed pricing, payment, or ledger behavior; Mobile financial PR #75 remains blocked on exact-schema verification.

## Draft cashier financial integration (25 October 2026)

The Dashboard `dev` split discount and legacy collection; every inspected staff cash payment action is being routed through the single Draft `checkout_booking_cash_atomic` contract. A personally owned open shift, durable operation ID and matching canonical receipt are required before success. The default request collects the server-calculated remaining balance; amount and percentage discounts are mutually exclusive. This Dashboard branch depends on the revised backend Draft PR #84 and must remain Draft until exact-schema integration, a safe backend-first rollout plan, refunds, permissions and CI are reviewed. Existing production clients still use legacy RPCs. See [the financial integration evidence](docs/qa/2026-10-25-atomic-cash-checkout-integration.md).

The owner-approved business model is manual InstaPay/wallet verification, optional owner-enabled cash, a small configurable deposit or no-deposit cash booking, and final settlement after play. The baseline manual-transfer approval posts the full 100.00 for a future 100.00 booking before play, while the baseline cash collector cannot accept a later cash balance after noncash collection. The Draft integration below addresses collection only; never present it as a complete financial rollout.

The Draft Dashboard branch now detects deposit-required bookings in the manual verification dialog and routes actual-receipt attestation to backend Draft PR #87 with the cashier's own open shift, bank reference, lounge-held funds and durable operation ID. Platform-held transfers need a separate verifier authorized to see that account. The client validates a canonical movement receipt before success and labels the result as partial. Backend PR #87 fails closed on legacy approval for these bookings; cached tabs may show an error until refreshed. The new flow remains Draft and depends on backend PRs #84 and #87 plus full payout/refund and staging integration. See [the financial integration evidence](docs/qa/2026-10-25-atomic-cash-checkout-integration.md).
## Draft owner staff permissions (25 October 2026)

The existing staff detail view gains an owner-only per-employee permission dialog on a separate Draft branch. It depends on backend Draft PR #85's branch-scoped `get_lounge_staff_permissions`, `set_staff_permission` and server-side audit; the client only displays effective server permissions and confirms matching RPC responses. Keep this separate from the Dashboard cash-checkout PR #83, preserve the approved Dashboard design, and do not deploy the UI before the backend. See [staff permission evidence](docs/qa/2026-10-25-owner-staff-permissions.md).

## Preview backend isolation (26 October 2026)

The Vercel project builds a preview on `dev` pushes. Never put the production Supabase URL or anon key in Dart fallback values: a preview without explicit `--dart-define` values must fail closed. Verify a staging build's configured project reference before sharing its URL, and confirm real sign-in against that same isolated backend on both Dashboard and Mobile. See [preview isolation evidence](docs/qa/2026-10-26-dev-preview-safety.md).

## Explicit local IDE profiles (30 October 2026)
Use the named Local backend profile with ignored .env.local.json only after authorization of its exact target; do not populate it from Demo/Staging automatically. The OFFLINE equipment preview profile uses tool/equipment_cards_preview.dart with synthetic Cubits and no hosted initialization. scripts/launch_local.ps1 -ValidateOnly performs offline format checks only, not hosted key/schema verification. VS Code preLaunchTask blocks invalid configuration; IntelliJ users must run validation manually. Preserve generic/legacy profiles and setupInjection's fail-closed check. See docs/LOCAL_DEVELOPMENT_LAUNCH.md.

Operational room controls depend on both RoomState and BookingState freshness: retained booking lists during loading/failure must not leave actions enabled. Observe status-only changes, block initial/loading states and retry failed sources in the current lounge. See docs/audits/RELEASE_READINESS_20261030.md for the local backend gate and evidence levels.

Isolated acceptance has a separately named loopback IDE profile and Local validator mode pinned to http://127.0.0.1:56621. Hosted guards remain enforced; never replace a missing local environment with Demo/Staging. Runtime/storage isolation and service bindings must be independently verified before client use. See docs/LOCAL_DEVELOPMENT_LAUNCH.md and canonical Mobile tooling/local-supabase.

Local acceptance now runs on the separately isolated Supabase stack; use the named loopback profile and ignored public config only. Local font assets avoid external downloads. API journey and native Mobile Auth evidence do not establish authenticated Dashboard browser acceptance. See docs/audits/RELEASE_READINESS_20261030.md for the real refund-audit prerequisite failure and remaining gates.
