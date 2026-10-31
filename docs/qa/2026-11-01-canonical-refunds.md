# Canonical manual cash refund integration — 1 November 2026

## Delivery follow-up — owner-provided Vercel evidence

The owner subsequently supplied the actual project Settings → Environments image:
Production tracks **main**; Preview tracks **all unassigned git branches**; Preview
has no custom domains. Image SHA256:
`DCBE2A7812ABA3C9C00A55C5F8F3C2489E6FB5A48435802F18D3A86ECCD9277A`.
This supersedes the earlier verbal report that dev was the Production Branch.
No Production-branch change is needed from the evidence shown; no settings were changed.
Draft release PR #88 is still open/Draft, dev → main; it was not merged.

The remaining pre-push gate is narrower: verify current Git connection/build command
and Preview Supabase variable scopes/target, without exposing values or connecting to
hosted backends. Existing source has empty compile-time defaults and checks required
configuration before Supabase initialization. Missing Preview configuration can fail
closed; an injected Production/Staging configuration cannot be assumed safe.
Read-only project API/CLI access remains unavailable. The owner was asked only for
Git repository name, redacted build command, and environment names/scopes/target.
No Save/Redeploy or branch/environment modification was requested.

The refund implementation remains `413826ec7239ae46861db016b05a9a0b2cc5ab96`;
this follow-up changes guidance/evidence only. Reuse its exact 27 targeted tests and
local Auth/API/ledger/main-build evidence; do not claim browser acceptance.
Dashboard remote dev remains `6113da82da43b8630f042b3be30e3cfeaf2560fd` at inspection.
The dated pre-screenshot investigation below is preserved as history.

## Source and scope

Implementation branch: `codex/dashboard-refund-integration-20261101`, based on local
dev `a54ad29acd58873d7f34653bacef452b308f59f7`. Remote inspection still returns
`6113da82da43b8630f042b3be30e3cfeaf2560fd` for Dashboard dev.
The commit containing this report includes the implementation; its exact SHA is
recorded in the companion canonical handover after commit. No remote push.

Actual entry: booking details, both responsive layouts → shared financial summary
→ Refunds and verified returns → BookingRefundCubit → BookingRefundRepository
→ Supabase canonical RPCs → validated request/monetary receipt → canonical summary.
No legacy payment RPC, direct ledger update, cancellation mutation or backend migration.
The booking total is now labelled total rather than implying a trustworthy balance due.

Contract source: canonical Mobile dev `46cdfafe`, refund migration
`20261027150000` plus forward audit/signature correction `20261031111003`.
Existing local baseline includes these; no historical migration replay performed.
Source signatures remain:

- `get_booking_refund_summary(p_booking_id)`
- `initiate_booking_refund(p_booking_id,p_collection_movement_id,p_refund_amount_minor,p_reason,p_operation_id,p_policy_override)`
- `execute_booking_refund(p_refund_request_id,p_return_payment_method,p_evidence_reference,p_operation_id,p_shift_id)`

Supported write scope is lounge-held original CASH collections, partial/full.
Owner/manager can explicitly request an audited policy override; default false.
Customer, cross-branch, inactive/banned accounts are not offered cashier actions.
Cash execution needs the signed-in actor's active open same-branch shift, evidence
and explicit attestation that the return was actually performed once.
The server reauthorizes and enforces policy, available collection, reservations,
payout locks, drawer cash and transaction invariants. UI guards do not replace it.
Transfers/platform custody, policy editing and request cancellation have no new write
UI here. Historical/locked/unsupported cases remain server-rejected or read-only.

Gross collected, actual returns, net collected, pending requests and unreserved
unreturned collection are distinct native widgets. The latter is NOT invoice due
or guaranteed refund eligibility. Initiation is never reported as money returned.
Audit views now interpret the canonical payload stage: the backend uses
`payment_refunded` for both initiation and completion; missing/unknown stage stays neutral.

## Retry and authorization

Deterministic UUIDv5 IDs cover actor/booking/phase/snapshot/payload; identical
intents on the same snapshot deduplicate. An actor-scoped durable journal retains
only IDs and hashes, not evidence/reasons/tokens. Pending mismatched payloads are
blocked before dispatch. Unknown transport/gateway/malformed-receipt outcomes retain
the operation; retry uses identical details. Definitive first SQL rejection may be
corrected; rejection after an earlier unknown result does not discard its journal.
Canonical request/movement reads can recover lost acknowledgement after restart.
Absence from a read never proves an in-flight request cannot commit; unresolved
cases require review and remain blocked. Do not clear browser storage to bypass this.
Cross-tab journal storage is not a distributed lock; deterministic intent IDs and
server request/booking locks provide final accounting protection. Separate cashier
physical cash handover still requires the venue's actual receipt-verification procedure.

Success requires matching operation/booking/request/amount/method/shift and canonical
movement/expense identity. A validated receipt survives a failed subsequent refresh,
with further actions disabled until a fresh authorized read. Logout/account changes
fail closed. No secret key or client-generated financial amount is trusted.

Writes default OFF via `PLAYSPOT_MANUAL_REFUND_WRITES`; no hosted contract rollout
is implied. The isolated local test explicitly enables the repository only against
127.0.0.1:56821 and synthetic accounts. Do not enable hosted writes before backend
compatibility, recovery and rollout acceptance are authorized.

## Evidence and limitations

Final executed checks (no remote CI claimed):

- `flutter test --no-pub` for booking_refund_contract_test,
  booking_refund_dialog_test, atomic_cash_checkout_contract_test and
  refunded_financial_status_test: **27 passed**. The two dialog cases use real
  translated widgets at 360px and 1.6 text scale, Arabic RTL and English LTR.
- `scripts/test_local_refunds.ps1 -PrivateDirectory PRIVATE_LOCAL_RUNTIME -Report OUTPUT_JSON`:
  **1 real local repository journey passed**. The runner restores process environment,
  preserves prior inputs/rows and selects an unused synthetic station rather than
  clearing previous booked capacity. No hosted requests are allowed by its HTTP client.
- `node tooling/dev-stack/verify-client-refund.mjs PRIVATE_LOCAL_RUNTIME CLIENT_REPORT LEDGER_REPORT`
  in canonical Mobile source: **independent ledger assertions passed**; node syntax check passed.
- `dart format --output=none --set-exit-if-changed lib test`: **1137 files, 0 changed**.
- `flutter analyze --no-pub --no-fatal-infos`: **no issues**; final two edited
  booking dialog files analyzed again, **no issues**.
- Actual `flutter build web --no-pub --release --no-web-resources-cdn --dart-define-from-file=.env.dev-local.json --dart-define=PLAYSPOT_MANUAL_REFUND_WRITES=true`:
  **passed, 117.5s**, targeting lib/main.dart. Public loopback config was generated
  only in the ignored worktree file after verifying anon role; no hosted fallback.
  Optional Wasm dry-run warnings remain; no dependency upgrade.

Initial failures were corrected and preserved in workspace logs: mocked HTTP
responses needed SDK request metadata; the local stack was stopped; the new UNC
runner originally used a PowerShell provider path; reusing a station hit its retained
booking capacity period. No test/database rule was weakened. Audit assertions now
check two initiated plus two completed stages, matching the inspected backend contract.
Earlier failed Web build lacked the ignored local config; the final build above
used the verified local public key and succeeded.

Focused checks and sanitized local API/independent SQL evidence accompany this report
in `docs/qa/evidence/refunds-20261101/`. Full logs stay in workspace outputs.
The local test uses actual GoTrue/PostgREST through Dashboard's repository:
100.00 collected, 33.33 returned, lost-response replay, then remaining 66.67;
customer and revoked cashier denied; simultaneous same-isolate submissions block
one pending intent. Independent read-only SQL verifies 2 reversals, 2 completed
requests, 1 payment aggregate, zero net collection/commission, 100.00 drawer input
and 100.00 refund expense output. Audit stages are independently counted, not
inferred from event_code alone. These are synthetic attestations, no external funds.

Local stack had stopped with WSL. The preserved dedicated daemon/storage identity
was checked before restart; nine existing core services and actual loopback bindings
then verified, Auth health HTTP 200. No reset/bootstrap/reseed occurred. The warm
launcher initially exited nonzero; its private diagnostics were preserved. The
optional Edge container remained stopped at this checkpoint; prior 7-group Edge
runtime evidence is historical, not rerun or claimed current.

Actual browser financial interaction remains unaccepted: existing Windows UI tooling
twice timed out in the previous task; no bypass or repeated browser troubleshooting.
Widget rendering/interaction, compilation and authenticated API evidence are separate.
No new golden or browser screenshot claim. No hosted compatibility claim.
An attempt to start a new loopback build server on 51753 was rejected by automatic
tool policy (`blocked by policy`, no detailed reason supplied). It did not run;
no new local URL or HTTP/rendering acceptance is claimed. No alternate launch was
attempted to bypass that rejection. The verified compiled build remains in this
implementation worktree's `build/web` for manual launch through the normal local workflow.

Manual local acceptance after explicitly enabling the local refund build: sign in as
the synthetic owner/cashier, open a collected synthetic booking, inspect the separate
balances and request, verify the current own shift, record a verified synthetic cash
return once, refresh and verify the same receipt/ledger. Check Arabic/English,
keyboard traversal, denial after permission revocation, response failure and reload.
Never hand back cash again merely to retry a recording request.

## Vercel delivery gate

Read-only GitHub metadata on 1 November confirms last Preview record 7458201304,
source `6113da82`, created 31 October. Latest record labelled Production returned
by GitHub is 6206651654 at `fd46373158f41cef21b7e380045868c3b8afae59`
(1 September), but its ref is a SHA and `production_environment=false`.
These labels do not establish the current live Production alias or branch.
Owner reports current Production Branch dev; no current Vercel credential/tool,
project link or project-settings access is available to independently verify it.
Preview backend URL/key scope is unknown. No deployed application was opened.

[Official Git integration documentation](https://vercel.com/docs/git) confirms that
the configured Production branch can trigger Production. Therefore HOLD push.
Before any settings edit, obtain read-only project Git/environment metadata and
the owner's intended protected release branch/process. Do not assume main.
Proposed separation for subsequent specific approval: chosen release branch alone
targets Production; dev targets Preview; Preview has only an explicitly authorized
non-Production backend or fails closed. A developer loopback backend is not a usable
hosted Preview backend. No branch-protection bypass, setting edit, push or deployment
was performed by this task.
