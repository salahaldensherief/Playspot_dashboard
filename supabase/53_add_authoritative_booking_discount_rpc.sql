BEGIN;

CREATE OR REPLACE FUNCTION public.apply_booking_discount(
  p_booking_id uuid,
  p_discount_amount numeric DEFAULT 0,
  p_discount_percentage numeric DEFAULT 0,
  p_discount_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_amount numeric := GREATEST(COALESCE(p_discount_amount, 0), 0);
  v_percentage numeric := GREATEST(COALESCE(p_discount_percentage, 0), 0);
  v_reason text := NULLIF(btrim(p_discount_reason), '');
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, false);

  IF v_amount > 0 AND v_percentage > 0 THEN
    RAISE EXCEPTION 'Use either a fixed discount or a percentage discount, not both'
      USING ERRCODE = '22023';
  END IF;

  IF v_percentage > 100 THEN
    RAISE EXCEPTION 'Discount percentage must be between 0 and 100'
      USING ERRCODE = '22023';
  END IF;

  IF (v_amount > 0 OR v_percentage > 0) AND v_reason IS NULL THEN
    RAISE EXCEPTION 'Discount reason is required'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.bookings
  SET
    discount_amount = v_amount,
    discount_percentage = v_percentage,
    discount_reason = v_reason,
    discount_approved_by = auth.uid(),
    updated_at = now()
  WHERE id = p_booking_id
  RETURNING *
  INTO v_booking;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking.id,
    'discount_amount', v_booking.discount_amount,
    'discount_percentage', v_booking.discount_percentage,
    'discount_reason', v_booking.discount_reason,
    'total_price', v_booking.total_price
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.apply_booking_discount(
  uuid, numeric, numeric, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.apply_booking_discount(
  uuid, numeric, numeric, text
) TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.start_booking_session(
  p_booking_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT public.is_super_admin()
     AND NOT public.has_lounge_permission(
       v_booking.lounge_id,
       'sessions_control'
     ) THEN
    RAISE EXCEPTION 'Not authorized for this lounge'
      USING ERRCODE = '42501';
  END IF;

  IF v_booking.status = 'in_progress'::public.booking_status THEN
    RETURN jsonb_build_object(
      'success', true,
      'booking_id', p_booking_id,
      'status', 'in_progress'
    );
  END IF;

  IF v_booking.status <> 'upcoming'::public.booking_status THEN
    RAISE EXCEPTION 'Only upcoming bookings can be started'
      USING ERRCODE = '55000';
  END IF;

  IF COALESCE(v_booking.payment_status, 'unpaid') <> 'paid' THEN
    RAISE EXCEPTION 'PAYMENT_REQUIRED_BEFORE_SESSION_START'
      USING ERRCODE = '55000';
  END IF;

  UPDATE public.bookings AS b
  SET status = 'in_progress'::public.booking_status,
      checked_in_at = COALESCE(b.checked_in_at, now()),
      actual_start_time = COALESCE(b.actual_start_time, now()),
      updated_at = now()
  WHERE b.id = p_booking_id;

  IF v_booking.room_id IS NOT NULL THEN
    UPDATE public.rooms AS r
    SET status = 'occupied',
        is_available = false,
        updated_at = now()
    WHERE r.id = v_booking.room_id
      AND r.status NOT IN ('maintenance', 'deleted');
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'in_progress'
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.start_booking_session(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.start_booking_session(uuid)
TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.update_booking_status_admin(
  p_booking_id uuid,
  p_status text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_status public.booking_status;
  v_now_local timestamp without time zone :=
    now() AT TIME ZONE 'Africa/Cairo';
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, true);

  BEGIN
    v_status := p_status::public.booking_status;
  EXCEPTION
    WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'Invalid booking status' USING ERRCODE = '22023';
  END;

  IF v_status IN (
       'in_progress'::public.booking_status,
       'completed'::public.booking_status
     )
     AND COALESCE(v_booking.payment_status, 'unpaid') <> 'paid' THEN
    RAISE EXCEPTION 'PAYMENT_REQUIRED_FOR_ACTIVE_OR_COMPLETED_BOOKING'
      USING ERRCODE = '55000';
  END IF;

  UPDATE public.bookings
  SET status = v_status,
      updated_at = now()
  WHERE id = p_booking_id;

  IF v_status = 'in_progress'::public.booking_status
     OR (
       v_status = 'upcoming'::public.booking_status
       AND v_booking.booking_period IS NOT NULL
       AND v_booking.booking_period @> v_now_local
     ) THEN
    UPDATE public.rooms
    SET status = 'occupied',
        is_available = false,
        updated_at = now()
    WHERE id = v_booking.room_id
      AND status NOT IN ('maintenance', 'deleted');
  ELSIF v_status IN (
    'upcoming'::public.booking_status,
    'completed'::public.booking_status,
    'cancelled'::public.booking_status,
    'rejected'::public.booking_status
  ) THEN
    UPDATE public.rooms AS r
    SET status = 'available',
        is_available = true,
        updated_at = now()
    WHERE r.id = v_booking.room_id
      AND r.status = 'occupied'
      AND NOT EXISTS (
        SELECT 1
        FROM public.bookings AS active_b
        WHERE active_b.room_id = r.id
          AND active_b.id <> p_booking_id
          AND active_b.status IN (
            'upcoming'::public.booking_status,
            'in_progress'::public.booking_status,
            'pending'::public.booking_status
          )
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

REVOKE EXECUTE ON FUNCTION public.update_booking_status_admin(uuid, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.update_booking_status_admin(uuid, text)
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
