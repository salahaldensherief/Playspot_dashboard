# Dashboard backend audit — 11 October 2026

Companion server contract: `playspot_V2/docs/backend/BACKEND_AUDIT_20261011.md`. Deploy and verify its five new migrations before exposing custody review in production. This source branch performs no deployment.

The platform payout page now opens a paginated review of unknown payment recipients. Each record displays payment/booking/venue identifiers, method, amount and receipt time. An administrator must select platform or lounge and supply an evidence reference. No recipient is inferred from InstaPay, wallet or card. Requests send only payment ID, recipient and evidence; amounts remain server-owned. Replays and conflicting evidence use server decisions. Errors remain visible. Zero/debt payout results are failures instead of success toasts.

Booking reads retain RPC authority on missing functions, authorization errors and malformed responses; the former broad table fallback is removed. FCM uses one module-level GoogleAuth instance, letting the pinned Google library manage access-token expiry and refresh.

Verified locally: 1138 Flutter tests passed (2 existing skips); analyze reports 49 informational findings and no warnings/errors. 76 Edge tests passed, including 9 actual FCM handler cases. New payout contract/widget tests cover both recipient choices, required evidence, finite ledger values, RPC acknowledgement and false payout success. Booking tests cover authorization/missing RPC failures without direct reads. Actual Google token refresh and device notification delivery are not tested.

Pending: full Auth/Realtime/Storage integration, legacy reconciliation and audited evidence correction, mixed-recipient installment contract, deployment of existing source security fixes, and exact-commit CI. The separately prepared staff recovery PR must be reviewed too. No production records or deployments were changed.
