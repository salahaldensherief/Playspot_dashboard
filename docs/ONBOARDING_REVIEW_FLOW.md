# Lounge onboarding and verification review

Reviewed 2026-09-30. Live inspection used SELECT on function definitions only.
No document uploads, review RPC calls, migrations or live writes were performed.

## Intended business flow

Owner authenticates, enters lounge identity/contact/address/location, operating
hours, images, and rooms with rates/capacity/specifications. Canteen products are
optional. A branch selection must reference a brand owned by the authenticated
owner; typing a brand name or a branch count cannot create a real chain implicitly.
Owner supplies identity proof and optionally business proof, reviews a summary,
then explicitly submits one complete version for verification.

Review is a distinct lifecycle: draft -> submitted -> under review -> approved
or rejected. A rejection records a reason and allows a new version after edits.
Pending or rejected lounges cannot enter operational dashboard routes or accept
online bookings. Owner can still inspect status or edit an eligible draft.
Administrative suspension/bans must never be bypassed by an onboarding exception.
Approval unlocks operational access only. Online admission additionally requires
an open shift, current connectivity lease and reconciled reservations.

Reviewer sees owner identity/contact, complete lounge information, location,
images, opening hours, rooms/rates/capacity, optional inventory, protected document
previews, version/submission timestamp and previous rejection notes. Decisions
must await server acknowledgment, retain failures visibly and avoid double submit.
PDF documents require a document viewer rather than an image-only renderer.

## Frontend repairs in this phase

- batch_complete_onboarding returns void. Successful RPC is followed by an exact
  lounge-ID read. Removed the fallback that could duplicate rooms/products and
  silently mark a profile complete after partial failures.
- onboard_lounge returns success/lounge_id/status metadata, not a Lounge entity.
  Fetch the actual lounge by the returned ID; reject malformed acknowledgments.
- Room additions in the onboarding repository are staged, not inserted immediately
  and then inserted again by final batch submission.
- Preserve room images/features/descriptions/capacity/controllers/screen/type and
  decimal rates in the final payload. Serialize enum status to its database name.
- Add persisted contact phone input and send verified contact_phone field.
- Validate core identity/address/contact/hours, one room, main photo and ID document.
  Flush the debounce before submit. Stop after failed KYC upload and guard duplicate
  submit. Split the legacy setup view into state/content/submission parts.
- Add an eighth review step with owner/lounge/contact/address/hours/rates/attachment
  summary and explicit unchecked consent before submission. Remove invented KYC ETA.

## Remaining backend contract gaps — release blockers

1. submit_kyc_documents immediately publishes status=pending separately from lounge
   completion. A reviewer can act before lounge data is committed. Need a reviewed,
   atomic submit-for-review contract with immutable version and stable operation ID.
2. batch_complete_onboarding marks profile setup complete independently of KYC,
   appends rooms/extras, and has no deduplication key. An ambiguous timeout or failed
   follow-up read must not be automatically replayed. Need an authoritative status
   read/reconciliation contract before a retry can safely repeat the mutation.
3. get_pending_kyc_reviews returns only user_id, owner_name/email, lounge_name and
   document references. It omits lounge ID, phone, full fields, rooms, timestamps,
   rejection history and review version. Supply a scoped full review detail contract.
4. review_kyc currently accepts user ID and updates every lounge owned by that user.
   Need exact lounge/submission/version identity and pending-only decision checks.
5. review_kyc approval currently sets lounges.is_open=true immediately. Separate
   approval from shift/presence/online eligibility; an accepted lounge can be offline.
6. onboard_lounge sets profiles.is_active=false, while RouterGuards rejects inactive
   accounts before onboarding/pending routing. Distinguish pending verification from
   administrative suspension server-side; do not weaken the suspension guard.

## Remaining frontend work

Account/lounge-scoped durable drafts including rooms/products, attachment retention
policy, complete per-step validation, location selection
without mandatory GPS, real city/brand IDs, localized rejection/resubmission status,
full reviewer detail view with awaited decisions/retry and PDF previews, and offline
end-to-end flow tests and responsive captures. Current tests do not certify the full
business flow or live integration. No private identity documents should be persisted
in plain SharedPreferences/GetStorage.

The transfer handoff states: "A separate agent owns Supabase implementation. Do not
implement/apply SQL or change live RLS, grants, Storage or cron." This phase changes
Flutter only. The backend gaps above remain untouched for the backend owner.
