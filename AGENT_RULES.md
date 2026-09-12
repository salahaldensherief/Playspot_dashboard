# AGENT CODING RULES & ARCHITECTURAL GUIDELINES (Web Dashboard)

You must strictly adhere to the following rules for ALL code generation, refactoring, and feature implementations in this **Flutter Web Dashboard** project (Flutter Web + Supabase, Clean Architecture, BLoC/Cubit).

> This project shares its architecture, domain/data-layer contracts, and naming conventions with a companion **Mobile App** repository (governed by its own `AGENTS.md`). If you are ever unsure whether a decision here (a `Failure` type, an RPC contract, a caching strategy, a naming convention) should match the mobile side, assume it should — the two repos are meant to stay in lockstep on everything except platform-specific `presentation/` widgets.

⚠️ **MANDATORY CHECKPOINT:** Before starting any new feature, task, or refactoring step, you MUST re-read and validate your code against these guidelines to ensure zero regressions, zero infinite loops, zero UI crashes, and strict architectural integrity.

---

## 1. Localization & String Handling
- **NO HARDCODED STRINGS:** Never write raw strings directly in UI widgets, logic layers, or error messages (e.g., no `Text('Dashboard')` or `errorMessage = 'Failed'`).
- **Use Localization Files:** All user-facing text, error messages, placeholders, and labels MUST be added to and referenced from the app's localization files (e.g., `AppLocalizations.of(context)!` or `easy_localization` / `slang` syntax used in the project).
- **RTL/LTR Safety:** Never hardcode directional values (`left`, `right`, `EdgeInsets.only(left: ...)`). Always use directional-aware widgets/properties (`EdgeInsetsDirectional`, `Alignment.centerStart/End`) since the dashboard supports both English and Arabic.

## 2. GoRouter & Provider Scoping
- **No In-View Providers:** NEVER declare `BlocProvider` inside the `build()` method of UI View classes, inside custom widgets, or at the top of page screens.
- **Route-Level Scope:** ALL `BlocProvider` instances MUST be provided strictly inside the `GoRoute.builder`/`pageBuilder` mapping within the `app_router.dart` configuration file.
- **Global / Shell Scoping:** Persistent Cubits (such as `ShiftCubit`, `LoungeStatsCubit`, `DashboardCubit`) MUST be initialized at the `ShellRoute` level and accessed via `context.read<YourCubit>()` in sub-views. NEVER re-instantiate them across child routes.
- **No Side-Effects in Creation:** NEVER trigger API requests, async fetches, or side-effects inside the `create: (context) => ...` callback of a `BlocProvider`. Instantiation must be pure.
  - **🆕 This rule is currently violated in `app_router.dart` in at least 7 places** (`sl<CategoryCubit>()..loadCategories()`, `sl<MarketingCubit>()..loadPromotions()`, `sl<AdminManagementCubit>()..fetchAdmins()`, the `PermissionsCubit` `create:` block calling `fetchPermissions()`, etc.). These are not exceptions — they are defects to fix. **Correct pattern:** trigger the fetch from the *screen's* `initState()`/`didChangeDependencies()` after reading the already-provided Cubit (`context.read<T>().loadX()`), not from the provider's `create:` callback. This keeps `create:` pure while still loading data as soon as the screen mounts.
- **Pure Const Views:** UI View widgets must accept `const` constructors where possible, remaining completely agnostic of how their Cubit/Bloc was created or provided.
- **Provider Restrictions:**
  - **No `MultiBlocProvider` / No Ad-Hoc Pyramid Nesting — Use a Shared `AppProviderScope` Helper:** Manually nesting `BlocProvider` inside `BlocProvider` inside `BlocProvider` (as currently done 8 levels deep in the main `ShellRoute` builder for `ShiftCubit → BookingCubit → LoungeCubit → RoomCubit → LoungeStatsCubit → DashboardCubit → ExtrasCubit → PermissionsCubit`) is prohibited going forward. Instead, compose `ShellRoute`-level persistent Cubits via a single shared helper widget (e.g. `MultiBlocProviderScope` in `art_core/di/provider_scope.dart`) that internally folds a `List<BlocProvider>` into a nested tree. This keeps the *call site* flat (one widget, one list) while avoiding the banned `MultiBlocProvider` API directly.
  - **🆕 Re-evaluate Eager Shell-Level Cubit Creation:** Before adding a new Cubit to the main dashboard `ShellRoute`, ask whether it is genuinely needed on *every* page under that shell (as `PermissionsCubit` and `DashboardCubit` plausibly are) or only on specific routes (as `ShiftCubit`, `ExtrasCubit` likely are). Cubits only needed by 1–2 specific routes belong in that `GoRoute`'s own `pageBuilder`, not hoisted to the shell — hoisting them to the shell means they are constructed on every navigation under that shell, including pages that never use them.
  - **`BlocProvider.value` Exception — Overlays Only:** `BlocProvider.value` is permitted in exactly one case: making an already-provided Cubit available inside a `showDialog`, `showModalBottomSheet`, or other `Navigator` overlay builder, since these build a widget subtree outside the calling context's tree. Usage outside this exception remains strictly prohibited.
- **Route Guards:** Auth/role/onboarding-based route protection MUST be implemented via `GoRouter.redirect` at the router configuration level, NEVER via conditional checks scattered inside individual screens. (The existing `redirect` callback in `app_router.dart` handling auth/role/onboarding/permission gating is the correct reference pattern — keep new route guards consistent with it.)

## 3. UI Engineering & Web Stability Rules (CRITICAL)
- **Zero Force-Unwrapping (`!` Ban):** NEVER use the bang operator `!` on entity/model properties inside widgets (e.g., avoid `state.overview!.startTime!`). Always provide explicit fallback values (e.g., `overview?.cashierName ?? 'N/A'`, `overview?.startTime != null ? DateFormat.jm().format(overview!.startTime!) : '--:--'`).
  - **🆕 Explicit Exception — `GlobalKey.currentState!`:** The idiom `_formKey.currentState!.validate()` (and equivalent `GlobalKey<FormState>.currentState!` usage) is exempt from this rule. `currentState` is guaranteed non-null whenever the callback referencing it can run (the widget is already built and attached), and forcing a null-check workaround around it produces worse code, not safer code. This exception applies **only** to `GlobalKey.currentState!` immediately after the widget is known to be mounted — it does not extend to entity/model/API-response properties.
- **Web Layout & Hit-Testing Safety:** Never perform gesture handling or size queries during unconstrained layout passes. Ensure all parent containers inside Web Dashboards have bounded constraints or wrapped inside `Expanded` / `Flexible` to prevent `Cannot hit test a render box that has never been laid out`.
- **Loading & Skeleton Shimmers:** Never display empty blank screens while states are loading. Always show a dedicated lightweight shimmer/skeleton loader that respects the widget's exact dimensions.
- **Empty & Error UI States:** Every list, table, or card collection MUST render a clean, localized empty-state placeholder or error fallback widget with an explicit retry action button.
- **CanvasKit Context Loss Protection:** Do not trigger continuous micro-animations or unbounded canvas repaints during data fetches to avoid browser WebGL crashes.
- **🆕 Breakpoint Transitions Must Not Force a Full Tree Rebuild:** The current `ScreenUtilInit(key: ValueKey(designSize.width), ...)` pattern in `app.dart` intentionally forces a full teardown/rebuild of the entire app tree every time the browser window crosses a phone/tablet/desktop breakpoint, discarding scroll positions and local widget state in the process. This is acceptable only as a documented, deliberate trade-off for a dashboard that is rarely resized live — it must not be copied into other breakpoint-driven `LayoutBuilder`/`ScreenUtilInit` usages without the same justification. Where a widget subtree only needs to re-layout (not fully rebuild) across breakpoints, prefer `RepaintBoundary` + conditional layout logic over remounting via `ValueKey`.

## 4. UI Performance, Minimal Rebuilds & When Predicates
- **Targeted Rebuilds Only:** Wrap ONLY the specific component or leaf widget that actually needs to re-render with `BlocBuilder` or `BlocSelector`.
- **Mandatory `buildWhen` Condition:** ALL `BlocBuilder` instances MUST explicitly define a `buildWhen` predicate to ensure the widget ONLY rebuilds when the relevant subset of state actually changes.
- **Mandatory `listenWhen` Condition:** ALL `BlocListener` instances MUST explicitly define a `listenWhen` predicate to prevent redundant side-effects.
- **NO AUTOMATIC RETRIES IN LISTENERS:** NEVER trigger automatic data re-fetching inside a `BlocListener` when a `failure` / `error` state is caught. Retries must strictly be user-initiated (e.g., via a "Try Again" button) to prevent infinite re-render / retry loops.
- **No Global/Screen-Level Rebuilds:** NEVER wrap an entire Screen, Scaffold, Layout Shell, Sidebar, Navigation Bar, or Header inside a `BlocBuilder`.
- **Aggressive Const Usage:** Use `const` constructors aggressively across all UI widgets to prevent unnecessary paint cycles on rebuild.
- **🆕 Repository-Level Caching for Repeatedly-Visited Reference Data:** Data that rarely changes and is reloaded on every visit to a route (e.g. `CategoryCubit.loadCategories()` currently re-fetching on `super-admin/categories`, `lounge-admin/rooms`, and onboarding every single time) MUST use a Cache-First strategy at the repository level (see Section 7) instead of relying on "reload on every mount." A Cubit calling its own load method on every screen mount is not wrong by itself, but the underlying repository must serve cached data instantly and refresh in the background — not re-hit Supabase from a cold state on every navigation.

## 5. State Management, Value Equality & Equatable
- **Enum-Based States:** Use an `enum` to represent status (e.g., `enum RequestStatus { initial, loading, success, failure }`) instead of creating multiple state classes per feature.
- **Single State Class:** Each feature Cubit must have a single immutable State class holding the status enum, data properties, and optional localized failure objects/keys.
- **Mandatory `Equatable` on All States and Models:** ALL State classes, Entities, and Models MUST extend `Equatable` and implement `List<Object?> get props` accurately. Emitting a state with identical values must NOT trigger listeners or rebuilds.
- **`copyWith` Pattern:** Always use `copyWith` to emit new state instances cleanly.
- **🆕 Stream & Controller Disposal:** Any `StreamSubscription`, `TextEditingController`, Supabase Realtime channel (e.g. in `booking_realtime_datasource.dart`), or `AnimationController` created inside a Cubit/Widget MUST be explicitly cancelled/disposed in `close()`/`dispose()`. No exceptions.
- **🆕 Idempotent Stream Subscriptions:** Any Cubit method that starts a realtime subscription (e.g. `watchBookings`) MUST cancel any existing subscription it already holds before creating a new one, and must guard against redundant re-subscription with identical parameters.

## 6. Clean Architecture Purity & Directory Scaffolding (Flat Presentation)
- **No Duplicate Data Sources / Repositories:** NEVER create duplicate files or competing folders (e.g., do NOT create both `data_source` and `data_sources`, or `repos` and `repositories`).
- **Standard Feature Scaffolding:**
  ```text
  feature_name/
  ├── data/
  │   ├── datasources/                # Single Remote / Local Data Source files
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
- **🆕 Current Compliance Status (for reference):** 13 of 16 features already follow this scaffolding correctly (`auth`, `bookings`, `lounges`, `rooms`, `onboarding`, `users`, `analytics`, `marketing`, `payouts`, `kyc`, `loyalty`, `shifts`, `permissions`) — this is the reference standard, keep matching it. `categories` and `staff` still use the old flat pattern (`data/entities/`, `data/data_source/remote/`, `data/repos/`, no `domain/` layer at all). The next non-trivial change to either of those two features MUST migrate it to the full 3-layer scaffolding (introduce `domain/entities`, `domain/repositories`, `domain/usecases`, move the repository implementation under `data/repositories/`) as part of that change, rather than adding to the old structure.

## 7. Supabase Queries & Database Safety Rules
- **No Nested / Recursive Table Joins:** In Remote Data Sources, do NOT perform joins that traverse recursive foreign keys (e.g., avoid `.select('*, profiles(full_name)')` if `profiles` has circular relations). Perform flat, indexed selects or delegate to dedicated RPC functions.
- **Column Verification:** Always verify exact column names before executing queries (e.g., do NOT guess `user_id` when the schema uses `cashier_id` or `staff_user_id`).
- **Safe RPC Over Complex Selects:** For aggregate stats, dashboard overviews, or complex multi-table checks, always call dedicated `SECURITY DEFINER` Postgres functions with `SET search_path = public` and `SET row_security = off` to eliminate `PostgreSQL 54001: stack depth limit exceeded` recursion errors.
- **Location Updates Isolation:** Functions that update hardware/device state (e.g., GPS location, device info) MUST be called exactly once during bootstrap/login with an explicit execution flag. NEVER trigger updates inside `build()` methods or reactive listeners.
- **🆕 RLS Awareness (elevated priority):** Never assume a table is protected — every Supabase table accessed from this dashboard MUST have Row Level Security policies verified/documented, especially since the client uses the public anon key (see Section 14). Never bypass RLS from the client using the service role key.
- **🆕 Pagination for Large Datasets:** Any list-returning query expected to grow beyond ~50 rows (bookings, KYC reviews, staff, loyalty transactions) MUST use `.range()`-based pagination. `BookingRepository.getBookings` already does this correctly (`limit`/`offset` params) — use it as the reference pattern for other list endpoints.
- **🆕 Cache-First for Reference/Config Data:** Repositories serving data that changes infrequently but is read on every navigation (categories, cities, activity types, permission definitions) MUST implement a Cache-First strategy: emit cached data instantly, refresh from Supabase in the background, update the cache, and emit fresh state. This directly addresses the `CategoryCubit` re-fetch-on-every-visit issue noted in Section 4.

## 8. Feature-Level Dependency Injection (GetIt)
- **Modular DI:** Every feature MUST have its own dedicated DI setup file (e.g., `auth_di.dart`, `shifts_di.dart`).
- **Explicit Type Registration:** Always register dependencies via their abstract interfaces (e.g., `sl.registerLazySingleton<ShiftRepository>(() => ShiftRepositoryImpl(sl()))`).
- **No Dead Registrations:** When removing or refactoring duplicate data sources/repositories, immediately clean up and sync the feature DI file and `injection_container.dart`.

## 9. Execution Discipline
- **One Micro-Step at a Time:** Execute refactoring or creation ONE MICRO-STEP at a time to maintain context and code quality.
- **Verify Existing Code First:** Before creating any new file, inspect existing directories to prevent duplicating classes that already exist under slightly different names.
- **No Unsolicited Scope Changes:** Do not modify unrelated files or change project structure unless explicitly instructed.
- **🆕 No Unused Constructor Parameters or Fields:** If a class declares a constructor parameter or a field, it MUST be read/used somewhere in that class's logic. An accepted-but-unused parameter is a defect, not a stylistic nitpick.

## 🆕 10. Design Tokens & Component Reuse (MANDATORY)
- **Design Tokens Only:** Colors, spacing, radii, font sizes, and shadows MUST always come from the shared theme/design-tokens file (`AppColors` and equivalents in `art_core/theme/`). Raw hex codes (`Color(0xFF...)`) or inline `TextStyle(fontSize: 14)` are forbidden inside feature code. **This is already well-followed in this codebase (zero raw hex colors found in `lib/features/`) — keep it that way as new features are added.**
- **Shared Component Reuse:** Any UI widget, card, data-table row, badge, dialog, or form pattern that appears in more than one feature MUST be extracted to `art_core/widgets/`. Two occurrences is the trigger, not three.
- **Single Standardized Button/Table Components:** All buttons MUST use the shared `AppButton` (`art_core/widgets/app_button.dart`). All tabular data MUST use a shared data-table component rather than each feature (bookings, staff, users, KYC) reimplementing its own table layout independently — audit `bookings_data_table.dart` and similar per-feature table widgets for consolidation opportunities.

## 11. Error Handling & Result Pattern
- **Unified Failure Type:** All repositories return `Either<Failure, T>` using the shared `Failure` hierarchy in `core/error/failures.dart` (`ServerFailure`, `CacheFailure`, `NetworkFailure`, `AuthFailure`). **This is already correctly implemented project-wide — no `Either<String, T>` or `Left(e.toString())` instances found.** Keep all new repository methods consistent with this pattern; do not regress to string-based errors.
- **Exception-to-Failure Mapping:** Data sources are the ONLY layer allowed to catch raw exceptions (`PostgrestException`, `SocketException`, `AuthException`, etc.) and must map them to the appropriate `Failure` subtype before they cross into the Repository layer.
- **Localized Failure Messages:** Every `Failure` must carry a localization key (not a raw English string) so the presentation layer can render it via the localization system from Section 1.

## 🆕 12. Logging & Debugging Discipline
- **No `print()` in Production Code:** `print()` calls currently exist in `permissions_cubit.dart`, `permission_item_model.dart`, `permissions_remote_data_source.dart`, and `loyalty_remote_data_source.dart` (10 occurrences total, several tagged `'DEBUG: ...'`). These must be removed and replaced with the project's shared `AppLogger` using proper log levels (`info`, `warning`, `error`), gated by `kDebugMode` where appropriate.
- **Consolidate `debugPrint` Usage:** 53 `debugPrint()` calls currently exist scattered across features with no consistent format or log level. Route all of these through a single `AppLogger` service so logging can be filtered, disabled in production builds, or redirected to a monitoring service later without touching every call site.
- **No Sensitive Data in Logs:** Never log tokens, passwords, full user objects, or raw Supabase auth sessions, even at debug level.
- **Clean Before Commit:** Any temporary debug logging added during a task MUST be removed before considering the task complete.

## 13. Testing Requirements
- **Usecases Must Be Testable & Tested:** Every Usecase MUST have at least one corresponding unit test covering the success path and at least one failure path, using mocked Repository interfaces (`mocktail`/`mockito`).
- **Cubit Testing:** Every Cubit MUST have `bloc_test` coverage for its primary state transitions (initial → loading → success/failure), using a mocked Usecase layer.
- **No Live Network Calls in Tests:** Tests MUST NEVER hit the real Supabase project. All data sources are mocked at the Repository or Datasource boundary.
- **Widget Tests for Shared Components:** Any component under `art_core/widgets/` reused in 3+ places MUST include a basic widget test verifying it renders without exceptions.

## 🆕 14. Security & Configuration
- **No Hardcoded Secrets:** The Supabase URL and anon key are currently hardcoded directly in `core/di/di.dart`. Even though the anon key is designed to be client-visible (RLS-protected), it MUST be injected via `--dart-define` or a build-time config, not committed to source — this decouples staging/production environments and avoids permanently baking a specific project's key into git history.
- **RLS Verification Is Non-Negotiable Given Public Key Exposure:** Because this repository's anon key is committed to version control, treat every table it can reach as if its RLS policies will be read and tested by an outside party — verify and document RLS policies for every table before shipping a new data source that touches it.
- **Client Never Uses Service Role Key:** The Supabase service role key must never appear anywhere in client-side (Flutter Web) code, under any circumstance.
- **Input Validation Before Mutation:** Any form or input feeding a Supabase write MUST be validated on the client before the mutation call is dispatched.

## 🆕 15. Naming Conventions
- **Files:** `snake_case.dart` matching the primary class name (e.g., `booking_repository_impl.dart` → `BookingRepositoryImpl`).
- **Classes:** `PascalCase`, suffixed by role — `*RepositoryImpl`, `*RemoteDataSource`, `*Usecase`, `*Cubit`, `*State`.
- **Usecase Naming:** Verb-first, feature-scoped (e.g., `ConfirmCashPayment`, `UpdateBookingStatus` — the existing `bookings/domain/usecases/` files are the correct reference pattern for naming).
- **No Ambiguous/Abbreviated Names:** Avoid unclear shorthand. Names must describe intent, not implementation detail.

## 🆕 16. Problem Diagnosis & Root Cause Verification Before Execution
- **MANDATORY DIAGNOSIS FIRST:** Before attempting any bug fix, confirm whether the root cause is Frontend (Flutter UI, BLoC state, router) or Backend (Supabase schema, RLS, RPC functions) by tracing logs and network/database responses first.
- **Clear Root Cause Explanation:** Present diagnostic findings clearly before applying or proposing any solution.

## 🆕 17. Dependency Declaration Integrity
- **Explicit `pubspec.yaml` Declaration:** Any package imported and used directly in Dart source MUST be explicitly listed under `dependencies`/`dev_dependencies` in `pubspec.yaml`, never relied upon only as a transitive dependency resolved via `pubspec.lock`.
- **Watch the `dependency_overrides` block:** The current `dependency_overrides: intl: any` is a broad override with no version constraint — this should carry a comment explaining why it's needed (likely a transitive version conflict) so it isn't silently forgotten or copy-pasted into unrelated projects.

---

**Cross-Repo Consistency Note:** This dashboard is currently **ahead of** the mobile app on: Clean Architecture completeness (13/16 vs 0/1 features with a full `domain/` layer), error handling (`Either<Failure,T>` fully adopted vs `Either<String,T>` in mobile), and design-token discipline (zero raw hex colors in features vs several in mobile). When updating either repo's rules or code, treat this dashboard's `bookings` feature and `core/error/failures.dart` as the reference implementation to bring the mobile app up to, rather than re-deriving the pattern independently on the mobile side.