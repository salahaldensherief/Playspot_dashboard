# Supabase source of truth

The SQL files in this dashboard repository are retained as legacy reference
material only. They must not be deployed or extended.

All production database changes, RPC contracts, RLS policies, cron jobs, and
storage policies belong in the `playspot_V2` repository under
`supabase/migrations/`. Client changes that depend on a new contract must state
the required migration and rollout order in their pull request.

This rule prevents the mobile and dashboard repositories from defining two
different versions of the same backend contract.
