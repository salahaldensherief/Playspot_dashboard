-- 35_fix_booking_pricing_nighttime_and_room_status.sql
-- Fixes:
-- 1. sync_booking_period_trigger: Correctly handles overnight bookings (e.g. 23:30 to 01:30) so lower bound is strictly less than upper bound.
-- 2. fn_validate_and_clamp_booking_price: Uses existing column names (addons_price, discount_amount, discount_percentage) instead of invalid fields (extras, voucher_discount), preventing price wipeouts on UPDATE.
-- 3. update_booking_status_admin: Guarantees room status is reset to 'available' and is_available=true on booking cancellation/completion.

CREATE OR REPLACE FUNCTION public.sync_booking_period_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'auth', 'extensions', 'pg_temp'
AS $function$
DECLARE
    v_start_ts timestamp;
    v_end_ts timestamp;
BEGIN
    IF NEW.start_at IS NOT NULL AND NEW.end_at IS NOT NULL THEN
        v_start_ts := NEW.start_at;
        v_end_ts := NEW.end_at;
    ELSIF NEW.date IS NOT NULL AND NEW.start_time IS NOT NULL AND NEW.end_time IS NOT NULL THEN
        v_start_ts := (NEW.date + NEW.start_time)::timestamp;
        IF COALESCE(NEW.duration_minutes, 0) > 0 THEN
            v_end_ts := v_start_ts + (NEW.duration_minutes || ' minutes')::interval;
        ELSIF NEW.end_time <= NEW.start_time THEN
            v_end_ts := (NEW.date + NEW.end_time + interval '1 day')::timestamp;
        ELSE
            v_end_ts := (NEW.date + NEW.end_time)::timestamp;
        END IF;
    END IF;

    IF v_start_ts IS NOT NULL AND v_end_ts IS NOT NULL AND v_start_ts < v_end_ts THEN
        NEW.booking_period := tsrange(v_start_ts, v_end_ts, '[)');
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_validate_and_clamp_booking_price()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actual_hourly_rate NUMERIC := 0;
  v_addons NUMERIC := 0;
  v_subtotal NUMERIC := 0;
  v_manual_discount NUMERIC := 0;
BEGIN
  IF COALESCE(NEW.duration_minutes, 0) <= 0 OR NEW.duration_minutes > 1440 THEN
    RAISE EXCEPTION 'Invalid booking duration: % minutes. Duration must be between 1 and 1440 minutes.', NEW.duration_minutes;
  END IF;

  IF NEW.room_id IS NULL THEN
    RAISE EXCEPTION 'Cannot validate booking price: room_id is required.';
  END IF;

  IF TG_OP = 'INSERT'
     OR (TG_OP = 'UPDATE' AND (
          OLD.room_id IS DISTINCT FROM NEW.room_id
          OR OLD.duration_minutes IS DISTINCT FROM NEW.duration_minutes
          OR OLD.play_mode IS DISTINCT FROM NEW.play_mode
     )) THEN

    SELECT
      COALESCE(
        CASE
          WHEN NEW.play_mode = 'multi' AND COALESCE(hourly_rate_multi, 0) > 0 THEN hourly_rate_multi
          ELSE COALESCE(hourly_rate_single, 0)
        END, 0
      )
    INTO v_actual_hourly_rate
    FROM public.rooms
    WHERE id = NEW.room_id;

    IF v_actual_hourly_rate <= 0 THEN
      RAISE EXCEPTION 'Cannot validate booking price: room % has no valid rate configured.', NEW.room_id;
    END IF;

    NEW.room_price := (NEW.duration_minutes / 60.0) * v_actual_hourly_rate;
  ELSE
    NEW.room_price := GREATEST(0, COALESCE(NEW.room_price, OLD.room_price, 0));
  END IF;

  v_addons := GREATEST(0, COALESCE(NEW.addons_price, NEW.addons_total, 0));
  NEW.addons_price := v_addons;
  NEW.addons_total := v_addons;

  v_subtotal := NEW.room_price + v_addons;

  IF COALESCE(NEW.discount_amount, 0) > 0 THEN
    v_manual_discount := LEAST(v_subtotal, NEW.discount_amount);
  ELSIF COALESCE(NEW.discount_percentage, 0) > 0 THEN
    v_manual_discount := LEAST(v_subtotal, (v_subtotal * (NEW.discount_percentage / 100.0)));
  ELSE
    v_manual_discount := 0;
  END IF;

  NEW.discount_amount := v_manual_discount;
  NEW.total_price := GREATEST(0, v_subtotal - v_manual_discount);

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_booking_status_admin(p_booking_id uuid, p_status text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'extensions', 'pg_temp'
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_status public.booking_status;
  v_now_local timestamp := (now() AT TIME ZONE 'Africa/Cairo');
BEGIN
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, true);

  BEGIN
    v_status := p_status::public.booking_status;
  EXCEPTION WHEN invalid_text_representation THEN
    RAISE EXCEPTION 'Invalid booking status';
  END;

  UPDATE public.bookings
  SET status = v_status,
      updated_at = now()
  WHERE id = p_booking_id;

  IF v_status = 'in_progress'::public.booking_status
     OR (v_status = 'upcoming'::public.booking_status
         AND v_booking.booking_period IS NOT NULL
         AND v_booking.booking_period @> v_now_local) THEN
    UPDATE public.rooms
    SET status = 'occupied',
        is_available = false,
        updated_at = now()
    WHERE id = v_booking.room_id;
  ELSIF v_status IN ('upcoming'::public.booking_status,
                     'completed'::public.booking_status,
                     'cancelled'::public.booking_status,
                     'rejected'::public.booking_status) THEN
    UPDATE public.rooms r
    SET status = 'available',
        is_available = true,
        updated_at = now()
    WHERE r.id = v_booking.room_id
      AND NOT EXISTS (
        SELECT 1
        FROM public.bookings active_b
        WHERE active_b.room_id = r.id
          AND active_b.id <> p_booking_id
          AND active_b.status IN ('upcoming'::public.booking_status, 'in_progress'::public.booking_status, 'pending'::public.booking_status)
          AND active_b.booking_period IS NOT NULL
          AND active_b.booking_period @> v_now_local
      );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', v_status::text
  );
END;
$function$;
