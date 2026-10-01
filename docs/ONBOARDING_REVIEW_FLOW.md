# Onboarding and venue review — coordinated release source

Updated 2026-10-01. This document describes the versioned client and SQL repair source.
It does not claim these RPCs have been deployed to the hosted database.

The owner completes nine steps: venue type, basic identity/contact/photos, city/address/GPS,
operating hours, rooms/resources/pricing, products/inventory, payment destination,
identity/business documents, then a consent and review summary.
Required fields include valid GPS coordinates, a main venue photo, at least one room,
identity evidence and at least one transfer destination. Business evidence is currently optional;
jurisdiction-specific document requirements still need a product policy.

Venue details are saved atomically before final review submission. Stable room and product IDs
make retries update the same resources. Removed resources are deactivated only when there are
no conflicting future/active bookings. The client retains existing photos when adding uploads.
Saving details alone never completes setup or activates the venue. Only a valid server acknowledgement
from submit_lounge_review moves the owner to pending review. Immutable content-addressed uploads
are safe to retry after a lost acknowledgement. Scoped drafts separate each owner and venue.
Server draft restoration preserves pending local field edits and exposes the latest rejection notes.

Super admins review the exact immutable request ID and revision, rather than all venues of an owner.
The dialog shows the venue snapshot, room prices/capacity, payment destination and signed evidence.
Approval/rejection awaits server confirmation; failures keep the dialog open. Approval activates the
selected venue but leaves online availability closed. Rejection preserves the owner's login and
returns that venue to correction. The client guards late responses and duplicate review mutations.

Release dependency: backend repair migrations 20261001110000 through 20261001170000, plus
the active_super_admin_boundary.sql review source, must be reviewed and deployed in a coordinated
release before merging this feature client to dev. No SQL is auto-applied by the client or tests.
Wallet/session repairs are separate contracts and require their own release review.
Legacy KYC submission/review endpoints must be retired or redirected before cutover; otherwise
older clients can bypass the versioned workflow. The hosted bucket's private access policies also
require final deployment verification. Ordinary staff routes already require an active verified venue.

Remaining blockers: owner registration must use Supabase Auth Admin rather than direct auth.users
insertion; chains need an owned brand ID instead of typed brand labels; saved identity evidence
reuse and gallery removal controls need completion. Admin snapshots still need complete equipment/
stock/photo/map presentation. Offline cashier writes and server online-availability leases are separate
unfinished work and must not be advertised as complete. No production migration, auth mutation or
live database test has been run for this source release.

Verification includes offline Flutter transport/cubit/router/restoration/validation tests and real-widget
layout captures. Synthetic PostgreSQL 17 tests cover revision checks, submission freeze, decision
retries, resource retries, rejection re-entry and privilege boundaries. Synthetic schemas and mocked
uploads do not prove hosted Storage/RLS/Auth integration. Screenshot fixtures do not replace
an end-to-end signed-in session or physical-device performance measurement.
