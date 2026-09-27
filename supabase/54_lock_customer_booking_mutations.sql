-- CI baseline: platform hardening safety net
BEGIN;

CREATE OR REPLACE FUNCTION public.cancel_my_booking(
  p_booking_id uuid,
  p_reason text DEFAULT 'Cancelled by user'
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

  IF v_booking.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_booking.status NOT IN (
    'pending'::public.booking_status,
    'upcoming'::public.booking_status
  ) THEN
    RAISE EXCEPTION 'Booking cannot be cancelled in its current status'
      USING ERRCODE = '55000';
  END IF;

  UPDATE public.bookings
  SET status = 'cancelled'::public.booking_status,
      cancellation_reason = COALESCE(NULLIF(btrim(p_reason), ''), 'Cancelled by user'),
      cancelled_at = now(),
      cancelled_by = auth.uid(),
      updated_at = now()
  WHERE id = p_booking_id;

  IF v_booking.room_id IS NOT NULL THEN
    PERFORM public.sync_room_status(v_booking.room_id);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'cancelled'
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.cancel_my_booking(uuid, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.cancel_my_booking(uuid, text)
TO authenticated, service_role, supabase_auth_admin;


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
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF v_receipt_url IS NULL THEN
    RAISE EXCEPTION 'Receipt URL is required' USING ERRCODE = '22023';
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

REVOKE EXECUTE ON FUNCTION public.attach_my_booking_receipt(uuid, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.attach_my_booking_receipt(uuid, text)
TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.request_booking_extension(
  p_booking_id uuid,
  p_requested_minutes integer
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

  IF p_requested_minutes IS NULL
     OR p_requested_minutes <= 0
     OR p_requested_minutes > 240 THEN
    RAISE EXCEPTION 'Requested extension must be between 1 and 240 minutes'
      USING ERRCODE = '22023';
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

  IF v_booking.status <> 'in_progress'::public.booking_status THEN
    RAISE EXCEPTION 'Only active bookings can request an extension'
      USING ERRCODE = '55000';
  END IF;

  IF v_booking.extension_status = 'pending' THEN
    RETURN jsonb_build_object(
      'success', true,
      'booking_id', p_booking_id,
      'already_pending', true,
      'requested_minutes', v_booking.requested_extension_minutes
    );
  END IF;

  UPDATE public.bookings
  SET extension_status = 'pending',
      requested_extension_minutes = p_requested_minutes,
      updated_at = now()
  WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'already_pending', false,
    'requested_minutes', p_requested_minutes
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.request_booking_extension(uuid, integer)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.request_booking_extension(uuid, integer)
TO authenticated, service_role, supabase_auth_admin;


DROP POLICY IF EXISTS "bookings_write_policy" ON public.bookings;
DROP POLICY IF EXISTS "bookings_update_customer_or_branch" ON public.bookings;
DROP POLICY IF EXISTS "bookings_delete_customer_or_branch" ON public.bookings;

CREATE POLICY "bookings_update_branch_only"
ON public.bookings
FOR UPDATE
TO authenticated
USING (public._playspot_has_lounge_access(lounge_id))
WITH CHECK (public._playspot_has_lounge_access(lounge_id));

CREATE POLICY "bookings_delete_branch_only"
ON public.bookings
FOR DELETE
TO authenticated
USING (public._playspot_has_lounge_access(lounge_id));

COMMIT;
