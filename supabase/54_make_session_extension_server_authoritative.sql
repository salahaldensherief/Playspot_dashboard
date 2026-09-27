BEGIN;

CREATE OR REPLACE FUNCTION public.extend_booking_session(
  p_booking_id uuid,
  p_additional_minutes integer,
  p_additional_cost numeric DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_is_staff boolean := false;
  v_is_super_admin boolean := false;
  v_new_duration integer;
  v_new_end timestamp without time zone;
  v_new_end_time time without time zone;
  v_hourly_rate numeric;
  v_cost numeric := 0;
  v_shift_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '28000';
  END IF;

  IF p_additional_minutes IS NULL
     OR p_additional_minutes <= 0
     OR p_additional_minutes > 720 THEN
    RAISE EXCEPTION 'INVALID_EXTENSION_MINUTES' USING ERRCODE = '22023';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
    AND (
      b.user_id = auth.uid()
      OR private.is_lounge_member(b.lounge_id)
      OR public.is_super_admin()
    )
    AND b.status IN (
      'in_progress'::public.booking_status,
      'upcoming'::public.booking_status
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND_OR_NOT_OWNED' USING ERRCODE = '42501';
  END IF;

  v_is_staff := private.is_lounge_member(v_booking.lounge_id);
  v_is_super_admin := public.is_super_admin();

  IF NOT v_is_staff AND NOT v_is_super_admin THEN
    IF COALESCE(v_booking.extension_status, 'none') = 'pending' THEN
      RAISE EXCEPTION 'EXTENSION_ALREADY_PENDING' USING ERRCODE = '55000';
    END IF;

    UPDATE public.bookings
    SET extension_status = 'pending',
        requested_extension_minutes = p_additional_minutes,
        updated_at = now()
    WHERE id = p_booking_id;

    RETURN jsonb_build_object(
      'success', true,
      'status', 'pending',
      'booking_id', p_booking_id,
      'requested_extension_minutes', p_additional_minutes
    );
  END IF;

  v_new_duration :=
    COALESCE(v_booking.duration_minutes, 60) + p_additional_minutes;

  IF v_new_duration <= 0 OR v_new_duration > 1440 THEN
    RAISE EXCEPTION 'INVALID_TOTAL_SESSION_DURATION' USING ERRCODE = '22023';
  END IF;

  SELECT CASE
           WHEN lower(COALESCE(v_booking.play_mode, '')) = 'single'
             THEN r.hourly_rate_single
           ELSE r.hourly_rate_multi
         END
  INTO v_hourly_rate
  FROM public.rooms AS r
  WHERE r.id = v_booking.room_id
    AND r.lounge_id = v_booking.lounge_id;

  IF v_hourly_rate IS NULL OR v_hourly_rate < 0 THEN
    RAISE EXCEPTION 'ROOM_RATE_NOT_CONFIGURED' USING ERRCODE = '22023';
  END IF;

  v_new_end :=
    v_booking.date
    + v_booking.start_time
    + make_interval(mins => v_new_duration);

  v_new_end_time := v_new_end::time;
  v_cost := public.calculate_booking_price(
    v_hourly_rate,
    p_additional_minutes
  );

  IF EXISTS (
    SELECT 1
    FROM public.bookings AS next_booking
    WHERE next_booking.id <> v_booking.id
      AND next_booking.room_id = v_booking.room_id
      AND next_booking.status IN (
        'pending'::public.booking_status,
        'upcoming'::public.booking_status,
        'in_progress'::public.booking_status
      )
      AND next_booking.booking_period IS NOT NULL
      AND next_booking.booking_period && tsrange(
        (v_booking.date + v_booking.start_time)::timestamp,
        v_new_end,
        '[)'
      )
      AND (
        next_booking.status <> 'pending'::public.booking_status
        OR next_booking.expires_at IS NULL
        OR next_booking.expires_at > now()
      )
  ) THEN
    RAISE EXCEPTION 'BOOKING_EXTENSION_CONFLICT' USING ERRCODE = '23P01';
  END IF;

  SELECT s.id
  INTO v_shift_id
  FROM public.shifts AS s
  WHERE s.lounge_id = v_booking.lounge_id
    AND s.status = 'open'
  ORDER BY s.opened_at DESC
  LIMIT 1;

  UPDATE public.bookings
  SET duration_minutes = v_new_duration,
      end_time = v_new_end_time,
      end_at = v_new_end_time,
      total_price = COALESCE(total_price, 0) + v_cost,
      extension_status = 'approved',
      requested_extension_minutes = NULL,
      updated_at = now()
  WHERE id = p_booking_id;

  IF v_booking.payment_status = 'paid' AND v_cost > 0 THEN
    UPDATE public.payments
    SET amount = amount + v_cost,
        commission = round((amount + v_cost) * 0.15, 2),
        net_to_lounge =
          (amount + v_cost) - round((amount + v_cost) * 0.15, 2)
    WHERE booking_id = p_booking_id;

    IF v_shift_id IS NOT NULL THEN
      INSERT INTO public.shift_payments (
        shift_id,
        lounge_id,
        booking_id,
        payment_method,
        category,
        amount,
        paid_at
      )
      VALUES (
        v_shift_id,
        v_booking.lounge_id,
        p_booking_id,
        COALESCE(v_booking.payment_method, 'cash'),
        'gaming_time',
        v_cost,
        now()
      );
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'status', 'approved',
    'booking_id', p_booking_id,
    'added_minutes', p_additional_minutes,
    'extension_cost', v_cost,
    'new_duration', v_new_duration,
    'new_end_time', v_new_end_time
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.extend_booking_session(
  uuid, integer, numeric
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.extend_booking_session(
  uuid, integer, numeric
) TO authenticated, service_role, supabase_auth_admin;

COMMIT;
