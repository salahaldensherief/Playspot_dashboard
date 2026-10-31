-- Migration: 20261005124000_add_missing_fk_indexes.sql
-- Description: Add index for unindexed foreign key identified in performance advisor:
--              booking_waitlist(hold_id) referencing booking_holds(id).

CREATE INDEX IF NOT EXISTS idx_booking_waitlist_hold_id ON public.booking_waitlist(hold_id);
