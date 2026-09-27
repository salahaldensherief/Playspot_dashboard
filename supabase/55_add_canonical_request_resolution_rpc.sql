BEGIN;

CREATE OR REPLACE FUNCTION public.resolve_lounge_request(
  p_request_id uuid,
  p_request_type text,
  p_resolution text DEFAULT 'completed'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_type text := lower(btrim(COALESCE(p_request_type, '')));
  v_resolution text := lower(btrim(COALESCE(p_resolution, 'completed')));
  v_lounge_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_request_id IS NULL THEN
    RAISE EXCEPTION 'Request id is required' USING ERRCODE = '22023';
  END IF;

  IF v_type NOT IN ('service_call', 'canteen_order') THEN
    RAISE EXCEPTION 'Unsupported request type' USING ERRCODE = '22023';
  END IF;

  IF v_resolution NOT IN ('completed', 'resolved', 'cancelled') THEN
    RAISE EXCEPTION 'Unsupported request resolution' USING ERRCODE = '22023';
  END IF;

  IF v_type = 'service_call' THEN
    SELECT COALESCE(sc.lounge_id, b.lounge_id)
    INTO v_lounge_id
    FROM public.service_calls AS sc
    LEFT JOIN public.bookings AS b ON b.id = sc.booking_id
    WHERE sc.id = p_request_id
    FOR UPDATE OF sc;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Service request not found' USING ERRCODE = 'P0002';
    END IF;

    PERFORM private.assert_lounge_operator(v_lounge_id, true);

    UPDATE public.service_calls
    SET status = CASE
          WHEN v_resolution = 'cancelled' THEN 'cancelled'
          ELSE 'resolved'
        END,
        is_attended = true,
        is_read = true,
        updated_at = now()
    WHERE id = p_request_id;

    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'request_type', v_type,
      'status', CASE
        WHEN v_resolution = 'cancelled' THEN 'cancelled'
        ELSE 'resolved'
      END
    );
  END IF;

  SELECT COALESCE(co.lounge_id, b.lounge_id)
  INTO v_lounge_id
  FROM public.canteen_orders AS co
  LEFT JOIN public.bookings AS b ON b.id = co.booking_id
  WHERE co.id = p_request_id
  FOR UPDATE OF co;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Canteen order not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_lounge_id, true);

  UPDATE public.canteen_orders
  SET status = CASE
        WHEN v_resolution = 'cancelled' THEN 'cancelled'
        ELSE 'completed'
      END,
      is_attended = true,
      updated_at = now()
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'request_type', v_type,
    'status', CASE
      WHEN v_resolution = 'cancelled' THEN 'cancelled'
      ELSE 'completed'
    END
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.resolve_lounge_request(uuid, text, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.resolve_lounge_request(uuid, text, text)
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
