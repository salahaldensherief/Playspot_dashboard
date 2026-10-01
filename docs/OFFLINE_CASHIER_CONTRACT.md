# Offline cashier implementation stages

This branch contains the local storage/command/synchronization foundation. It is
not yet a complete offline cashier UI and must not be released as that feature.
The current cashier screens still use their existing online repositories.

## Implemented and verified locally

- Hive 2.2.3 stores each account/venue's projection and pending commands together
  in one encrypted record. Writes await persistence and flush before acknowledgement.
- Encryption keys use FlutterSecureStorage 10.3.4. A missing key never creates a
  replacement for an existing database. GetStorage 2.1.1 accepts only non-secret
  device ID, language and theme. It never stores keys, tokens or financial data.
- The local engine reserves a fixed-duration room, starts its session, records
  product orders, collects partial cash and closes without inventing payment.
  Prices use cached integer minor units and a billing quantum. These are snapshot
  prices, not proof that every advanced server pricing rule has been integrated.
- Projection, inventory deduction, receipt and outbox update in the same write.
  Duplicate IDs replay once; altered payloads fail. Room overlap, stock, amount,
  account/venue eligibility, exact effective permissions, shift and offline permit
  lifetime are checked. No privilege is inferred from a role name.
- Synchronization is sequential and single-flight. Each matching server receipt
  is persisted before removing its queued operation. Lost responses keep data;
  explicit retries use the same ID. Conflicts block dependent operations and remain
  on the device. Late responses after leaving the scope cannot clear local work.

Verification: 33 feature tests and 219 total offline Flutter tests passed; two live
tests remained skipped. Analyze had 22 existing informational findings and no
errors/warnings. Tests use real temporary encrypted Hive files and fake secure-key
and network adapters. Native credential storage/browser key security and hosted
reconciliation have not been exercised end to end.

## Required before enabling cashier writes in the app

1. Implement and verify server-issued device-bound offline permits, canonical
   resource/inventory/booking snapshots, and apply_offline_cashier_operation.
   Client JSON is never an authority for server prices, permissions or payment.
2. Implement a server availability lease: internet loss cannot instantly notify a
   remote server. Online bookings must stop when the heartbeat expires, and this
   bounded detection interval must be covered by resource conflict protection.
3. Bind the owner/employee's cached identity, venue, rooms, shift and effective
   permissions to a single cashier store. Add cached read adapters and local command
   paths to real cashier actions, including open-time/extension and shift operations.
4. Display offline/pending/conflict states, provide explicit reconciliation review,
   and preserve pending financial records on logout. Do not silently discard conflicts
   or manufacture server success when an endpoint is absent.
5. Complete advanced pricing, discounts, cached offers, expiry/clock handling and
   time-zone mapping. Verify these with native PostgreSQL and real UI workflows.

Single writer: the in-process journal serializes calls. It does not provide a
distributed lock between devices, browser tabs or independent application processes.
Multi-device halls need an explicit local coordinator/transport feature and a server
ownership protocol; they must not be enabled by reusing this in-process lock.
On native platforms secure keys use the platform plugin. Browser storage follows
the plugin's WebCrypto implementation and requires its own origin/HTTPS validation;
it must not be described as native OS credential storage.

No SQL/migration has been applied to production and no dev/main merge is made for
this unfinished feature. Generated macOS secure-storage registration is necessary
for the added native dependency and is scoped to this feature, unlike unrelated
generated files/test cache artifacts preserved in the original worktrees.
