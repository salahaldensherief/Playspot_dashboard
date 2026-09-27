BEGIN;

CREATE OR REPLACE FUNCTION public.resolve_live_request(
  p_request_type text,
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_type text := lower(btrim(COALESCE(p_request_type, '')));
  v_lounge_id uuid;
  v_booking_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_request_id IS NULL THEN
    RAISE EXCEPTION 'Request id is required' USING ERRCODE = '22023';
  END IF;

  IF v_type IN ('canteen', 'canteen_order') THEN
    SELECT co.lounge_id, co.booking_id
    INTO v_lounge_id, v_booking_id
    FROM public.canteen_orders AS co
    WHERE co.id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Canteen order not found' USING ERRCODE = 'P0002';
    END IF;

    IF NOT public.is_super_admin()
       AND NOT public.has_lounge_permission(v_lounge_id, 'pos_create_orders') THEN
      RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
    END IF;

    UPDATE public.canteen_orders
    SET status = 'completed',
        is_attended = true,
        is_read = true,
        updated_at = now()
    WHERE id = p_request_id;

    IF v_booking_id IS NOT NULL THEN
      UPDATE public.service_calls
      SET status = 'completed',
          is_attended = true,
          is_read = true,
          updated_at = now()
      WHERE booking_id = v_booking_id
        AND call_type = 'canteen_order'
        AND COALESCE(status, 'pending') NOT IN ('completed', 'resolved', 'cancelled');
    END IF;

  ELSIF v_type IN ('service', 'service_call', 'call_staff') THEN
    SELECT COALESCE(sc.lounge_id, b.lounge_id), sc.booking_id
    INTO v_lounge_id, v_booking_id
    FROM public.service_calls AS sc
    LEFT JOIN public.bookings AS b ON b.id = sc.booking_id
    WHERE sc.id = p_request_id
    FOR UPDATE OF sc;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Service call not found' USING ERRCODE = 'P0002';
    END IF;

    IF NOT public.is_super_admin()
       AND NOT public.has_lounge_permission(v_lounge_id, 'sessions_control') THEN
      RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
    END IF;

    UPDATE public.service_calls
    SET status = 'resolved',
        is_attended = true,
        is_read = true,
        updated_at = now()
    WHERE id = p_request_id;

  ELSIF v_type IN ('request', 'client_request') THEN
    SELECT cr.lounge_id, cr.booking_id
    INTO v_lounge_id, v_booking_id
    FROM public.client_requests AS cr
    WHERE cr.id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Client request not found' USING ERRCODE = 'P0002';
    END IF;

    IF NOT public.is_super_admin()
       AND NOT public.has_lounge_permission(v_lounge_id, 'sessions_control') THEN
      RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
    END IF;

    UPDATE public.client_requests
    SET status = 'resolved',
        is_attended = true,
        is_read = true
    WHERE id = p_request_id;

  ELSE
    RAISE EXCEPTION 'Unsupported request type' USING ERRCODE = '22023';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'request_type', v_type,
    'request_id', p_request_id,
    'lounge_id', v_lounge_id,
    'booking_id', v_booking_id
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.resolve_live_request(text, uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.resolve_live_request(text, uuid)
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
