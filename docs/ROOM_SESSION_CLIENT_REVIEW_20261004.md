# Room/session client verification — 2026-10-04

The server now rejects changes that free or place an active room under maintenance, session starts in unavailable rooms, and simultaneous starts in the same room. Dashboard room and booking repositories map these denials to safe Arabic/English messages; status permission failures and unexpected database errors no longer expose raw SQL details through the room-state flow. Booking Cubit resolves mapped error keys in the active locale before existing action widgets display them.

Five client regressions prove denied room updates remain failures, cannot turn into cached success, and both session-start guard codes preserve their rejection. Full offline suite passed 947 tests (`--exclude-tags live --concurrency=2`, 75s). Live-tagged tests remain excluded locally. Analyzer passed with informational lints only; release build results are recorded in the task logs and GitHub CI. New translations were added to both catalogs.

The canonical backend commit contains the newly deployed migration, 12 sequential native checks and three concurrent transaction tests. Concurrent losers waited approximately 1.52s and received 55000. These fixture transitions exercise the actual guard functions against PostgreSQL; they do not duplicate all hosted payment/hold/loyalty triggers or pretend real financial activity was submitted.

No hosted session or room was mutated for testing. Screenshots from the preceding audit/responsive phase remain in the task workspace. Mobile application/emulator has not been launched concurrently. Original project directories and unrelated Mobile generated/cache changes remain untouched.

Release web build succeeded in 102.0s. Pre-brace-cleanup analyzer found 54 informational lints, zero warnings/errors; the two newly introduced brace lints were fixed. Exact published head is verified by GitHub CI.
