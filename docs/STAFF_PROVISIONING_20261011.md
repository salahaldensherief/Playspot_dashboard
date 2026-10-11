# Staff creation recovery

The staff and lounge-administrator creation data sources share
`LoungeStaffProvisioner`. It serializes requests per Supabase client, validates
the returned identity/role and persists uncertain finalization recovery in secure
storage scoped to backend and actor. Original non-password fields must match on
retry. It never stores the password. Both Arabic and English describe recovery.

Deploy dependency: playspot_V2 migration
`20261011060637_atomic_staff_provisioning.sql` must be applied and integration
tested in isolated staging before deploying this `create-lounge-staff` Edge
bundle, then releasing the Dashboard client. The migration and Edge handler
remain source only. Exact hosted SQL history reconciliation and the broader
9/10 October migrations need separate deployment review.

Auth creation includes trusted server provenance. Finalization atomically writes
profile, membership and audit receipt after repeating current authorization.
Lost Auth acknowledgements recover by exact email/provenance; uncertain database
responses return a recoverable identity. The handler never deletes an Auth
account to compensate for an uncertain database commit. Recovery cannot adopt
an unrelated existing account or grant permissions without current authority.

Local verification: Dashboard full suite 1128 passed, JavaScript release build
passed, 8 focused client/permission cases and 18 staff Edge handler cases passed.
Native fixture verification lives in the canonical Mobile repository. Real
Supabase Auth and native/browser secure storage integration remain staging work.

The deleted SQL 81 is obsolete reference source; the safer actual hosted
conflict-retry migration is now tracked in playspot_V2 with its original version.
CI permits removal of legacy Dashboard SQL while rejecting added/modified SQL.
