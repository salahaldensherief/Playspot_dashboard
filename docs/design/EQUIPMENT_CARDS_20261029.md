# Equipment room cards — 29 October 2026

## Decision and research

Use original static SVG compositions rendered by the existing flutter_svg 2.3.0 dependency, with native Flutter names/status/timers/amounts/actions. Seven artwork files total 9,187 bytes before compression. No new dependency, 3D engine, remote art request or decorative animation added. Vector cache keys are stable asset paths; RepaintBoundary isolates artwork. SessionClockHost supplies a shared clock to RoomOccupancyGrid, while SessionTimeBuilder updates timer subtrees. No frame-rate/performance benchmark was performed.

| Approach | Capabilities / licensing | Assessment |
| --- | --- | --- |
| Layered SVG + Flutter | [flutter_svg documentation](https://pub.dev/packages/flutter_svg), [MIT license](https://pub.dev/packages/flutter_svg/versions/2.3.0/license); supports Flutter Web, asset loading, placeholder/error widgets | Selected: existing dependency, small resolution-independent assets, easy source review/recoloring, no animation runtime |
| Transparent raster + Flutter | Flutter Image assets support transparent formats; each image needs independently verified art rights | Suitable for photographic detail, but more resolution variants and bytes than these simple vector scenes; not adopted |
| Rive | [official runtime/license](https://pub.dev/packages/rive/license), [platform considerations](https://github.com/rive-app/rive-flutter/blob/master/platform_considerations.md); runtime MIT, individual artwork licenses separate | Interactive state machines can help real operational animations, but no such requirement here; extra native/Web WASM runtime not justified |
| Lottie | [package documentation](https://pub.dev/packages/lottie), [license](https://pub.dev/packages/lottie/license); Web supported; animation file rights separate from player | Useful for bounded operational feedback, unnecessary for static equipment on a dense grid |
| Reusable stock SVG | [SVG Repo licensing](https://www.svgrepo.com/page/licensing/) varies by individual asset | No external stock adopted; original equipment geometry avoids mixed licenses/style and branding |

Original art provenance is in assets/equipment/PROVENANCE.md. The owner screenshot was a direction reference only, not an art source. No artwork/text/branding was extracted. The design preserves PlaySpot's existing theme, AppText, AppButton, status semantics, dialogs and cashier RPC paths.

## Actual model and implementation scope

RoomEntity.resourceType derives from selected activity categories; known editor categories include console, pc, vr, simulator, table_sport, board_game, arcade, entertainment and other. Mixed/unknown gets neutral equipment. Only explicit activity names under table_sport distinguish billiards and table tennis. VIP is a separate spaceType (vip/vip_room), represented by a restrained room backdrop rather than a fabricated device. No classification from customer-provided room names.

Changes target the existing RoomOccupancyCard/RoomOccupancyGrid, not the separate CashierSessionsWorkspace layout or the whole Dashboard. Available, occupied and maintenance are actual room statuses. isAvailable=false blocks the available booking UI. There is no room paused enum, so no paused controls or fake reserved state were introduced.

Cards show equipment art, localized room names, text/icon status, applicable screen/controller facts, existing rates/session facts, and existing actions. Open Time uses elapsed time and a finalization notice; fixed sessions use remaining time. No progress bar is invented for Open Time. Existing total amounts are not relabeled as collected/due. Session close still uses the existing canonical close and does not collect payment.

Grid density derives from available width (target 320px, max 6 columns, 16px gaps). Long names use existing truncation; customer/money facts and controls can wrap/stack. Text labels/icons accompany state colors. AppButton preserves focus/keyboard/disabled behavior. During room refresh/failure, cards show loading/stale feedback and block pointer/focus actions; grid provides room refresh retry. Missing/unknown artwork has a neutral fallback. Permission and business contracts remain server-owned.

## Fixture and checks

`tool/equipment_cards_preview.dart` renders the actual room cards with synthetic Cubits/rooms/bookings only; no Auth/DI/Supabase initialization or hosted calls. Its failed-close handler deliberately returns no receipt and exposes an error. Its clock is frozen at a documented synthetic instant for deterministic screenshots, not live-realtime acceptance. Run locally:

`flutter run -d web-server --no-pub --web-hostname=127.0.0.1 --web-port=51631 --target=tool/equipment_cards_preview.dart`

Use `?lang=ar&stations=20`, `?lang=en&stations=40`, `?stale=true` or `?loading=true`. These flags affect the fixture only.

Focused tests load the project's Tajawal/Material icon fonts and preload SVGs before snapshots. Test asset-manifest caching after rename was resolved by registering the dedicated equipment asset directory; a missing asset must not be hidden by a placeholder screenshot.

Eight focused tests passed: structured type/fallback mapping; AR/EN at widths390/1440 (narrow text scale1.4), failed close error and RTL/LTR assertions; 6/20/40 rooms with stale action/focus blocking. Screenshots are Flutter golden captures of implemented widgets, not browser screenshots: test/features/bookings/goldens/equipment_{ar,en}_{390,1440}.png. Visual review caught the status badge inheriting desktop-scaled typography on narrow screens; its font now uses 11 logical pixels with normal accessibility scaling.

Verification commands (local Flutter environment):

- `flutter test --no-pub --update-goldens test/features/bookings/room_equipment_card_test.dart`: 8 passed; reviewed actual rendered AR/EN captures. Golden updates are reference generation, not independent screenshot approval.
- `flutter test --no-pub test/features/bookings/room_equipment_card_test.dart`: matching-reference confirmation, 8 passed before the final status-font correction; full-suite rerun below covers the corrected captures.
- `flutter test --no-pub`: 1,348 passed, 2 skipped.
- `flutter analyze --no-pub --no-fatal-infos`: no issues.
- `dart format --output=none --set-exit-if-changed lib test tool/equipment_cards_preview.dart`: 1,124 files, zero changes.
- `flutter build web --release --no-pub`: succeeded in 113.6s, main application release build (not the synthetic fixture). The optional Wasm dry run reports existing audioplayers_web/get_storage dart:html/package:js incompatibilities; this validates the default Web build, not Wasm compatibility.

Raw logs are preserved in the task workspace's sibling `outputs/equipment-*.log` files. Local fixture server responds on port 51631; HTTP availability is not browser acceptance. No CI was triggered because no remote changes were made.

Browser verification is blocked by Computer Use's local kernel asset setup failure. No actual browser interaction, hosted Auth, realtime reconnection, physical device connectivity, cashier success or performance acceptance claimed. The existing mutation/dialog implementation is preserved; successful hosted operations need separately authorized integration testing.

## Delivery boundary

Integrate locally only after checks. Existing Vercel Git integration couples Dashboard dev push to Preview deployment. No deployment authorized, so no remote push, PR mutation or deployment in this task. Preserve other dirty worktrees and generated registrants. Financial branches and production/staging data remain untouched.

## Focused refinement after e1363452

The read-only `git ls-remote origin refs/heads/dev` returned e13634524b91250275a459bb567d94af80109790, independently confirming the actual remote head. GitHub commit status reports Vercel deployment completed at https://vercel.com/salaheldindev11-6746s-projects/playspot-dashboard/5DMCc9XFvo9yEsTdmcq7EjsEwtgn. This does not establish who pushed the earlier commit or backend compatibility. The new work stays local pending separate authorization for a dev push's coupled Preview deployment. No deployment settings or protections were disabled.

The actual application path is BookingsPage -> BookingsCollapsibleOccupancy (devices/rooms map) -> RoomOccupancyGrid -> RoomOccupancyCard. The map starts collapsed on mobile. The separate CashierSessionsWorkspace remains unchanged. The fixture now also supports `?operational=true` to render that actual collapsible map/grid with synthetic Cubits; this is not an authenticated BookingsPage acceptance test.

RoomSessionTimer now renders native tabular timer text inside the console/PC screen using the SVG viewBox. Other equipment gets the same timer on a dark foreground panel. Above 1.25 text scale, the timer expands below artwork with natural height. Open Time explicitly says elapsed; fixed sessions show signed remaining time, including negative remaining time during the existing grace period. Alert/grace, authoritative timestamps, pricing and close callbacks remain unchanged. Missing walk-in timestamps never produce a fabricated timer. Artwork retains a repaint boundary separate from ticking text. A shared clock updates timer subtrees, not the grid.

RoomCardsLayout uses 300px target columns, maximum six, and 12px gaps. A small row render object measures actual children then supplies a shared minimum height; it does not constrain maximum height. IntrinsicHeight was rejected because existing controls use LayoutBuilder. An intermediate tight-height attempt exposed refresh overflows; final loading/failure/keyboard tests cover the corrected minimum-height layout. Header/artwork origins and bottom primary actions align while text can grow. Secondary booking/details controls precede the bottom primary action. This intentionally changes the former action-order assertion; hit area/readability/rate assertions remain intact.

Names may occupy two lines; status retains text/icon/color; total/finalization is visually stronger than customer/equipment details. Booking.totalPrice remains booking total; collected and due explicitly show the existing unavailable label because Booking does not carry authoritative values for them. No amounts are inferred from partial/paid state. End & Calculate uses the original close operation and never collects money. Ambient/rim artwork lighting is consistent across seven original assets, now 12,624 bytes total. No new dependency/animation.

### Inspected captures and actual checks

Before captures were preserved in task outputs/equipment-before before editing. After captures are the four equipment_{ar,en}_{390,1440}.png references. These are actual Flutter widget captures with synthetic names/amounts and a frozen clock, not browser screenshots. AR wide and EN narrow captures were visually inspected after the final layout/lighting changes; earlier intermediate images were inspected and replaced after fixing concrete defects. Narrow references use text scale 1.4; operational interaction tests exercise 1.6.

- Focused equipment suite: 11 passed without --update-goldens after reference inspection. Covers type mapping, both languages/directions, 6/20/40 rooms, stale blocking, actual operational map, keyboard close failure, loading/unfocus, retry, equal row heights and clock-driven elapsed/remaining/overdue values.
- Full `flutter test --no-pub`: 1,351 passed, 2 skipped. An initial full run failed six assertions expecting the former quick/detailed order; only that ordering assertion was updated to the intended bottom-primary layout, then the complete suite passed.
- `flutter analyze --no-pub --no-fatal-infos`: no issues (67.0s).
- `dart format --output=none --set-exit-if-changed lib test tool/equipment_cards_preview.dart`: 1,126 files, zero changes.
- `flutter build web --release --no-pub`: main application built successfully (159.6s); existing optional Wasm incompatibility warnings remain.

Read-only GitHub inspection found the earlier e1363452 quality job failed: 1,344 passed / 4 failed / 2 skipped. Authenticated log inspection confirmed exactly the four equipment golden comparisons failed on Linux (2.99–7.83% pixel difference). See https://github.com/salahaldensherief/Playspot_dashboard/actions/runs/40890947005/job/123507262138. Flutter documents platform/version-dependent font rasterization at https://api.flutter.dev/flutter/flutter_test/LocalFileComparator-class.html. The new CI uses a Windows equipment-visuals job pinned to the reference Flutter 3.44.1; quality depends on it. Only pixel comparison runs on Windows; all behavior/layout/error assertions run on every host. No tolerance was widened and no test was disabled. The new remote CI has not run because this refinement has not been pushed.

Browser evidence remains limited: cua_repl failed local kernel setup; the subsequently available Windows Computer Use API listed/launched Chrome, but no stable Chrome window remained available for capture. No browser rendering, successful real cashier operation, authenticated session, realtime reconnect or performance acceptance is claimed. The user can inspect the synthetic operational map independently; hosted staging and production were not accessed.
