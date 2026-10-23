# PlaySpot Dashboard: agent engineering rules

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
- After each scoped change, update the relevant handoff/evidence document with its current commit, verified checks, and remaining blockers. Keep this guide current when architecture or product direction changes; do not turn unverified plans into facts.
