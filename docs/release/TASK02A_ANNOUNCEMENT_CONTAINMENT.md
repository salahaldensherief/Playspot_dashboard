# Global announcement containment candidate

Production `send-system-announcement` is active at version 1 with `verify_jwt=false`. Its handler checks a bearer token or internal key, but it accepts profile roles `owner` and `admin` as global broadcasters. The current `dev` implementation uses `is_super_admin()` for the caller and keeps the database webhook key separate. The SQL function checks an active, unbanned Auth/profile identity and canonical platform membership. A caller-controlled topic or payload is parsed only after authorization.

Release artifact: `supabase/functions/send-system-announcement/index.ts` plus `authorization.js`, deployed together. The guard now has an executable dispatch boundary; 12 isolated tests include a role matrix and mocked FCM delivery, with zero sends for owner/cashier/banned cases. No real FCM message was sent.

**Immediate containment recommended for separate approval:** deploy only this reviewed Edge Function source after comparing the exact current production version and staging-testing both the active platform admin and internal webhook path. Preserve the existing server-only `internal_get_edge_function_key` secret. Do not place it in a client, change keys, or send a production test broadcast under Task 02A. If staging fails, leave production unchanged and temporarily disable the broadcast path through an authorized operational control. Roll back only to a version that still enforces canonical platform authority; rolling back to production v1 would restore the defect.

The database, custody, cash-start, financial and checkout releases have separate gates in the backend rollout document. This document is a review artifact; no deployment is authorized or performed.
