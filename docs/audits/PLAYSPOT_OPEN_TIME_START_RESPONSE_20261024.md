# Dashboard Open Time start response — 24 October 2026

The `OpenTimeSessionDialog` calls `BookingCubit.startOpenTimeSession` → repository → `BookingRemoteDataSourceImpl` → `start_open_time_session`. The deployed function's inspected return contract includes `success`, `booking_id`, `room_id`, `started_at`, `status`, `is_open_time` and `shift_id`. Before this change the data source accepted any JSON map with `success: true`; the dialog then closed and showed “started” even if the response did not identify a running Open Time booking for the requested room.

The data source now verifies the room, nonempty booking ID, running/Open Time status and parseable server start timestamp. Mock-HTTP tests cover the correct request/response and reject failure, wrong room, wrong status, invalid timestamp and malformed response. This is a client acknowledgment guard, not proof that the backend allocated a station safely or created a financially valid session. Exact-schema concurrency, permission, shift and ledger tests remain blocked by the missing replayable baseline described in Mobile Draft PR #79.

Local verification: Flutter 3.44.1; the start and completion response suites passed together (12 cases). Final-head CI and Vercel Preview results are recorded on the focused PR.
