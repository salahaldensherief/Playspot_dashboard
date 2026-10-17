# Booking start and postpaid workflow — 17 October 2026

## Required behavior

An approved cash booking becomes startable at its booked time without recording
payment. Starting, extending, ordering, ending play, and collecting money are
separate server-confirmed operations. A scheduled time is not evidence that play
has started. Transfer verification remains a separate prepaid workflow.

## Reproduced defects and changes

- `BookingSchedule.canStart` previously enabled start fifteen minutes early. It
  now opens at the scheduled instant, retaining second precision and rejecting
  invalid schedules. The independent start button refreshes readiness each second.
- `Booking.isBookingActive` previously classified pending, upcoming and even
  rejected bookings inside their scheduled window as active. It now uses only
  `in_progress`, keeping overtime sessions visible until the server ends them.
  Room occupancy and active-session analytics consume the same predicate.
- A due, unstarted booking previously showed remaining play time. It now displays
  “Awaiting session start”; future approved bookings retain the starts-in clock.
  Scheduled start is labelled explicitly rather than presented as an actual start.
- The station drawer previously rendered both booking-card actions and its own
  controls. It now renders one set. Other workspace detail panels retain actions.
- Play controls and cash collection have separate headings. Collection uses a
  secondary outlined action; the guidance explains postpaid extensions/orders.
  Pending, refunded and unverified-transfer bookings do not expose this drawer's
  cash collection action. Existing server authorization remains unchanged.
- New Arabic text uses Modern Standard Arabic. No payment totals, ledger entries,
  or unknown collection amounts are invented by the interface.

## Backend dependency and operational limits

The earlier canonical Mobile migration
`20261016211005_cash_session_start_before_collection.sql` is still required for
backends that reject unpaid cash starts. Pushing Flutter source does not apply it.
It has only been applied to the isolated local QA stack; this follow-up changes
no SQL and performs no hosted database operations.

The time change is a Dashboard readiness rule. This delivery does not add a
server-side planned-start-time guard and must not be represented as hardening
direct RPC calls against early starts.

Earlier real local Auth/PostgREST testing verified start at 50 EGP, extension to
75, canteen additions to 105, unpaid completion, explicit collection of 105, and
idempotent repeated collection. That evidence covers the isolated no-deposit
scenario, not all deposit/paid-addon reconciliation cases or hosted deployment.

## Verification limits

Before changes, schedule-boundary and due-clock regressions failed. The activity
regression independently reproduced `pending` being treated as active. Automated
results for the final source are recorded below after execution.

Actual browser inspection of this follow-up was blocked by the browser protocol
safety gate on the existing tab. The user was asked to open the permitted local
HTTP runtime. Do not describe this follow-up as real-app visual verification
until that inspection occurs. Earlier real-app unpaid-start evidence belongs to
the preceding delivery, not the new layout.

Executed checks:

- Full Dashboard Flutter suite: **1,263 passed, 2 skipped**, no failures.
- Final session-start and responsive cashier workspace subset: **42 passed**.
- Additional due-but-unstarted layout checks: **4 passed**, Arabic and English at
  360/1440 pixels and 1.6 text scale. Widget screenshots were inspected separately
  from real-app evidence; they are not proof of hosted backend compatibility.
- Dart formatting and staged diff whitespace checks passed.
- Full `flutter analyze --no-pub --no-fatal-infos`: no issues, 103.2 seconds.
