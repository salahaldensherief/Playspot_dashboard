# Review follow-ups — 11 October 2026

The six reported Dashboard defects are addressed at their existing boundaries:

- Installing a complete cashier bootstrap removes obsolete server booking projections while preserving receipts, acknowledgements and sequence history. Fresh paid/completed bookings no longer revert to an older synchronized state.
- Access guards, the access loader and shell initialization use the selected branch for the same actor; a different actor starts from its own profile scope.
- Successful profile retry now triggers permission loading, avoiding a permanent access spinner.
- Pricing requests ignore results after Cubit disposal and superseded load/quote requests. Failed quote previews are cleared, and save/delete messages use Arabic/English translations.
- Dashboard SQL policy permits byte-identical legacy references from fixed commit e0ea905276cb350a7f20100822c4b3e1d8b872f6, including dev-to-main promotion. New or modified SQL remains prohibited and belongs in the canonical Mobile migrations repository.
- Canteen removal calls an authorized, idempotent archive RPC and filters deleted rows on reload. Ordinary disabled offers remain editable; historical sales are retained.

## Database prerequisite

Apply Mobile migration `20261011133002_canteen_catalogue_deletion_tombstones.sql` before deploying the new Dashboard catalogue client. It adds deletion tombstones and the archive RPC, locks and authorizes the resource, and blocks reactivation/physical client deletion. It was tested with isolated Postgres fixtures and the local Supabase schema; no hosted migration was applied by this work. Previously disabled offers are not automatically classified as deleted.

## Verification

Regression tests cover stale bootstrap overlays, selected-branch access, profile retry, Cubit disposal and quote replacement, archive transport failures and reload filters. Python policy tests exercise unchanged legacy SQL, changed SQL and new SQL. Full Flutter, Edge contract and release web-build results are recorded in the accompanying task status.
