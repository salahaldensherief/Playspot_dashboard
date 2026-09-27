-- Migration 16: Add extend_booking_session RPC & Booking Duration Extension Support
-- Date: 2026-09-23

DROP FUNCTION IF EXISTS public.extend_booking_session(UUID, INT);
DROP FUNCTION IF EXISTS public.extend_booking_session(UUID, INTEGER);

CREATE OR REPLACE FUNCTION public.extend_booking_session(
  p_booking_id UUID,
  p_extension_minutes INT DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_booking RECORD;
  v_room_rate NUMERIC := 0;
  v_additional_cost NUMERIC := 0;
  v_new_end_time TIME;
  v_new_duration INT;
  v_has_overlap BOOLEAN;
BEGIN
  -- 1. Fetch booking
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_booking.id IS NULL THEN
    RAISE EXCEPTION 'Booking % not found', p_booking_id;
  END IF;

  -- 2. Fetch room rate
  SELECT COALESCE(price_per_hour, hourly_rate_single, 0)
  INTO v_room_rate
  FROM public.rooms
  WHERE id = v_booking.room_id;

  -- 3. Calculate new duration and end_time
  v_new_duration := COALESCE(v_booking.duration_minutes, 60) + p_extension_minutes;
  v_additional_cost := (p_extension_minutes::NUMERIC / 60.0) * v_room_rate;

  IF v_booking.end_time IS NOT NULL AND v_booking.end_time != '' THEN
    v_new_end_time := (v_booking.end_time::TIME + (p_extension_minutes || ' minutes')::INTERVAL)::TIME;
  ELSE
    v_new_end_time := (v_booking.start_time::TIME + (v_new_duration || ' minutes')::INTERVAL)::TIME;
  END IF;

  -- 4. Check for overlapping future bookings on same room
  SELECT EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.room_id = v_booking.room_id
      AND b.id != p_booking_id
      AND b.date = v_booking.date
      AND b.status IN ('upcoming', 'in_progress', 'pending')
      AND b.start_time::TIME < v_new_end_time
      AND b.start_time::TIME >= v_booking.end_time::TIME
  ) INTO v_has_overlap;

  IF v_has_overlap THEN
    RAISE EXCEPTION 'BOOKING_EXTENSION_CONFLICT: Room is already booked for an upcoming slot immediately following this session.'
      USING ERRCODE = '23P01';
  END IF;

  -- 5. Update booking
  UPDATE public.bookings
  SET duration_minutes = v_new_duration,
      end_time = v_new_end_time::text,
      total_price = COALESCE(total_price, 0) + v_additional_cost,
      room_price = COALESCE(room_price, 0) + v_additional_cost,
      updated_at = NOW()
  WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'new_duration_minutes', v_new_duration,
    'new_end_time', v_new_end_time::text,
    'additional_cost', v_additional_cost
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.extend_booking_session(UUID, INT) TO authenticated, anon;
