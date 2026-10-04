# KYC and onboarding contract review

2026-10-04 primary-agent verification:

- 175 Dashboard Flutter tests for KYC and onboarding passed (offline).
- PostgreSQL 17.11 native fixtures: lounge review integrity 30 checks,
  onboarding bootstrap 10 checks, resource save 13 checks; all passed.
- Cases include anonymous/foreign-owner denial, owner cannot approve,
  revision mismatch, reason required on rejection, immutable snapshot, replay,
  approval/rejection and resource rollback. These are isolated fixture tests,
  not a live acceptance run. Geography is stubbed and concurrent decisions are
  not proven by these single-connection fixtures.
- Read-only live check: `kyc-documents` is private, 10 MiB limit; MIME allowlist
  is JPEG, PNG, WebP, PDF. The installed storage client infers multipart MIME
  from the immutable object path extension; a missing explicit contentType is
  not an octet-stream defect in this installed version.

Remaining gates from DASHBOARD_COMPLETION_CHECKPOINT_20261004.md still apply:
automatic unplanned offline cutover, auditable conflict reconciliation and
complete real-browser document upload/submission/review. Passing these tests
does not complete those features or certify production readiness.
