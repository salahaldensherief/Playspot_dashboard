# AGENT CODING RULES & ARCHITECTURAL GUIDELINES (Web Dashboard)

> **Context & Ecosystem:** > This project is a **Flutter Web Dashboard** (Flutter Web + Supabase, Clean Architecture, BLoC/Cubit).  
> It shares architecture, domain/data-layer contracts, and conventions with a companion **Mobile App** repository. Assume all core patterns (Failure types, RPC contracts, caching, naming) must match the mobile repo, diverging **only** on platform-specific `presentation/` widgets.

⚠️ **MANDATORY CHECKPOINT:** Before starting any new feature, task, or refactoring step, you MUST validate your code against these guidelines to ensure zero regressions, zero infinite loops, zero UI crashes, and strict architectural integrity.

---

## 1. Localization & String Handling
* **No Hardcoded Strings:** Never write raw strings directly in UI widgets, logic layers, or error messages (e.g., no `Text('Dashboard')` or `errorMessage = 'Failed'`).
* **Localization Source of Truth:** All user-facing text, error messages, placeholders, and labels MUST be referenced from localization files (e.g., `AppLocalizations.of(context)!`).
* **RTL/LTR Safety:** Never hardcode directional values (`left`, `right`, `EdgeInsets.only(left: ...)`). Always use directional-aware properties (`EdgeInsetsDirectional`, `AlignmentDirectional.centerStart/centerEnd`).

---

## 2. GoRouter & Provider Scoping
* **No In-View Providers:** NEVER declare `BlocProvider` inside the `build()` method, custom widgets, or screen files.
* **Route-Level Scope:** ALL `BlocProvider` instances MUST be provided strictly inside `GoRoute.builder` or `pageBuilder` within `app_router.dart`.
* **Global / Shell Scoping:** Persistent Cubits (e.g., `ShiftCubit`, `LoungeStatsCubit`, `DashboardCubit`) MUST be initialized at the `ShellRoute` level and read via `context.read<T>()`. NEVER re-instantiate them in child routes.
* **No Side-Effects in Creation:** Instantiation inside `create: (context) => ...` must remain purely synchronous. NEVER call API triggers or methods with side-effects inside `create:`.
  * *Violation Fix:* Do not call `sl<X>()..loadX()` inside `app_router.dart`. Trigger fetching inside the target screen's `initState()` or `didChangeDependencies()` after mounting.
* **Provider Tree Restrictions:**
  * **No Manual Pyramid Nesting:** Avoid deep manual nesting of `BlocProvider`s. Use a shared tree-folding helper (e.g., `AppProviderScope` or `MultiBlocProviderScope` in `art_core/di/provider_scope.dart`).
  * **Eager Shell Cubit Audit:** Only hoist Cubits to `ShellRoute` if used globally across all sub-routes. Route-specific Cubits belong exclusively in their respective `GoRoute.pageBuilder`.
  * **`BlocProvider.value` Scope:** Permitted **exclusively** when passing an existing Cubit into a `showDialog`, `showModalBottomSheet`, or overlay context.
* **Route Guards:** Auth, role, and onboarding protection MUST be executed strictly inside `GoRouter.redirect`, never via conditional UI branching inside screens.

---

## 3. UI Engineering & Web Stability (CRITICAL)
* **Zero Force-Unwrapping (`!` Ban):** NEVER use `!` on nullable model/entity properties. Always provide explicit fallbacks (e.g., `overview?.cashierName ?? 'N/A'`).
  * *Exemption:* `_formKey.currentState!.validate()` (and equivalent `GlobalKey<FormState>` operations) is explicitly allowed when the widget is mounted.
* **Web Layout & Hit-Testing Safety:** Ensure all parent containers inside responsive/web dashboard views have bounded constraints or are wrapped in `Expanded`/`Flexible` to prevent `Cannot hit test a render box that has never been laid out`.
* **Loading Skeletons:** Never show blank screens during asynchronous calls. Render dedicated shimmer skeletons matching the target component dimensions.
* **Empty & Error UI States:** Every list, table, or card collection MUST handle empty and error states explicitly with localized messages and a retry action button.
* **CanvasKit Context Protection:** Do not run unbounded micro-animations or infinite canvas repaints to prevent browser WebGL context loss crashes.
* **Breakpoint Transitions:** Avoid rebuilding the full application tree on window resize (e.g., avoid `ScreenUtilInit(key: ValueKey(...))`). Use `LayoutBuilder`, `RepaintBoundary`, and responsive breakpoints without tearing down the widget tree.

---

## 4. UI Performance & Minimal Rebuilds
* **Targeted Rebuilds Only:** Wrap only the specific leaf widget requiring updates with `BlocBuilder` or `BlocSelector`.
* **Mandatory Predicates:**
  * Every `BlocBuilder` MUST implement `buildWhen`.
  * Every `BlocListener` MUST implement `listenWhen`.
* **No Automatic Retries in Listeners:** NEVER re-fetch data automatically inside a `BlocListener` upon error. Retries must be strictly user-driven.
* **No Screen-Level Rebuilds:** NEVER wrap a Scaffold, Screen Shell, Sidebar, or App Bar in a global `BlocBuilder`.
* **Aggressive Const Usage:** Enforce `const` constructors on all immutable UI subtrees.

---

## 5. State Management & Value Equality
* **Enum-Based Status:** Model request cycles with an enum (e.g., `RequestStatus { initial, loading, success, failure }`) within a single immutable state class per feature.
* **Mandatory Equatable:** All State classes, Entities, and Models MUST extend `Equatable` and implement `List<Object?> get props`. Emitting identical data must not trigger rebuilds.
* **State Emission:** Always use `copyWith` to generate next-state instances.
* **Disposal Discipline:** Every `StreamSubscription`, `TextEditingController`, Supabase Realtime channel, and `AnimationController` MUST be cancelled/disposed in `close()` or `dispose()`.
* **Idempotent Realtime Subscriptions:** Before opening a new Supabase realtime subscription inside a Cubit, explicitly cancel and clean up any existing subscription.

---

## 6. Clean Architecture Scaffolding (Flat Presentation)
* **Standard Directory Structure:**
  ```text
  feature_name/
  ├── data/
  │   ├── datasources/        # Remote & Local data sources
  │   ├── models/             # Data Transfer Objects (DTOs extending Entities)
  │   └── repositories/       # Repository implementations (*_repository_impl.dart)
  ├── domain/
  │   ├── entities/           # Pure business models extending Equatable
  │   ├── repositories/       # Abstract repository contracts (*_repository.dart)
  │   └── usecases/           # Single-responsibility callable use cases
  └── presentation/
      ├── feature_screen.dart # Screen / Page entry point (NO screens/ subfolder)
      ├── feature_cubit.dart  # Business logic Cubit (NO cubit/ subfolder)
      ├── feature_state.dart  # State definition (NO cubit/ subfolder)
      └── widgets/            # Reusable private feature widgets
Strict Entity Isolation: Entities MUST live in domain/entities/, never in data/.

One Class Per File: Every file must contain exactly one public class.

Migration Rule: When modifying legacy features lacking full Clean Architecture (categories, staff), migrate them into the standard 3-layer structure as part of the PR.

7. Supabase & Database Integrity
   No Recursive Foreign Joins: Avoid deep recursive joins in queries. Use indexed, flat selects or delegate complex queries to Postgres RPC functions.

Column Name Verification: Verify exact schema column names before composing queries (e.g., distinguish staff_user_id from user_id).

Security Definer RPCs: For aggregations, complex stats, or multi-table mutations, use SECURITY DEFINER Postgres functions with SET search_path = public and SET row_security = off to eliminate PostgreSQL recursion errors.

One-Time Bootstrap Updates: Device and hardware state updates (e.g., geolocation, system metadata) must execute exactly once per session via a guarded bootstrap call.

Enforce RLS: Every accessed table MUST have Row Level Security enabled and verified. Never bypass RLS using the service role key on the client.

Mandatory Pagination: Queries expected to return > 50 rows must use .range(from, to) pagination.

Cache-First for Reference Data: Infrequently changing reference data (categories, roles, system flags) must be served from local cache first and refreshed in the background.

8. Dependency Injection (GetIt)
   Feature DI Modules: Each feature must register its dependencies via an isolated module file (e.g., auth_di.dart, shifts_di.dart).

Interface Registration: Always register implementations against their abstract contracts:

Dart
sl.registerLazySingleton<ShiftRepository>(() => ShiftRepositoryImpl(sl()));
Zero Dead Registrations: When removing or refactoring classes, immediately prune their registrations from DI containers.

9. Design Tokens & Component Reuse
   Strict Token Discipline: Colors, typography, spacing, border radii, and shadows must originate exclusively from AppColors and shared design tokens (art_core/theme/). Zero raw Color(0x...) or inline TextStyle in feature code.

Two-Occurrence Rule (UI): If any UI pattern, card, table row, badge, or modal appears in 2 or more places, it MUST be extracted to art_core/widgets/.

Standardized Controls: All buttons must use AppButton. All tabular data must use the shared core data-table component.

10. Error Handling & Result Pattern
    Unified Failure Hierarchy: All repositories must return Either<Failure, T> using standard Failure classes (core/error/failures.dart). Never return raw Strings or throw untyped exceptions into the domain layer.

Boundary Mapping: Data sources are the only layer catching raw exceptions (PostgrestException, SocketException, AuthException), converting them to concrete Failure models before reaching the repository.

Localized Failure Keys: Every Failure must contain a localization translation key, never a hardcoded English error string.

11. Logging & Observability
    No Production print(): Do not use print() or untagged debugPrint(). Use the centralized AppLogger with appropriate levels (info, warning, error).

Zero Sensitive Data Logging: Never log auth tokens, passwords, session secrets, or full PII payload objects.

Clean Commits: Strip all temporary debugging instrumentation before committing code.

12. Testing Requirements
    Usecase Testing: Every Usecase must have unit test coverage for success and failure paths using mocked repositories (mocktail/mockito).

Cubit State Testing: Every Cubit must have bloc_test suites covering full state transitions (initial → loading → success/failure).

Zero Network Tests: Tests must run fully offline using mocked data sources.

Component Testing: Shared widgets under art_core/widgets/ reused across 3+ features must include basic widget rendering tests.

13. Security & Environment Configuration
    No Hardcoded Secrets: Client keys (Supabase URL, Anon Key) must be injected via compile-time variables (--dart-define), never hardcoded in git.

Service Role Isolation: The Supabase service_role secret must NEVER exist in client-side code.

Client-Side Validation: All forms and payloads must pass client validation before dispatching mutations to the backend.

14. Naming Conventions
    Files: snake_case.dart reflecting the primary class name.

Classes: PascalCase with structural role suffix (*RepositoryImpl, *RemoteDataSource, *Usecase, *Cubit, *State).

Usecases: Verb-first, feature-scoped naming (e.g., ConfirmCashPayment, UpdateBookingStatus).

Self-Explanatory Identifiers: Avoid cryptic abbreviations. Variable and function names must denote explicit intent.

15. Problem Diagnosis Before Execution
    Root Cause First: Before touching code for any bug fix, verify whether the fault lies in Frontend state/routing or Backend RLS/Postgres schema via network traces and server logs.

Explicit Diagnostic Summaries: State the root cause clearly before proposing or applying code modifications.

16. Dependency Declaration Integrity
    Explicit Dependencies: Any package imported into code MUST be explicitly listed under dependencies or dev_dependencies in pubspec.yaml, never relied upon as a transitive artifact.

Documented Overrides: Any declaration inside dependency_overrides must contain an inline comment detailing the upstream conflict requiring it.

17. Single Responsibility, File Size & Self-Documenting Code
    17.1 Single Responsibility Principle (SRP)
    One Reason to Change: Classes, Cubits, functions, and widgets must fulfill a single distinct responsibility. If describing its function requires "and", decompose it.

Cubits Orchestrate, Not Implement: Cubits call use cases, map results, and emit states. They must contain zero data parsing, string formatting, or validation logic.

Widgets Render, Not Decide: Widget build() methods must not contain business logic or raw data transformations. Compute presentation data inside the State or Entity getters.

Extract Over Flags: Do not add boolean switch parameters to alter a function's core operation. Create distinct, dedicated functions instead.

17.2 Size Constraints & Decomposition
Method Length: Target ~25 lines; hard cap at 40 lines (excluding braces and switch statements).

File Length: Target < 200 lines; hard cap at 300 lines (excluding imports and .g.dart/.freezed.dart generated sections).

Widget Tree Decomposition: Any build() method exceeding 60–80 lines or nesting deeper than 4 levels MUST be extracted into named private StatelessWidget classes (class _ItemCard extends StatelessWidget), not private helper methods (Widget _buildCard()).

One Class Per File Absolute: Every model, state, and utility class requires its own file. Private enums are the only exception if strictly used within that file.

17.3 Self-Documenting Code Standards
Rename Instead of Comment: Replace explanatory comments by extracting logic into descriptively named variables and functions (e.g., extract an if expression to bool canUserCancelBooking(Booking b)).

No Code-Restating Comments: Comments simply rephrasing syntax are forbidden.

Permitted Comments (Narrow Exceptions):

Non-obvious regular expressions (with sample inputs/outputs).

Upstream bug workarounds (citing issue tracking URLs).

Required copyright/license notices.

Line-specific // ignore: lint_rule_name declarations paired with a justification.

No Dead Code: Commented-out code and untracked // TODO items are strictly prohibited.

17.4 DRY Logic & Project-Wide Consistency
Two-Occurrence Rule (Logic): If non-trivial logic (validation, transformations, currency math) appears in 2 places, extract it to core/utils/.

Universal Domain Vocabulary: Maintain identical naming for domain concepts across the application (e.g., standardise on loungeId across all files; do not mix lounge_id and currentLoungeId).

Zero Parallel Implementations: Check for existing use cases, utilities, and RPC wrappers before writing new ones.

17.5 Readability & Control Flow
Guard Clauses: Use early returns to maintain shallow indent levels. Nesting depth must not exceed 3 levels.

No Parameter Soup: Functions requiring > 2 boolean arguments must be refactored to use a configuration class or an enum.

Positive Boolean Naming: Name boolean properties for what true represents (e.g., isEnabled, never isNotDisabled).

18. Cross-Repository Alignment
    The Web Dashboard is the reference benchmark for Clean Architecture completeness, Either<Failure, T> error modeling, and strict Design Token usage.

Keep domain contracts, usecase interfaces, and failure classes synchronized in lockstep with the companion Mobile App repository.