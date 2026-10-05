-- Migration: 20261005123500_support_custom_cost_extension_approval.sql
-- Description: Allow custom negotiated extension pricing in approve_booking_extension without
--              it being overwritten by trigger trg_validate_and_clamp_booking_price.
--              1. Update fn_validate_and_clamp_booking_price to check app.skip_price_clamp session setting.
--              2. Update approve_booking_extension to set app.skip_price_clamp = 'true' before updating booking.

-- 1. Update fn_validate_and_clamp_booking_price
CREATE OR REPLACE FUNCTION public.fn_validate_and_clamp_booking_price()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actual_hourly_rate numeric := 0;
  v_extra_controller_rate numeric := 0;
  v_addons numeric := 0;
  v_subtotal numeric := 0;
  v_discount numeric := 0;
  v_snap jsonb;
BEGIN
  -- Honor intentional bypass flag from authorized RPCs (e.g. custom negotiated extension)
  IF current_setting('app.skip_price_clamp', true) = 'true' THEN
    RETURN NEW;
  END IF;

  -- If this is an Open Time session in progress, do not clamp or fail on duration
  IF COALESCE(NEW.is_open_time, false) IS TRUE AND NEW.status = 'in_progress'::public.booking_status THEN
    NEW.duration_minutes := GREATEST(1, COALESCE(NEW.duration_minutes, 1));
    RETURN NEW;
  END IF;

  -- For standard bookings or completed sessions, validate duration
  IF COALESCE(NEW.duration_minutes, 0) <= 0 OR NEW.duration_minutes > 1440 THEN
    RAISE EXCEPTION 'Invalid booking duration: % minutes. Duration must be between 1 and 1440 minutes.',
      NEW.duration_minutes USING ERRCODE = '22023';
  END IF;

  IF NEW.room_id IS NULL THEN
    RAISE EXCEPTION 'Cannot validate booking price: room_id is required.' USING ERRCODE = '22023';
  END IF;

  -- If an Open Time session is completed with a pricing snapshot, honor the snapshot!
  IF COALESCE(NEW.is_open_time, false) IS TRUE AND NEW.open_time_pricing_snapshot IS NOT NULL AND NEW.open_time_pricing_snapshot <> '{}'::jsonb THEN
    v_snap := NEW.open_time_pricing_snapshot;
    v_actual_hourly_rate := COALESCE((v_snap->>'effective_hourly_rate')::numeric, (v_snap->>'base_hourly_rate')::numeric, 50);
  ELSE
    SELECT
      COALESCE(
        CASE
          WHEN NEW.play_mode = 'multi' AND COALESCE(r.hourly_rate_multi, 0) > 0 THEN r.hourly_rate_multi
          ELSE r.hourly_rate_single
        END,
        0
      ),
      GREATEST(0, COALESCE(NEW.extra_controllers, 0)) * COALESCE(r.extra_controller_price, 0)
    INTO
      v_actual_hourly_rate,
      v_extra_controller_rate
    FROM public.rooms r
    WHERE r.id = NEW.room_id;

    IF v_actual_hourly_rate <= 0 THEN
      RAISE EXCEPTION 'Cannot validate booking price: room % has no valid rate configured.', NEW.room_id
        USING ERRCODE = '23514';
    END IF;
  END IF;

  -- Compute room price
  IF COALESCE(NEW.is_open_time, false) IS FALSE OR NEW.status = 'completed'::public.booking_status THEN
    NEW.room_price := ROUND((NEW.duration_minutes / 60.0) * (v_actual_hourly_rate + v_extra_controller_rate), 2);
  END IF;

  v_addons := GREATEST(0, COALESCE(NEW.addons_price, NEW.addons_total, 0));
  NEW.addons_price := v_addons;
  NEW.addons_total := v_addons;

  v_subtotal := NEW.room_price + v_addons;

  IF COALESCE(NEW.discount_amount, 0) > 0 THEN
    v_discount := LEAST(v_subtotal, NEW.discount_amount);
  ELSIF COALESCE(NEW.discount_percentage, 0) > 0 THEN
    v_discount := LEAST(v_subtotal, v_subtotal * (NEW.discount_percentage / 100.0));
  ELSE
    v_discount := 0;
  END IF;

  NEW.discount_amount := v_discount;
  NEW.total_price := GREATEST(0, v_subtotal - v_discount);

  RETURN NEW;
END;
$function$;

-- 2. Update approve_booking_extension
CREATE OR REPLACE FUNCTION public.approve_booking_extension(
  p_booking_id uuid,
  p_additional_cost numeric DEFAULT NULL::numeric,
  p_payment_method text DEFAULT 'cash'::text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'extensions', 'pg_temp'
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_new_duration integer;
  v_new_end timestamp without time zone;
  v_new_end_time time without time zone;
  v_hourly_rate numeric;
  v_cost numeric;
  v_shift_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '28000';
  END IF;

  SELECT b.* INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, true);

  IF v_booking.status NOT IN ('upcoming'::public.booking_status, 'in_progress'::public.booking_status)
     OR COALESCE(v_booking.extension_status, 'none') <> 'pending'
     OR COALESCE(v_booking.requested_extension_minutes, 0) <= 0 THEN
    RAISE EXCEPTION 'NO_ELIGIBLE_PENDING_EXTENSION' USING ERRCODE = '55000';
  END IF;

  SELECT CASE
           WHEN lower(COALESCE(v_booking.play_mode, '')) = 'single' THEN r.hourly_rate_single
           ELSE r.hourly_rate_multi
         END
  INTO v_hourly_rate
  FROM public.rooms AS r
  WHERE r.id = v_booking.room_id
    AND r.lounge_id = v_booking.lounge_id;

  IF v_hourly_rate IS NULL OR v_hourly_rate < 0 THEN
    RAISE EXCEPTION 'ROOM_RATE_NOT_CONFIGURED' USING ERRCODE = '22023';
  END IF;

  v_new_duration := COALESCE(v_booking.duration_minutes, 0) + v_booking.requested_extension_minutes;
  IF v_new_duration <= 0 OR v_new_duration > 1440 THEN
    RAISE EXCEPTION 'INVALID_TOTAL_SESSION_DURATION' USING ERRCODE = '22023';
  END IF;

  v_new_end := v_booking.date + v_booking.start_time + make_interval(mins => v_new_duration);
  v_new_end_time := v_new_end::time;
  v_cost := COALESCE(p_additional_cost, public.calculate_booking_price(v_hourly_rate, v_booking.requested_extension_minutes));

  IF EXISTS (
    SELECT 1
    FROM public.bookings AS next_booking
    WHERE next_booking.id <> v_booking.id
      AND next_booking.room_id = v_booking.room_id
      AND next_booking.status IN ('pending'::public.booking_status, 'upcoming'::public.booking_status, 'in_progress'::public.booking_status)
      AND next_booking.booking_period IS NOT NULL
      AND next_booking.booking_period && tsrange(
        (v_booking.date + v_booking.start_time)::timestamp,
        v_new_end,
        '[)'
      )
      AND (next_booking.status <> 'pending'::public.booking_status
           OR next_booking.expires_at IS NULL
           OR next_booking.expires_at > now())
  ) THEN
    RAISE EXCEPTION 'BOOKING_EXTENSION_CONFLICT' USING ERRCODE = '23P01';
  END IF;

  SELECT s.id INTO v_shift_id
  FROM public.shifts AS s
  WHERE s.lounge_id = v_booking.lounge_id AND s.status = 'open'
  ORDER BY s.opened_at DESC
  LIMIT 1;

  IF v_booking.payment_status = 'paid' AND v_cost > 0 AND v_shift_id IS NOT NULL THEN
    INSERT INTO public.shift_payments (
      shift_id, lounge_id, booking_id, payment_method, category, amount, paid_at
    ) VALUES (
      v_shift_id, v_booking.lounge_id, p_booking_id, 
      COALESCE(p_payment_method, v_booking.payment_method, 'cash'), 
      'gaming_time', v_cost, now()
    );

    UPDATE public.payments
    SET amount = amount + v_cost,
        commission = round((amount + v_cost) * 0.15, 2),
        net_to_lounge = (amount + v_cost) - round((amount + v_cost) * 0.15, 2)
    WHERE booking_id = p_booking_id;
  END IF;

  -- Set skip flag before updating booking to prevent trigger from clobbering custom cost
  PERFORM set_config('app.skip_price_clamp', 'true', true);

  UPDATE public.bookings AS b
  SET duration_minutes = v_new_duration,
      end_time = v_new_end_time,
      end_at = v_new_end_time,
      total_price = COALESCE(b.total_price, 0) + v_cost,
      extension_status = 'approved',
      updated_at = now()
  WHERE b.id = p_booking_id;

  INSERT INTO public.notifications(
    user_id, lounge_id, title_ar, title_en, body_ar, body_en, type, is_read, metadata
  ) VALUES (
    v_booking.user_id, v_booking.lounge_id,
    'تمت الموافقة على تمديد الحجز ✅', 'Booking Extension Approved ✅',
    'تمت الموافقة على طلب تمديد وقت الحجز بمقدار ' || v_booking.requested_extension_minutes || ' دقيقة.', 
    'Your booking extension request was approved for ' || v_booking.requested_extension_minutes || ' minutes.',
    'booking_extension_approved', false,
    jsonb_build_object(
      'booking_id', p_booking_id,
      'extension_minutes', v_booking.requested_extension_minutes,
      'extension_cost', v_cost
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'approved',
    'booking_id', p_booking_id,
    'new_duration', v_new_duration,
    'new_end_time', v_new_end_time,
    'extension_cost', v_cost,
    'new_total', COALESCE(v_booking.total_price, 0) + v_cost,
    'shift_payment_recorded', (v_booking.payment_status = 'paid' AND v_cost > 0)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.approve_booking_extension(uuid, numeric, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.approve_booking_extension(uuid, numeric, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.approve_booking_extension(uuid, numeric, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_booking_extension(uuid, numeric, text) TO service_role;
