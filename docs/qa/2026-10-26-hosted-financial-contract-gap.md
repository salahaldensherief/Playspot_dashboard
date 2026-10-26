# Hosted financial contract gap, 26 October 2026

Read-only `pg_proc` and catalog checks were run through the authorized Supabase connection against both hosted projects. No schema or customer row was changed.

| Contract | Canonical `play spot` (`tgpdexoitemmpruepgyt`, PostgreSQL 17.6) | Separate `playspot-demo` (`tmqhncduzlavgqoyjcmn`, PostgreSQL 17.11) | Current source |
| --- | --- | --- | --- |
| `checkout_booking_cash_atomic` | Absent | Absent | Mobile/backend `dev` migration `20261025101139_atomic_discount_cash_checkout.sql`; Dashboard `dev` calls it |
| `verify_booking_deposit_transfer` | Absent | Absent | Mobile/backend `dev` migration `20261025225255_canonical_booking_collections.sql`; Dashboard `dev` calls it |
| `get_lounge_staff_permissions`, `set_staff_permission` | Absent | Absent | Mobile/backend `dev` migration `20261025151217_owner_permission_write_boundary.sql`; Dashboard `dev` calls them |
| `private.booking_money_movements` | Absent | Absent | Mobile/backend `dev` migration `20261025225255_canonical_booking_collections.sql` |
| `complete_booking_payment(uuid,text,numeric)` | Present, authenticated execute; anon denied | Same definition hash and grants | Legacy checkout; cannot represent the new canonical mixed collection |
| `complete_booking_session(uuid,uuid)` | Present, authenticated execute; anon denied | Same definition hash and grants | Legacy session close; no evidence of new hosted partial-payment classification |

The hosted canonical and demo projects both have `payments` and `shift_payments`. The relevant public booking/payment/shift policy counts were 9 and 5 respectively; matching legacy function hashes do **not** imply identical RLS or data. The demo migration ledger ends at `20261017121640_demo_cash_session_start_before_collection`. The six newer Mobile/backend migrations were merged as source by PR #89, but are not recorded as applied on either hosted project. Dashboard financial and staff-permission source was merged by PR #86, so its new actions currently reach missing RPCs on these hosted backends.

The canonical project may serve real users and is excluded from development writes. The demo project contains existing Auth users, lounges, bookings and payment-related records; it is not disposable. Local demo owner/customer credentials passed direct password Auth and `/auth/v1/user` checks, but no current Dashboard signed-in financial flow passed. There is **no verified hosted development backend for the new contract yet**.

Before applying SQL to an explicitly selected non-production target: verify a restorable backup including the recovery procedure, compare its live function signatures and migration ledger to the six source migrations, restore/test the sequence on an isolated copy, check historical payment/booking compatibility and Auth/RLS, then apply the reviewed missing migrations in order and run signed-in client/accounting tests. Supabase's [backup documentation](https://supabase.com/docs/guides/platform/backups) notes that database backups exclude Storage objects, so asset recovery needs its own plan. Do not point a cashier at the current demo for financial acceptance.
