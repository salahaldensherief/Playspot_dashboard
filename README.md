# PlaySpot Dashboard

Flutter Web operations dashboard for PlaySpot. It is used by authorized platform and lounge operators to manage lounges, rooms, bookings, shifts, staff, permissions, users, payouts, loyalty, marketing, reviews, support, system controls, and tournaments.

## Stack

- Flutter Web / Dart
- flutter_bloc / Cubit
- GetIt
- GoRouter
- Supabase Auth, Postgres, Storage, Realtime, RPCs
- Easy Localization
- ScreenUtil

## Architecture

Dashboard features live under `lib/features/<feature>/` and use data/domain/presentation boundaries where applicable.

```
feature/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    cubit/
    screens/
    widgets/
```

Shared dependency injection, routing, services, error handling, responsive helpers, and utilities live under `lib/core/`.

The dashboard is an operations client, not the security boundary. Privileged actions must be authorized by Postgres/RLS/RPC logic. UI permission checks are for presentation only and must not replace server-side authorization.

Agent engineering rules start in `AGENTS.md`; `AGENT_RULES.md` contains additional conventions.

## Configuration

Supply Supabase configuration at build/run time. Real project keys are not committed as defaults.

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-publishable-or-anon-key
```

For a production web build:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-publishable-or-anon-key
```

See `.env.example` for variable names. Flutter consumes these as dart defines.

## Local development

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
```

## Supabase and privileged operations

Database and RPC changes are versioned under `supabase/`. Do not replay the whole directory against production.

The deployed Supabase migration ledger and historical SQL files are not assumed to be synchronized. For every backend change:

1. inspect the live schema/function first,
2. create a focused reviewed migration,
3. preserve RLS and explicit grants,
4. verify SECURITY DEFINER functions perform their own authorization,
5. avoid direct table-write fallbacks for privileged lifecycle actions,
6. test the operation through the same role the dashboard uses,
7. run Supabase security/performance advisors after deployment.

Never place `service_role` or secret server keys in the web client.

## Branch and PR workflow

- `main`: release/production history.
- `dev`: integration branch.
- Work branches: `feature/*`, `fix/*`, `chore/*`.
- Use PRs for all feature, schema, permission, and lifecycle changes.
- Keep dashboard changes aligned with the mobile/backend contract when both consume the same RPC or table model.
- Do not merge until CI is green and database migrations have been reviewed independently.

See `CONTRIBUTING.md`.

## CI

GitHub Actions checks formatting, analysis, and tests on pull requests and pushes to `dev` / `main`.

## Localization and layout

User-facing text must be localized. Dashboard changes must remain usable in Arabic/English and RTL/LTR layouts.
