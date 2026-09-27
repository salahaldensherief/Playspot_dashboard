BEGIN;

CREATE OR REPLACE FUNCTION public.attach_my_booking_receipt(
  p_booking_id uuid,
  p_receipt_url text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_receipt_url text := NULLIF(btrim(p_receipt_url), '');
  v_expected_prefix text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF v_receipt_url IS NULL THEN
    RAISE EXCEPTION 'Receipt reference is required' USING ERRCODE = '22023';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_booking.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_booking.status NOT IN (
    'pending'::public.booking_status,
    'upcoming'::public.booking_status
  ) THEN
    RAISE EXCEPTION 'Receipt cannot be changed in the current booking status'
      USING ERRCODE = '55000';
  END IF;

  v_expected_prefix := auth.uid()::text || '/' || p_booking_id::text || '/';

  IF v_receipt_url NOT LIKE v_expected_prefix || '%' THEN
    RAISE EXCEPTION 'Receipt reference does not belong to this booking'
      USING ERRCODE = '42501';
  END IF;

  IF v_receipt_url LIKE 'http://%' OR v_receipt_url LIKE 'https://%' THEN
    RAISE EXCEPTION 'Receipt reference must be a private storage object path'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.bookings
  SET receipt_url = v_receipt_url,
      updated_at = now()
  WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'receipt_url', v_receipt_url
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.attach_my_booking_receipt(uuid,text)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.attach_my_booking_receipt(uuid,text)
TO authenticated, service_role;

COMMIT;
