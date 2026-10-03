# Dashboard localization review — 2026-10-04

## Completed slice

Localized fixed labels in 25 components across bookings, customer cancellation history, receipts, room discounts, room features, canteen combos and suggestions, pricing, marketing, announcements, maintenance and tournament audit screens. Arabic and English resources include parameterized announcement previews; customer-authored text remains unchanged. Currency display was localized without changing financial payload currency codes.

Verification: `flutter test --no-pub --exclude-tags live --reporter compact` passed **867 tests**. Live-tagged database tests were excluded explicitly. `flutter analyze --no-pub --no-fatal-infos` passed with 51 informational lints and no errors or warnings. Changed Dart files were formatted; repository-wide read-only format checking reports existing formatting drift and does not modify unrelated files.

## Remaining review

The broader scan finds additional conditional and parameterized messages, feature Cubit messages, day labels and some raw backend errors. This slice does not claim complete localization. Browser screenshots must come from a rebuilt release before being used as evidence for these new translations. Customer warning submission also needs contract review: the existing dialog currently reports success without performing a request.

The permission bootstrap fix preceding this slice is verified by nine regression tests and successful CI run 37161841542 for c61e2b1. Protected routes retain local deep links and wait for access scoped to the current actor and lounge; duplicate shell initializers share requests.
