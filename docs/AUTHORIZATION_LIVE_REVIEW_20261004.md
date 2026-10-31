# Live authorization review — 2026-10-04

The supplied Super Admin account has an active, unbanned profile and canonical platform administrator membership. The owner and cashier accounts have their respective active, unbanned roles and no platform administrator membership. This was inspected without modifying roles or grants.

Fresh authenticated requests on the hosted project verified the actual `is_super_admin` RPC and the deployed `create-lounge-owner` Edge Function, version 2. The Super Admin returned `true` and the deliberately empty creation request reached validation (HTTP 400), rather than authorization denial. Owner and cashier returned `false` and HTTP 403. No owner account or lounge was created. This verifies access to the creation endpoint, not successful provisioning of a real account.

The actual Dashboard KYC read call, `get_lounge_review_requests`, returned HTTP 200 for Super Admin and HTTP 403 for owner and cashier. No KYC decision was made. Response data and tokens were not logged. Only the newly created test authentication sessions were signed out using local scope; existing user sessions were not globally revoked.

Client profile loading now refuses a requested identity different from the authenticated account, a foreign profile response, and a profile response after an account change. Platform membership cannot promote an inactive or banned profile. Four regression checks were added to the existing location/authentication suite; all 14 checks passed. All 11 isolated owner provisioning service tests also passed.

The missing no-argument PostgreSQL signature is not a missing RPC: the hosted profile function is `get_my_profile(p_user_id uuid DEFAULT NULL)`, and the client correctly invokes it with omitted parameters. Authorization remains server-controlled; no UI role override grants database access.

Still to verify: successful isolated end-to-end owner provisioning, KYC submission/decision in the browser, and current responsive UI behavior for each role. These read/invalid-input probes are not proof of every permission or feature being complete. Offline device handover changes remain uncommitted review work; their additional concurrency findings must be resolved before deployment or UI activation.
