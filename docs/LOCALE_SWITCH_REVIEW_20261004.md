# Mounted-page locale switching — 2026-10-04

## Reproduced defect

On the running super-admin KYC page, changing English to Arabic changed the sidebar, app bar and direction, but the page title, description and empty state remained English. Translation resources existed. These widgets called context-free `AppStrings` getters or `tr()` and did not subscribe to the localization provider, so retained route widgets did not rebuild when the locale changed.

## Fix

Localized widgets lacking any existing locale dependency now subscribe with `EasyLocalization.of(context)` in `build`. This is the package's inherited dependency API and tolerates isolated hosts without a localization provider. The change adds no navigation refresh, keys, fetches, Cubit recreation or request retries. Imports for Dart parts remain in their owning library. Redundant `intl` imports were removed where the localization import already provides their symbols.

The change covers 271 existing widget files with small dependency/import edits; it does not claim to translate every remaining literal. Existing widgets that already read `context.locale` were retained. The router and business state remain intact.

## Verification

- Regression test retains the same mounted KYC element, changes locale, verifies the title and empty state update, and verifies review loading runs once.
- Full offline suite: **896 passed**; live-tagged database tests excluded.
- Full analyze: successful, **50 informational lints**, no errors or warnings.
- Release web build: successful, **73.2 seconds**.
- Whole-repository read-only formatter: 1011 files checked, 368 existing files would change; no mass reformat applied.
- Actual browser: English → Arabic and Arabic → English KYC screenshots verified. Switching back to Arabic triggered **zero review reloads and zero permission reloads**. Page-error capture remained empty.

Local screenshot evidence: `kyc-locale-fixed-switched-en.png` and `kyc-locale-fixed-switched-ar.png` in the review workspace. These measurements prove this language-switch flow preserves data loading; they are not a full dashboard performance profile.

Earlier moderation correction `3a396f1` passed CI run 37164943416. Earlier conditional localization `c680a7e` passed CI run 37164016563.
