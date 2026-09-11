# AGENT CODING RULES & ARCHITECTURAL GUIDELINES

You must strictly adhere to the following rules for ALL code generation, refactoring, and feature implementations in this **Flutter Web Dashboard** project (Flutter + Supabase, Clean Architecture, BLoC/Cubit).

> This project shares its architecture, domain/data-layer contracts, and naming conventions with a companion **Mobile App** repository (governed by its own, separate rules file). If you are ever unsure whether a decision here (a `Failure` type, an RPC contract, a caching strategy, a naming convention) should match the mobile side, assume it should — the two repos are meant to stay in lockstep on everything except platform-specific `presentation/` widgets.

⚠️ **MANDATORY CHECKPOINT:** Before starting any new feature, task, or refactoring step, you MUST re-read and validate your code against these guidelines to ensure zero regressions, zero infinite loops, zero UI crashes, and strict architectural integrity.

---

## 1. Localization & String Handling
- **NO HARDCODED STRINGS:** Never write raw strings directly in UI widgets, logic layers, or error messages (e.g., no `Text('Dashboard')` or `errorMessage = 'Failed'`).
- **Use Localization Files:** All user-facing text, error messages, placeholders, and labels MUST be added to and referenced from the app's localization files (e.g., `AppLocalizations.of(context)!` or `easy_localization` / `slang` syntax used in the project).
- **RTL/LTR Safety:** Never hardcode directional values (`left`, `right`, `EdgeInsets.only(left: ...)`). Always use directional-aware widgets/properties (`EdgeInsetsDirectional`, `Alignment.centerStart/End`, `Directionality`-aware icons) so the UI works correctly in both Arabic (RTL) and English (LTR).

## 2. GoRouter & Provider Scoping
- **No In-View Providers:** NEVER declare `BlocProvider` inside the `build()` method of UI View classes, inside custom widgets, or at the top of page screens.
- **Route-Level Scope:** ALL `BlocProvider` instances MUST be provided strictly inside the `GoRoute.builder` mapping within the `app_router.dart` configuration file.
- **Global / Shell Scoping:** Persistent Cubits (such as `ShiftCubit`, `LoungeStatsCubit`, `DashboardCubit`) MUST be initialized at the `ShellRoute` level and accessed via `context.read<YourCubit>()` in sub-views. NEVER re-instantiate them across child routes.
- **No Side-Effects in Creation:** NEVER trigger API requests, async fetches, or side-effects inside the `create: (context) => ...` callback of a `BlocProvider`. Instantiation must be pure.
- **Pure Const Views:** UI View widgets must accept `const` constructors where possible, remaining completely agnostic of how their Cubit/Bloc was created or provided.
- **Provider Restrictions:**
    - **No `MultiBlocProvider` — Use the Shared `AppProviderScope` Helper:** Instead of `MultiBlocProvider` or manual nesting, all `ShellRoute`-level persistent Cubits MUST be composed via a single shared helper widget (e.g. `MultiBlocProviderScope` in `art_core/di/provider_scope.dart`) that internally folds a `List<BlocProvider>` into a nested tree. This keeps the *call site* flat (one widget, one list) while still avoiding the banned `MultiBlocProvider` API directly, and prevents ad-hoc pyramid nesting from being hand-written per screen.
    - **`BlocProvider.value` Exception — Overlays Only:** `BlocProvider.value` is permitted in exactly one case: making an already-provided Cubit available inside a `showDialog`, `showModalBottomSheet`, or other `Navigator` overlay builder, since these build a widget subtree outside the calling context's tree. Usage outside this exception remains strictly prohibited.
- **Route Guards:** Auth/role-based route protection MUST be implemented via `GoRouter.redirect` at the router configuration level, NEVER via conditional checks scattered inside individual screens.
- **Reflect Filter/Tab State in the URL (2.1):** Any screen-level filter, date range, or tab selection that affects what data is fetched or displayed MUST be reflected in the route's query parameters via GoRouter, so the state survives a page refresh and can be shared as a link. Purely ephemeral UI state (e.g. a dropdown being open) is exempt.

## 3. UI Engineering & Web Stability Rules (CRITICAL)
- **Zero Force-Unwrapping (`!` Ban):** NEVER use the bang operator `!` on entity/model properties inside widgets (e.g., avoid `state.overview!.startTime!`). Always provide explicit fallback values (e.g., `overview?.cashierName ?? 'N/A'`, `overview?.startTime != null ? DateFormat.jm().format(overview!.startTime!) : '--:--'`). This rule applies specifically to the **null-assertion operator** (`someNullable!`), not to boolean logical negation (`!someBool`), which remains unrestricted.
- **Web Layout & Hit-Testing Safety:** Never perform gesture handling or size queries during unconstrained layout passes. Ensure all parent containers inside Web Dashboards have bounded constraints or wrapped inside `Expanded` / `Flexible` to prevent "Cannot hit test a render box that has never been laid out".
- **Loading & Skeleton Shimmers:** Never display empty blank screens while states are loading. Always show a dedicated lightweight shimmer/skeleton loader that respects the widget's exact dimensions.
- **Empty & Error UI States:** Every list, table, or card collection MUST render a clean, localized empty-state placeholder or error fallback widget with an explicit retry action button.
- **Manual Refresh Convention:** Every screen backed by a one-shot (non-realtime) Cubit fetch MUST expose an explicit manual refresh mechanism — a `RefreshIndicator` where the layout allows pull gestures, or a visible refresh button in the header otherwise — wired to the `forceRefresh: true` bypass from Section 7. A screen with no realtime stream and no manual refresh path is non-compliant.
- **CanvasKit Context Loss Protection:** Do not trigger continuous micro-animations or unbounded canvas repaints during data fetches to avoid browser WebGL crashes.
- **Responsive Layout Rules:** Every screen MUST adapt across at least three standardized breakpoints (`mobile < 600`, `tablet 600–1024`, `desktop > 1024`) using a single shared `Breakpoints`/`ResponsiveLayout` utility. NEVER hardcode pixel-based conditionals (`if (width > 843)`) directly inside feature screens. Any widget subtree beneath a breakpoint-driven `LayoutBuilder` that is expensive to rebuild (charts, large grids, anything performing non-trivial computation in `build()`) MUST be wrapped in `RepaintBoundary` and MUST NOT perform recomputation inside `build()` on every layout pass — precompute or cache the computed values outside of `build()`.
- **Pointer/Hover States:** Interactive elements (rows, cards, buttons) MUST expose a `MouseRegion`/hover state, since Web Dashboard users rely on mouse/cursor feedback, not touch.
- **Keyboard & Screen Reader Accessibility (3.1):** Every interactive element (button, card, row, tab) MUST be reachable via keyboard `Tab` navigation with a visible focus indicator, and MUST expose a `Semantics` label describing its action. Custom widgets built on `GestureDetector` alone (no built-in focus handling) MUST be wrapped in `Focus`/`FocusableActionDetector` to remain keyboard-operable.
- **Destructive Action Confirmation:** Any delete, deactivate, logout, or irreversible mutation MUST be gated behind a confirmation dialog using the shared `AppConfirmDialog` component. Never wire a destructive action directly to a button's `onPressed`.

## 4. UI Performance, Minimal Rebuilds & When Predicates
- **Targeted Rebuilds Only:** Wrap ONLY the specific component or leaf widget that actually needs to re-render with `BlocBuilder` or `BlocSelector`.
- **Mandatory `buildWhen` Condition:** ALL `BlocBuilder` instances MUST explicitly define a `buildWhen` predicate to ensure the widget ONLY rebuilds when the relevant subset of state actually changes.
- **Mandatory `listenWhen` Condition:** ALL `BlocListener` instances MUST explicitly define a `listenWhen` predicate to prevent redundant side-effects.
- **NO AUTOMATIC RETRIES IN LISTENERS:** NEVER trigger automatic data re-fetching inside a `BlocListener` when a failure/error state is caught. Retries must strictly be user-initiated (e.g., via a "Try Again" button) to prevent infinite re-render/retry loops.
- **No Global/Screen-Level Rebuilds:** NEVER wrap an entire Screen, Scaffold, Layout Shell, Sidebar, Navigation Bar, or Header inside a `BlocBuilder`.
- **Aggressive Const Usage:** Use `const` constructors aggressively across all UI widgets to prevent unnecessary paint cycles on rebuild.
- **Debounce Reactive Inputs:** Any search field, filter, or input that triggers a Cubit event on every keystroke MUST be debounced (e.g., 300–500ms) using a shared debouncer utility to prevent excessive API calls/rebuilds.

## 5. State Management, Value Equality & Equatable
- **Enum-Based States:** Use an enum to represent status (e.g., `enum RequestStatus { initial, loading, success, failure }`) instead of creating multiple state classes per feature.
- **Single State Class:** Each feature Cubit must have a single immutable State class holding the status enum, data properties, and optional localized failure objects/keys.
- **Mandatory Equatable on All States and Models:** ALL State classes, Entities, and Models MUST extend `Equatable` and implement `List<Object?> get props` accurately. Emitting a state with identical values must NOT trigger listeners or rebuilds.
- **`copyWith` Pattern:** Always use `copyWith` to emit new state instances cleanly.
- **Stream & Controller Disposal:** Any `StreamSubscription`, `TextEditingController`, `ScrollController`, `AnimationController`, or Supabase Realtime channel subscription created inside a Cubit/Widget MUST be explicitly cancelled/disposed in `close()` (Cubit) or `dispose()` (Widget). No exceptions.
- **Idempotent Stream Subscriptions (5.1):** Any Cubit method that starts a realtime subscription (`startWatching...`, `watch...`) MUST: (1) cancel any existing `StreamSubscription` held by the Cubit before creating a new one, regardless of whether the method is being called for the first time or re-invoked; (2) guard against redundant re-invocation with identical parameters (e.g. store the last id/params passed and skip re-subscribing if unchanged); (3) treat the Cubit itself, not the calling widget, as the single source of truth for subscription lifecycle.
- **Tab Visibility Awareness:** Cubits holding active Realtime subscriptions MUST listen for browser tab visibility changes (via the platform's visibility-change signal) and pause/detach subscriptions when the tab is hidden, resuming on visibility restore — mirroring the Mobile app's `AppLifecycleState` handling in intent, even though the underlying API differs by platform.

## 6. Clean Architecture Purity & Directory Scaffolding (Flat Presentation)
- **No Duplicate Data Sources / Repositories:** NEVER create duplicate files or competing folders (e.g., do NOT create both `data_source` and `data_sources`, or `repos` and `repositories`).
- **Standard Feature Scaffolding:**

```
feature_name/
├── data/
│   ├── datasources/                # Single Remote & Local Data Source files (including caching layers)
│   ├── models/                     # Data transfer objects extending Entities
│   └── repositories/               # Concrete Repository implementations (*_repository_impl.dart)
├── domain/
│   ├── entities/                   # Pure business models extending Equatable
│   ├── repositories/               # Abstract repository interfaces (*_repository.dart)
│   └── usecases/                   # Individual callable use case classes
└── presentation/
    ├── feature_screen.dart         # Direct Screen / View file (NO screens/ subfolder)
    ├── feature_cubit.dart          # Direct Cubit file (NO cubit/ subfolder)
    ├── feature_state.dart          # Direct State file (NO cubit/ subfolder)
    └── widgets/                    # Dedicated folder strictly for reusable private UI widgets
```

- **Strict Entity Location:** Entities MUST reside in `domain/entities/`, NEVER inside `data/entities/`.
- **One Class Per File:** Every file must contain EXACTLY ONE class.

## 7. Supabase Queries, Database Safety & Caching Strategies
- **Root Cause & Fix for `PostgreSQL 54001: stack depth limit exceeded`:** This error is NOT inherently caused by multi-table select joins, but by **infinite recursion in Postgres Row-Level Security (RLS) policies** (e.g. Table A's policy querying Table B, whose policy queries Table A back). When encountering 54001:
  1. Inspect Postgres RLS policies for circular table references or self-querying functions.
  2. Fix circular policies on Postgres by wrapping helper queries inside `SECURITY DEFINER` functions with `SET search_path = public` and `SET row_security = off` to break RLS evaluation recursion.
  3. Do NOT use "Flat Selects" as a blanket rule or band-aid to mask broken RLS policies — RPCs and flat selects are for performance/aggregation optimization, not for hiding database recursion bugs.
- **Column Verification:** Always verify exact column names before executing queries (e.g., do NOT guess `user_id` when the schema uses `cashier_id` or `staff_user_id`).
- **Realtime Channel Filtering & Payload Evaluation:** Realtime channel string labels (e.g. `client.channel('public:table:topic')`) are client-side identifiers and do NOT perform server-side event filtering. Server-side filtering MUST be defined using `filter: PostgresChangeFilter(...)`. Furthermore, event callbacks MUST evaluate event records (`payload.newRecord` / `payload.oldRecord`) before triggering network re-fetches to avoid redundant API queries under high load.
- **Location Updates Isolation:** Functions that update hardware/device state (e.g., GPS location, device info) MUST be called exactly once during bootstrap/login with an explicit execution flag. NEVER trigger updates inside `build()` methods or reactive listeners.
- **RLS Awareness:** Never assume a table is protected — every new Supabase table accessed from the client MUST have Row Level Security policies verified/documented before the data source is written. Never bypass RLS from the client by using the service role key.
- **Pagination for Large Datasets:** Any list-returning query expected to grow beyond ~50 rows (transactions, logs, orders, shifts) MUST use `.range()`-based pagination or an infinite-scroll cursor in the data source. NEVER fetch an entire table with an unbounded `select()`.

### 🗄️ Caching & Invalidation Rules (Cache-First Strategy)
- **Cache-First Implementation:** For heavy or frequently accessed read operations (e.g., lounge profiles, menus, configurations), repositories MUST use a Cache-First strategy via Local Data Sources (SharedPreferences / Hive / Isar). Instantly emit local cache for zero-latency UI rendering, then fetch fresh data from Supabase in the background, update the cache, and emit the fresh state.
- **Write-Through & Invalidation on Mutate:** Whenever a mutation, update, or write operation succeeds (e.g., `updateLoungeProfile`, `updateMenuItem`), the repository must immediately update or clear/invalidate the corresponding local cache keys to prevent displaying stale data.
- **Session & Auth Cleanup:** Always clear relevant local cache keys or invoke local storage resets upon user Logout to prevent data leakage between different admin sessions.
- **Manual Refresh Bypass:** Provide a `forceRefresh: true` flag or equivalent mechanism in repository fetch methods to completely bypass local caching when a manual sync/refresh is triggered.
- **Realtime Channel Hygiene:** Any Supabase Realtime channel (`.channel(...)`) subscribed to inside a repository/data source MUST be unsubscribed/removed (`supabase.removeChannel`) when the owning Cubit closes, to prevent duplicate event listeners and memory leaks. Ownership is layered, not duplicated: the **Repository/Datasource** owns the Supabase `RealtimeChannel` and is solely responsible for `supabase.removeChannel()`. The **Cubit** owns the `StreamSubscription` it created by listening to the Repository's stream, and is solely responsible for cancelling *that* subscription (see Section 5). Neither layer calls the other's cleanup method directly.

## 8. Feature-Level Dependency Injection (GetIt)
- **Modular DI:** Every feature MUST have its own dedicated DI setup file (e.g., `auth_di.dart`, `shifts_di.dart`).
- **Explicit Type Registration:** Always register dependencies via their abstract interfaces (e.g., `sl.registerLazySingleton<ShiftRepository>(() => ShiftRepositoryImpl(sl()))`).
- **No Dead Registrations:** When removing or refactoring duplicate data sources/repositories, immediately clean up and sync the feature DI file and `injection_container.dart`.

## 9. Execution Discipline
- **One Micro-Step at a Time:** Execute refactoring or creation ONE MICRO-STEP at a time to maintain context and code quality.
- **Verify Existing Code First:** Before creating any new file, inspect existing directories to prevent duplicating classes that already exist under slightly different names.
- **No Unsolicited Scope Changes:** Do not modify unrelated files or change project structure unless explicitly instructed.

## 10. Single Component Architecture & Custom Component Reuse (MANDATORY)
- **SINGLE STANDARDIZED BUTTON COMPONENT:** ALL buttons across the entire codebase MUST strictly use `AppButton` (`lib/art_core/widgets/app_button.dart`). Direct usage of raw Flutter buttons (`ElevatedButton`, `OutlinedButton`, `TextButton`) or duplicate custom button implementations in feature modules is strictly prohibited. `AppButton` supports all variants (`primary`, `gradient`, `outlined`, `danger`, `text`), icons, loading states, and custom styling.
- **CUSTOM COMPONENT REUSE FOR REPEATED UI:** Any UI widget, card, table, input field, status badge, dialog, or section container that appears in more than one place MUST be created as a custom reusable widget component under `lib/art_core/widgets/` or feature-specific `widgets/`. Re-writing or duplicating identical UI structures across screens is strictly forbidden.
- **Design Tokens Only:** Colors, spacing, radii, font sizes, and shadows MUST always come from the shared theme/design-tokens file (e.g., `AppColors`, `AppSpacing`, `AppTextStyles`). Raw hex codes (`Color(0xFF...)`), magic numbers (`SizedBox(height: 17)`), or inline `TextStyle(fontSize: 14)` are strictly forbidden inside feature code.

## 11. Error Handling & Result Pattern (MANDATORY)
- **Unified Failure Type:** Define a single sealed/abstract `Failure` hierarchy in `core/errors/` (e.g., `ServerFailure`, `CacheFailure`, `NetworkFailure`, `ValidationFailure`). NEVER throw raw `Exception` or `String` errors out of a Repository or Usecase.
- **Either/Result Contract:** Every Repository method and Usecase MUST return `Either<Failure, T>` (via `dartz` or `fpdart`, whichever is already used in the project — verify before adding a new dependency). Cubits must never catch raw exceptions from a repository call; they only pattern-match on `Left`/`Right`.
- **Exception-to-Failure Mapping:** Data sources are the ONLY layer allowed to catch raw exceptions (`PostgrestException`, `SocketException`, `AuthException`, etc.) and must map them to the appropriate `Failure` subtype before they cross into the Repository layer.
- **Localized Failure Messages:** Every `Failure` must carry a localization key (not a raw English string) so the presentation layer can render it via the localization system from Rule 1.

## 12. Logging & Debugging Discipline
- **No `print()` in Production Code:** NEVER use `print()`, `debugPrint()` for permanent logging, or leftover `// TODO: remove` debug statements. Use the project's shared `AppLogger` (wrapping the `logger` package or similar) with proper log levels (`info`, `warning`, `error`).
- **No Sensitive Data in Logs:** Never log tokens, passwords, full user objects, or raw Supabase auth sessions, even at debug level.
- **Clean Before Commit:** Any temporary debug logging added during a task MUST be removed before considering the task complete.

## 13. Testing Requirements
- **Usecases Must Be Testable & Tested:** Every Usecase MUST have at least one corresponding unit test covering the success path and at least one failure path, using mocked Repository interfaces (`mocktail`/`mockito`).
- **Cubit Testing:** Every Cubit MUST have `bloc_test` coverage for its primary state transitions (initial → loading → success/failure), using a mocked Usecase layer.
- **No Live Network Calls in Tests:** Tests MUST NEVER hit the real Supabase project. All data sources are mocked at the Repository or Datasource boundary.
- **Widget Tests for Shared Components:** Any component added under `art_core/widgets/` (per Rule 10) that is reused in 3+ places MUST include a basic widget test verifying it renders without exceptions across its documented variants.
- **Responsive Breakpoint Coverage:** Any screen implementing the mandatory 3-breakpoint responsive layout (Section 3) MUST have at least one widget/golden test per breakpoint (`mobile`, `tablet`, `desktop`) verifying the correct branch renders without exceptions.

## 14. Security & Configuration
- **No Hardcoded Secrets:** Supabase URL, anon key, or any API key/secret MUST NEVER be hardcoded directly in Dart files. They must be injected via `--dart-define`, a `.env` file (excluded from version control), or a build-time config class populated from environment variables.
- **Client Never Uses Service Role Key:** The Supabase service role key must never appear anywhere in client-side (Flutter) code, under any circumstance — only the anon/public key is allowed on the client, protected by RLS.
- **Input Validation Before Mutation:** Any form or input feeding a Supabase write MUST be validated on the client (required fields, formats, ranges) before the mutation call is dispatched — never rely on the database to be the only validation layer.
- **Secure Token Storage on Web:** Auth tokens and refresh tokens MUST NOT be stored in `localStorage`/`sessionStorage` from Dart code. Use the project's designated secure web storage strategy (e.g., httpOnly session cookies set by the backend, or an equivalent mechanism agreed with the backend team) — document the chosen approach in `core/auth/` and keep it identical across both repos' token *contracts* even though the storage *mechanism* differs by platform.

## 15. Naming Conventions
- **Files:** `snake_case.dart` matching the primary class name (e.g., `shift_repository_impl.dart` → `ShiftRepositoryImpl`).
- **Classes:** `PascalCase`, suffixed by role — `*RepositoryImpl`, `*RemoteDataSource`, `*LocalDataSource`, `*Usecase`, `*Cubit`, `*State`.
- **Usecase Naming:** Verb-first, feature-scoped (e.g., `GetShiftOverview`, `UpdateLoungeProfile`) — never generic names like `Handler` or `Manager`.
- **No Ambiguous/Abbreviated Names:** Avoid unclear shorthand (`mgr`, `tmp`, `data2`). Names must describe intent, not implementation detail.

## 16. Problem Diagnosis & Root Cause Verification Before Execution (MANDATORY)
- **MANDATORY DIAGNOSIS FIRST:** Before attempting any bug fix, code modification, or refactoring, you MUST first perform a complete diagnostic analysis to confirm whether the root cause originates from the **Frontend** (Flutter UI, BLoC state, data models, router) or the **Backend** (Supabase DB schema, RLS policies, RPC functions, network/server responses).
- **No Immediate Fixes Without Evidence:** NEVER jump directly into modifying code or writing fixes upon receiving an error report. Always trace the logs, check network/database responses, and verify the exact failure source first.
- **Clear Root Cause Explanation:** Present your diagnostic findings clearly to the user, explaining whether the issue is Frontend or Backend, before applying or proposing any solution.

---

**Priority Note:** If any rule above ever conflicts with the Directory Scaffolding in Section 6, Section 6 wins — the folder structure must never be altered to accommodate a new rule; new rules must fit inside the existing structure instead. This scaffolding must stay identical to the one used in the Mobile App repo — only the `presentation/` layer's widget implementations are allowed to differ between the two.