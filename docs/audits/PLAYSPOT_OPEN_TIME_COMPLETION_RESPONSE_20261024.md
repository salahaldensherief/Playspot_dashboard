# Dashboard Open Time completion response — 24 October 2026

The cashier's `completeOpenTimeSession` call goes from booking/occupancy controls through `BookingCubit`, repository and `BookingRemoteDataSourceImpl` to `complete_booking_session(p_booking_id, p_action_by)`. Two UI call sites treated any non-null map as a successful close. Previously the data source accepted a map even if it contained `success: false`, another booking ID, or `status: in_progress`, so the cashier could see a success snackbar without confirmed completion.

The data source now rejects those responses before they reach any widget. The focused mock-HTTP regression covers the requested booking/parameters, confirmed success, explicit failure, wrong booking ID, wrong status and wrong shape. This is a client response-integrity fix only; it does not alter server transactions, prices, payments or grants.

Final verification on [Dashboard PR #80](https://github.com/salahaldensherief/Playspot_dashboard/pull/80), head `b01b0b00695a4c906b15304714456d6bc518b7ec`: Flutter 3.44.1 focused `flutter test` PASS (5 cases), `flutter analyze --no-fatal-infos` PASS (no issues), `dart format` made no changes. GitHub Dart formatting review and [Flutter CI run 40085055116](https://github.com/salahaldensherief/Playspot_dashboard/actions/runs/40085055116) both PASS, including the full test suite and web release build. [Vercel Preview](https://playspot-dashboard-r49i7jhot-salaheldindev11-6746s-projects.vercel.app) reached `READY`, with `target: null` for the same head; no manual deployment was initiated. PR #80 was merged into `dev` at `031761003207f2189c76c4915f825e1bff144662`.

The first mock test attempt failed because the fixture omitted `http.Response.request`; after correcting the fixture all cases passed. The Preview build result does not constitute an authenticated end-to-end cashier test.

Deployed financial contract verification remains blocked as documented in Mobile Draft PR #79, and Mobile financial PR #75 remains Draft.
