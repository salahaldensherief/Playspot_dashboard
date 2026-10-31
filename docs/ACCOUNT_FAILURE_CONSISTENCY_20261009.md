# Account deletion and administrator deactivation

delete-account now depends on playspot_V2 migration 20261009000004_account_anonymization_transaction.sql. Database deletion/deactivation is atomic; Auth disabling remains an external operation with two attempts and a durable pending record. See that repository's ACCOUNT_DELETION_CONSISTENCY_20261009.md for staging deployment, reconciliation and containment rollback. No automatic reconciliation worker exists.

The existing deactivate-lounge-admin handler already disables/unassigns atomically through deactivate_lounge_admin, then retries Auth twice. The native legacy-contract fixture verifies transaction rollback, target protection, canonical active authority, lounge isolation and idempotent replay. Its handler tests verify denied access, database failure, transient/permanent Auth failure and explicit retry recovery. A 503 deactivated=true requires retry/operations attention; it does not imply Auth was disabled. This path has no durable Auth task queue and no automatic retry after the request ends.

Node tests execute the actual TypeScript handlers with synthetic service responses. Native tests do not contain Supabase Auth. Hosted Edge, token invalidation and dashboard partial-error UX remain untested pending a disposable staging account. Deployed versions observed read-only remain delete-account v6 and deactivate-lounge-admin v1; pushing dev changes neither hosted bundle.

CI runs every supabase/functions/*/*.test.mjs handler suite, including staff creation authorization, rather than only the original provisioning suites.
