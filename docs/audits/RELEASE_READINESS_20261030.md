# Release-readiness checkpoint — 30 October 2026

## Current source and delivery boundary

Read-only `git ls-remote origin refs/heads/dev` independently returned Dashboard 200d995f7a3a87ce5163f5ae2119a61acc154d35. Local dev fast-forwarded normally to d9121a4c24d4cd9fe5c600bd122cc32f1196fc7a; no conflicts, reset, rebase or discarded work. The named IDE launch configurations and ignored blank .env.local.json are preserved. Launch validation tests reran: 10 passed; combined equipment tests before the new change: 11 passed. The existing Vercel Git integration couples dev pushes to Preview. Current authorization excludes deployment, so no remote push was attempted and protections/settings were not changed.

## Confirmed operational-screen defect

BookingsPage lines 285–288 mounts BookingsCollapsibleOccupancy -> RoomOccupancyGrid. That real grid rebuilt only on booking-list changes and propagated RoomState freshness alone. BookingCubit.startWatchingBookings explicitly preserves its list on same-scope reload and watch error while emitting loading/failure. Thus a status-only booking stream failure left session controls interactive even though current occupancy could not be confirmed.

The grid now observes booking status as well, disables/focus-excludes card actions during initial/loading/failure, and uses the existing visible loading/stale indicators. Retry refreshes each failed source, including a forced booking watch on the current lounge. Returning to success restores actions. Fixtures explicitly represent a successfully loaded booking list. Tests on the actual operational component cover retained lists, loading, failed close suppression, retry and recovery at narrow/enlarged and wide layouts. No pricing, permission, RPC, financial classification or collection behavior changed.

## Complete local backend feasibility

Read-only inventory: Docker CLI exists and selects desktop-linux; Docker Server connection fails because dockerDesktopLinuxEngine pipe is absent; WSL docker-desktop is Stopped. The preserved original backup D:/CodexBackups/Docker/codex-docker-original.vhdx is present (15,799,943,168 bytes). Active local Docker VHDX files also exist. No daemon start, disk attach, prune, reset, context change, storage migration or file modification was attempted. Starting the existing engine may mount/write these disks and is outside this task's storage-preservation boundary.

The existing local PostgreSQL 17.11 fixture cluster and schema-only export are preserved. The 1,342,424-byte playspot_schema_20261025.sql and historical catalog fingerprints remain available in the task financial-schema-local directory. These do not constitute a runnable Supabase stack. No complete local Auth/API stack or root Supabase local config/Compose project was found in the inspected Mobile repository, PlaySpotWork, PlaySpotDemoRuntime or PlaySpotBackendAudit inventory; function-specific config.toml files are not a stack configuration. Private demo material was not imported and no hosted service was contacted.

The immediate prerequisite is a running Linux container engine with a separately isolated empty storage location/context, preserving the existing Docker disks/backups. Then prepare a new local-only Supabase project with loopback ports, Auth/API/Realtime/Storage, review the existing schema and Draft migration ordering against that stack, seed only synthetic Auth/users/venues and verify grants/RLS before populating the ignored client configuration with its local public key. Current launch validator accepts only explicit hosted HTTPS development project URLs; loopback support must be added and tested once that local API exists, rather than bypassing it with a hosted project or fake URL now. No claim of compatibility or successful Auth is made.

## Evidence levels and remaining release blockers

| Gate | Current evidence / next step |
| --- | --- |
| Launch configuration | Offline validation and compile/serve evidence; connected file remains blank. |
| Operational UI | Real application widget path and widget interactions using synthetic Cubits; no full authenticated BookingsPage/browser acceptance. |
| Financial backend | Previous isolated PostgreSQL 17.11 results preserved: refund 35, payout reconciliation 35, custody 17, partial collection 47. Not rerun as proof of hosted schema compatibility. Refund/payout branches remain unmerged. |
| Native operations | Test-only recovery a9dd3309 retained independently atop Mobile dev; previous synthetic writer/renewal/reconciliation checks are not hardware or Auth acceptance. |
| Authenticated E2E | Blocked on complete isolated backend, reviewed schema/migration order, synthetic identity/permission setup and same-backend clients. |
| Migration ledger | Independent schema/function/grant/RLS and ledger reconciliation remain unavailable. Eleven alleged manual migrations are unverified; no missing ledger report fabricated. |
| Delivery | Dashboard local dev integration only; Preview deployment excluded by current authorization. Production/Staging/migrations/main/store untouched. |
| Mobile release | Signing, installed-device behavior, privacy/deletion and actual backend acceptance remain open. |

Original dirty Mobile AGENTS.md and ANTIGRAVITY_FINAL_CODEX_HANDOFF.md hashes still match the preserved checkpoint (6145A21E… and CCE287B9…). Existing financial worktrees, generated edits, clusters and recovery assets are untouched.

Current backend rerun attempt: Node fixture_session_clock.test.mjs exited 1 before assertions with ECONNREFUSED 127.0.0.1:55499; the PostgreSQL fixture listener is currently unavailable. No existing cluster was started/rebuilt/modified. The independent Mobile test patch stays on test/native-fixture-recovery-dev-20261030 at a9dd3309, not merged into Mobile dev. The previous statement that the cluster was left running is historical, not its current state.

New operational-grid focused run: 11 passed without golden regeneration, including both narrow text-scale 1.6 and wide status-only failure/recovery interactions. This is widget rendering with synthetic Cubits on the actual operational component, not authenticated end-to-end evidence.

Final client checks: flutter test --no-pub: 1,351 passed / 2 skipped, exit 0. flutter analyze --no-pub --no-fatal-infos: no issues, exit 0 (233.6s). dart format on all three touched Dart files: zero changes. git diff --check passed. The first release-build invocation produced no progress output and was interrupted; a separate verbose release build is being used to obtain actual final build evidence, not counted as success until completion. No golden references changed. Raw logs: task outputs/readiness-*.log.

Final release build completed: flutter --verbose build web --release --no-pub built the main lib/main.dart application successfully in 97.5s, exit 0. Existing optional Wasm compatibility warnings remain; default Web build passed. This is compilation only, with no connected runtime. Final evidence is outputs/readiness-main-build-diagnostic.log. All changes are ready for local dev integration; remote delivery is held solely at the existing Preview deployment boundary and still needs remote CI when a push is authorized without violating that boundary.

## Isolated runtime continuation

A new WSL distribution PlaySpotAcceptance20261030 was imported into D:/PlaySpotIsolated20261030/wsl from a checksum-verified Ubuntu Base 24.04.5 image. Docker Engine 29.1.3 runs inside it with daemon ID a5425fa1-5622-4997-8e86-a80a06cec53d, data root /var/lib/playspot-docker and managed containerd root under that directory. The old docker-desktop distribution remains stopped; no context-only isolation claim, old-disk attach/reset, or host virtualization/security change. Pinned CLI 2.122.0 and internal-network config are in Mobile branch feat/local-supabase-acceptance-20261030, commit a82aaf01, tooling/local-supabase. Images are being acquired; service bindings, managed baseline and authenticated acceptance are still pending. Existing fixture clusters were not modified.

The new explicit loopback Dashboard profile targets API http://127.0.0.1:56621 and ignored .env.isolated.json, with a separate Local validator mode. 21 offline synthetic validation checks passed; hosted guards remain. The corresponding Mobile opt-in avoids Firebase/push/font initialization and validates the same endpoint. Mobile 629 passed / 1 skipped; touched-file analysis no issues; release Web build passed 127.2s with local engine resources. This is client preparation, not connected-runtime evidence.

Historical payout counts are reconciled: verification-payout/refund_aware_payout_reconciliation and restack logs contain 32 PASS lines and passed:32. Later rc-backend and refinement-backend logs contain 35 PASS lines and passed:35. Commit aa8628f4262f198e79f158399fae20d1b9221c7b added three serialization scenarios (both refund/payout commit orders, plus payout waiting for executed reversal). The canonical tooling/suite-count-evidence.json hashes each log. Historical reports retain their dated result; the latest 35 is not a contradiction or a fresh E2E run. No test was edited to match a number.
