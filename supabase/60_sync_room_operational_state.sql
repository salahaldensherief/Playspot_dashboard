BEGIN;

CREATE OR REPLACE FUNCTION public.set_room_operational_status(
  p_room_id uuid,
  p_status text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_status text := lower(btrim(COALESCE(p_status, '')));
  v_lounge_id uuid;
  v_required_permission text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '28000';
  END IF;

  IF p_room_id IS NULL THEN
    RAISE EXCEPTION 'ROOM_ID_REQUIRED' USING ERRCODE = '22023';
  END IF;

  IF v_status NOT IN ('available', 'occupied', 'maintenance') THEN
    RAISE EXCEPTION 'INVALID_ROOM_STATUS' USING ERRCODE = '22023';
  END IF;

  SELECT r.lounge_id
  INTO v_lounge_id
  FROM public.rooms AS r
  WHERE r.id = p_room_id
    AND r.status <> 'deleted'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ROOM_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  v_required_permission := CASE
    WHEN v_status = 'maintenance' THEN 'rooms_manage'
    ELSE 'sessions_control'
  END;

  IF NOT public.is_super_admin()
     AND NOT public.has_lounge_permission(
       v_lounge_id,
       v_required_permission
     ) THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED' USING ERRCODE = '42501';
  END IF;

  UPDATE public.rooms
  SET status = v_status,
      is_available = (v_status = 'available'),
      updated_at = now()
  WHERE id = p_room_id;

  RETURN jsonb_build_object(
    'success', true,
    'room_id', p_room_id,
    'lounge_id', v_lounge_id,
    'status', v_status,
    'is_available', (v_status = 'available')
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.set_room_operational_status(uuid, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.set_room_operational_status(uuid, text)
TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.complete_booking_session(
  p_booking_id uuid,
  p_action_by uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_room_id uuid;
  v_lounge_id uuid;
BEGIN
  IF p_action_by IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'Action user must be the authenticated user';
  END IF;

  SELECT lounge_id, room_id
  INTO v_lounge_id, v_room_id
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF v_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  PERFORM private.assert_lounge_operator(v_lounge_id, true);

  UPDATE public.bookings
  SET status = 'completed',
      updated_at = now()
  WHERE id = p_booking_id;

  IF v_room_id IS NOT NULL THEN
    UPDATE public.rooms
    SET status = 'available',
        is_available = true,
        updated_at = now()
    WHERE id = v_room_id
      AND lounge_id = v_lounge_id
      AND status = 'occupied';
  END IF;

  RETURN json_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'lounge_id', v_lounge_id,
    'status', 'completed'
  );
END;
$function$;


UPDATE public.rooms
SET is_available = CASE
      WHEN status = 'available' THEN true
      ELSE false
    END,
    updated_at = now()
WHERE status IN ('available', 'occupied', 'maintenance', 'deleted')
  AND is_available IS DISTINCT FROM (status = 'available');

COMMIT;
