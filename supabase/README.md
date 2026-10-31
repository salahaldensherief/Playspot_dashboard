# Supabase source of truth

The SQL files in this dashboard repository are retained as legacy reference
material only. They must not be deployed or extended.

All production database changes, RPC contracts, RLS policies, cron jobs, and
storage policies belong in the `playspot_V2` repository under
`supabase/migrations/`. Client changes that depend on a new contract must state
the required migration and rollout order in their pull request.

This rule prevents the mobile and dashboard repositories from defining two
different versions of the same backend contract.

CI accepts only unchanged SQL bytes from the approved legacy snapshot at
`e0ea905276cb350a7f20100822c4b3e1d8b872f6`. This allows the existing dev history
to be promoted to main without treating those files as deployable migrations.
New paths or modified SQL are rejected on every PR, including release PRs.
The reference is pinned rather than following the moving dev branch.
