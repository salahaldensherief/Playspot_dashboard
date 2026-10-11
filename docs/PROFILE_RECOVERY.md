# Profile recovery contract

An existing Auth session and a successfully verified application profile are separate states. A failed `get_my_profile` request must not become `Right(null)` or a logout. The data source now propagates errors; a profile missing for the same authenticated identity also fails explicitly. A response from a previous identity remains discarded.

Initial lookup and profile refresh enter `profileFailure` on failure. The router gates protected pages, including cached platform administrators, on the existing access-loading route. That page offers localized retry and explicit logout. Retry rechecks the profile and permissions; no cached identity grants access while verification has failed. A genuinely absent session clears the cached user.

Regression evidence: the SDK error and two Cubit cases failed before repair. The Auth suite passes 79 cases; two additional page tests exercise Arabic/English at 360px and text scale 1.6. The full dashboard suite passes 1118 tests with 2 skipped. These use synthetic transport and do not establish hosted Auth/Realtime E2E.
