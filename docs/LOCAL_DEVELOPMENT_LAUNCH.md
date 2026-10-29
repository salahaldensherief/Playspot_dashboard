# Local Dashboard launch on Windows

## Choose an explicit IDE profile

Both VS Code/Antigravity (`.vscode/launch.json`) and Android Studio/IntelliJ (`.run/*.run.xml`) now offer:

- **PlaySpot - OFFLINE equipment preview (Chrome)**: `tool/equipment_cards_preview.dart`, synthetic rooms and fake Cubits only. No Supabase initialization, credentials, Auth, repository setup or hosted RPCs. Translation JSON, SVGs and fonts are local bundled assets. This is the safe profile to inspect equipment cards immediately. The clock is frozen; actions are synthetic and close fails intentionally. It is not real cashier, realtime or authenticated acceptance.
- **PlaySpot - Local backend (Chrome, explicit config)**: `lib/main.dart` with `--dart-define-from-file=.env.local.json`. This does not silently select the existing Demo or Staging project. The profile requires a separately authorized development target and matching public client key. The name means a local Dashboard process, not a claim that its backend is local. The current validator accepts explicitly configured HTTPS Supabase development projects only.

The original Chrome/Edge profiles and Android Studio `main.dart` configuration are preserved. Running plain `main.dart` does not supply compile-time values; the existing setupInjection fail-closed check remains unchanged. Use the named profile rather than the generic current-file Run action.

## Connected configuration remains deliberately incomplete

A blank `.env.local.json` is prepared locally and ignored by Git through `.env*`. The committed `config/local-defines.example.json` contains only empty fields; it can be copied to that ignored path on another machine. Fill `SUPABASE_URL` and `SUPABASE_ANON_KEY` only after the owner explicitly authorizes the particular target. Never copy a service-role/secret key. Do not paste keys into launch.json, run XML, terminal arguments or chat. No environment values are committed in IDE files.

Existing `.env`/`.env.demo` settings are preserved and are not imported into the new profiles. Their presence is not authorization to use their target. No connected application was launched for this configuration fix.

Before any connected launch, run from the repository root:

```powershell
./scripts/launch_local.ps1 -Environment Development -ConfigFile .env.local.json -ValidateOnly
```

Validation is entirely local: required fields, URL/project restrictions, key format, legacy anon role/project claims. An opaque publishable key cannot be matched to a project or cryptographically verified offline. Successful validation is not proof of a working key, deployed schema, Auth, RLS or finance. Production is rejected, and Development rejects the known demo project. VS Code runs this validator automatically as a pre-launch task. For Android Studio/IntelliJ run it manually before the connected profile; that IDE's existing before-run tools were not changed.

After explicit authorization, the CLI alternative is the same command without `-ValidateOnly`; it passes only the two public settings in a temporary JSON file and deletes it on exit. `-Device edge` is supported. `-Environment Demo` remains an explicit legacy opt-in only, not authorized by this task. The old demo schema is not a financial acceptance environment. Do not run any connected profile in the current checkpoint.

## Offline preview CLI and checks

```powershell
flutter run -d chrome --no-pub -t tool/equipment_cards_preview.dart
# Headless local server alternative:
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 51641 --no-pub -t tool/equipment_cards_preview.dart
```

The preview accepts local query parameters such as `?lang=en`, `?lang=ar&stations=40`, `?stale=true`, `?loading=true` and `?operational=true`. These switch synthetic rendering only.

Configuration regression checks: `powershell.exe -NoProfile -NonInteractive -File scripts/test_launch_local.ps1`: **10 passed**, with HTTP blocked in the test and only synthetic values. Covers missing fields, Production, accidental Demo selection, privileged keys, mismatched legacy anon, valid synthetic anon/publishable, malformed publishable and redacted malformed JSON. The selected blank local configuration was checked and rejects missing fields as intended. Both launch JSON and shared run XML parse successfully. `lib/core/di/di.dart` and environment constants are unchanged; no dependency upgraded.

Equipment widget checks: `flutter test --no-pub test/features/bookings/room_equipment_card_test.dart`: **11 passed**. Build and local-server results for this checkpoint are recorded below after completion. No hosted runtime, browser interaction or authenticated acceptance should be inferred from compilation/server readiness.

Official references: [Dart Code launch configuration](https://dartcode.org/docs/launch-configuration/) (`program`, `deviceId`, Flutter `toolArgs`), [Supabase key types](https://supabase.com/docs/guides/getting-started/api-keys). Only public/publishable or legacy anon keys belong in Flutter; secret/service-role keys do not.

Final local results (30 October 2026): offline entry point release Web build succeeded in 73.6s; existing optional Wasm warnings in audioplayers/get_storage remain, not a dependency upgrade or default Web failure. Debug `web-server` launched the same entry point in 49.8s on `127.0.0.1:51641`; local HTTP GET returned 200. The server remains running for inspection. This establishes compilation and serving, not browser-rendered/interaction or authenticated acceptance. `flutter analyze --no-pub --no-fatal-infos`: no issues (13.6s). `dart format --output=none --set-exit-if-changed tool/equipment_cards_preview.dart`: zero changes. Existing VS Code configurations compared structurally equal; original IntelliJ main.dart and .env/.env.demo were untouched. git check-ignore confirms .env.local.json ignored. No connected runtime, hosted request, push or deployment performed. Raw build/test/analyze logs are in the task workspace outputs/ide-*.log.
