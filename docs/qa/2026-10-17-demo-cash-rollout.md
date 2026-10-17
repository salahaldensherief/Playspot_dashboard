# Demo cash start rollout — 17 October 2026

User authorized Demo and local deployment, and a separate production plan.
Production deployment remains excluded.

## Applied to the existing Demo

- Project: `tmqhncduzlavgqoyjcmn` (`playspot-demo`, active healthy, Postgres 17).
- Remote ledger entry: `20261017121640_demo_cash_session_start_before_collection`.
- Canonical source: Mobile migration
  `20261016211005_cash_session_start_before_collection.sql`, commit
  `2f128f38479c30fa3ec665303a5663dfa66ca292`.
- Replaced only `public.start_booking_session(uuid)` and
  `public.create_manual_booking_admin(uuid,uuid,date,time,integer,text,text,text,jsonb,boolean)`.
- Compared both pre-deployment function bodies with the tested baseline: exact
  match. Captured their prior definitions and a rollback outside Git.
- Added an atomic baseline-definition hash guard and short lock/statement timeouts
  to the deployment wrapper. No old migrations were replayed.
- Verified new definitions, original execute ACLs, security-definer flags and
  empty search paths after deployment. Anonymous execution was not granted.
- Starting a cash session no longer requires a receipt; immediate manual start
  no longer records a payment automatically. Transfers/refunds retain the tested
  restrictions. No receipt or ledger row is created by the schema deployment.

## Preservation evidence

Full-row fingerprints and counts matched before/after for all eight inspected
tables. This is stronger than counting rows alone, but is not a backup of Storage
binary contents or a fingerprint of every database table.

| Table | Unchanged rows |
| --- | ---: |
| lounges | 24 |
| rooms | 144 |
| bookings | 655 |
| payments | 500 |
| canteen_orders | 170 |
| lounge_reviews | 125 |
| shift_payments | 4 |
| storage.objects | 39 |

No synthetic accounts, bookings, payments, orders or reviews were created to test
the hosted migration. No Storage API writes occurred. Runtime transactional
rehearsal is a separate step; metadata verification is not a claim that a new
hosted end-to-end journey has run.

## Existing advisory findings

The pre-deployment security scan reported PostGIS in public and its
`spatial_ref_sys` table without RLS, private tables with RLS/no policies, existing
executable security-definer functions, and disabled leaked-password protection.
These predate this change and were not suppressed or changed. They need a
separate production review; the scan is not a clean security certification.

Relevant advisor references:
[public schema RLS](https://supabase.com/docs/guides/database/database-linter?lint=0013_rls_disabled_in_public),
[function execute privileges](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable).

Production `tgpdexoitemmpruepgyt` was neither queried nor changed by this rollout.
Detailed fingerprints/rollback material remain outside Git in the task reports
and private directories; credentials are not included in this document.
