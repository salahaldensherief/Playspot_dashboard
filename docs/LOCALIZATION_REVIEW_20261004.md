# Dashboard localization review — 2026-10-04

## Completed slice

Localized fixed labels in 25 components across bookings, customer cancellation history, receipts, room discounts, room features, canteen combos and suggestions, pricing, marketing, announcements, maintenance and tournament audit screens. Arabic and English resources include parameterized announcement previews; customer-authored text remains unchanged. Currency display was localized without changing financial payload currency codes.

Verification: `flutter test --no-pub --exclude-tags live --reporter compact` passed **867 tests**. Live-tagged database tests were excluded explicitly. `flutter analyze --no-pub --no-fatal-infos` passed with 51 informational lints and no errors or warnings. Changed Dart files were formatted; repository-wide read-only format checking reports existing formatting drift and does not modify unrelated files.

## Remaining review

## Conditional and parameterized labels

The next slice covers 42 components: booking references, grace periods, customer cancellation details, receipt methods, room/session status, occupancy counts, financial discount summaries, canteen savings and suggestion rules, localized day labels, promotion validation, pricing scope/conflicts, shift actions, tournament events and moderation context. Resource values use parameters for user content and numbers; weekday indices and backend identifiers remain unchanged.

The pricing preview header now wraps its legend under narrow constraints. Maintenance notices select the server-provided message for the current language, with an alternate-language fallback only when the preferred message is empty. Twenty widget tests verify these widgets in Arabic and English at 360, 600, 768, 1024 and 1440 with text scale 1.6.

Verification after this slice: **887 offline tests passed**; live-tagged tests explicitly excluded. Full analyze passed with 52 informational lints, no errors or warnings. Release web build succeeded in 102.2 seconds. Whole-repository read-only formatting reports 369 pre-existing files needing formatting; no bulk formatting was applied.

CI for the first localization slice (`05841c3`) passed in run 37162920622.

## Still outstanding

The broader scan finds additional conditional and parameterized messages, feature Cubit messages, day labels and some raw backend errors. This slice does not claim complete localization. Browser screenshots must come from a rebuilt release before being used as evidence for these new translations. Customer warning submission also needs contract review: the existing dialog currently reports success without performing a request.

The permission bootstrap fix preceding this slice is verified by nine regression tests and successful CI run 37161841542 for c61e2b1. Protected routes retain local deep links and wait for access scoped to the current actor and lounge; duplicate shell initializers share requests.
