# Moderation contract review — 2026-10-04

Live PostgreSQL metadata confirmed that the four existing moderation RPCs require `p_request_id` / `p_admin_notes`, or `p_lounge_id` / `p_reason`. The client previously sent names without the prefix and could fail before reaching authorization. These payload names now match the live definitions; optional admin notes preserve null rather than inventing an empty value.

Both moderation list queries now propagate permission/schema failures. A failed read is no longer shown as an empty queue. Failure diagnostics record the operation and database code, excluding raw exception messages, notes and account/request identifiers.

Eight HTTP contract regression tests verify all four RPC payloads and both list reads under authorization (`42501`) and missing-schema (`PGRST202`) failures. Full offline suite passed **895 tests**, explicitly excluding live-tagged database tests. Full analyze passed with 52 informational lints, no errors or warnings. No bans, lounge suspensions or real customer warnings were submitted during this review.

The existing cancellation-warning dialog had no request at all and displayed a fabricated success. Live inventory confirmed no dedicated customer-warning contract. It now explains that warning delivery is unavailable and does not offer a fake submission. Connecting this feature still needs a scoped, auditable backend operation; generic notification delivery is not an authorization substitute.

Runtime checks against the rebuilt localization release authenticated the supplied owner and super-admin accounts. Owner room management loaded; super-admin statistics settled, the venue badge was absent, and KYC displayed its empty state without an RPC error. Browser page-error capture was empty. These are read/navigation checks, not a full KYC approval lifecycle or moderation mutation test.

Screenshots are retained in the local review workspace, including `superadmin-localized-settled.png` and `superadmin-kyc-localized.png`. The warning-dialog correction is covered by subsequent source/test verification and needs the next release rebuild before a runtime screenshot.
