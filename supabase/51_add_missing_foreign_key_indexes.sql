-- 51_add_missing_foreign_key_indexes.sql
-- Performance Optimization: Create indexes on foreign keys of bookings table to eliminate Linter performance warnings.

CREATE INDEX IF NOT EXISTS idx_bookings_lounge_id ON public.bookings(lounge_id);
CREATE INDEX IF NOT EXISTS idx_bookings_room_id ON public.bookings(room_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_shift_id ON public.bookings(shift_id);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at_status ON public.bookings(created_at DESC, status);
