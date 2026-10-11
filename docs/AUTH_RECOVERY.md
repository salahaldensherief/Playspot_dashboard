# Durable Auth disabling recovery

Status: source implemented and isolated PostgreSQL/worker tests passed. Not deployed to hosted Supabase or verified against real GoTrue yet. This is distinct from staff-create compensation, which remains open.

Apply Mobile migration `20261009000004_account_anonymization_transaction.sql` before `20261010120419_durable_auth_disable_recovery.sql`. Profile inactive/banned transitions transactionally enqueue a private job; rollback rolls back the job. Existing unfinished deletion requests are backfilled only when the profile is still ineligible. Historical deactivations without a durable request need separately reviewed reconciliation; this migration does not assume every inactive historical account needs a new operation.

Deploy `reconcile-auth-disable` to the isolated environment after both migrations, alongside the repaired deletion/deactivation handlers. It accepts only the server service credential, never an admin/customer JWT, and does not accept a request-selected user ID. Never expose its credential in either Flutter client.

Run every minute. Each batch claims at most 10 tasks, with `FOR UPDATE SKIP LOCKED`, a fresh UUID lease and a two-minute expiry. Only the current lease can acknowledge. Auth bans are idempotent; a missing Auth user already cannot sign in. Network/provider/ack failures survive worker termination. Five claimed attempts maximum; retry delays are 30, 60, 120, 240 seconds before the fifth attempt becomes terminal. A fifth crashed attempt becomes failed after its lease expires. Repeating a profile update without changing eligibility does not reset attempts.

Monitoring: service-only RPC `get_auth_disable_recovery_status()` returns counts and oldest pending time. Worker logs `AUTH_RECOVERY_REQUIRES_ATTENTION` on deferred work or terminal failures and `AUTH_RECOVERY_BATCH_FAILED` on infrastructure errors. Monitor worker HTTP status, this RPC, and scheduler delivery separately: a cron SQL success only means an HTTP request was queued. Alert on any failed task and pending age over 10 minutes. No external alert destination is configured by this change.

Scheduling uses Supabase [Cron/pg_net/Vault](https://supabase.com/docs/guides/functions/schedule-functions). After test deployment, store environment-specific URL and server service JWT in Vault as `auth_recovery_project_url` and `auth_recovery_service_key`, without committing their values. Schedule the following in the TEST database only:

```sql
select cron.schedule('playspot-auth-disable-recovery', '* * * * *', $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets
            where name = 'auth_recovery_project_url') || '/functions/v1/reconcile-auth-disable',
    headers := jsonb_build_object('Content-Type','application/json','Authorization',
      'Bearer ' || (select decrypted_secret from vault.decrypted_secrets
                   where name = 'auth_recovery_service_key')),
    body := '{}'::jsonb,
    timeout_milliseconds := 10000
  );
$job$);
```

Use a legacy service JWT supported by the environment's Edge JWT verifier; verify both gateway and handler checks. A modern non-JWT secret needs explicitly reviewed gateway configuration. Local scheduling can invoke the same POST through a test-only process using local service credentials; do not use a production URL/key. The schedule itself has not been applied: complete-stack testing is still blocked by Windows prerequisites.

Test real Auth outage, restored service, duplicate delivery, lost acknowledgement, concurrent workers and existing access tokens in the isolated stack. Native tests use synthetic identities and are not a replacement for these tests. Re-enabling a profile cancels queued jobs/leases, but an Auth request already in flight cannot be revoked by PostgreSQL; account reinstatement must coordinate Auth unban after the worker settles. No reinstatement flow is implemented here.

Rollback: first disable/unschedule this named job and wait for leased work to settle. Roll back the Edge worker to its previous deployment/disable endpoint. Retain the private task table and rows for investigation; do not drop/delete them. To stop producers, disable the named `profile_auth_disable_recovery` trigger in a reviewed follow-up migration, leaving the original account deactivation and token protections intact. Retry only reviewed terminal identities after fixing the cause; never reset all failed tasks blindly.
