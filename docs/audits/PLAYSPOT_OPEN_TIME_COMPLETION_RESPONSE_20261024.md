# Dashboard Open Time completion response — 24 October 2026

The cashier's `completeOpenTimeSession` call goes from booking/occupancy controls through `BookingCubit`, repository and `BookingRemoteDataSourceImpl` to `complete_booking_session(p_booking_id, p_action_by)`. Two UI call sites treated any non-null map as a successful close. Previously the data source accepted a map even if it contained `success: false`, another booking ID, or `status: in_progress`, so the cashier could see a success snackbar without confirmed completion.

The data source now rejects those responses before they reach any widget. The focused mock-HTTP regression covers the requested booking/parameters, confirmed success, explicit failure, wrong booking ID, wrong status and wrong shape. This is a client response-integrity fix only; it does not alter server transactions, prices, payments or grants.

Local verification: Flutter 3.44.1, focused `flutter test` PASS (5 cases), `flutter analyze --no-fatal-infos` PASS (no issues), `dart format` made no changes. The first mock test attempt failed because the fixture omitted `http.Response.request`; after correcting the fixture all cases passed. Vercel project `playspot-dashboard` showed ready `dev` and feature deployments with `target: null` (Preview) before branch push. No deployment was initiated manually. Full PR CI and its Vercel Preview must be checked against the final SHA.

Deployed financial contract verification remains blocked as documented in Mobile Draft PR #79, and Mobile financial PR #75 remains Draft.
