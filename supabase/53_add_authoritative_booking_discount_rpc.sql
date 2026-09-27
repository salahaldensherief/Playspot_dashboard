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

COMMIT;
