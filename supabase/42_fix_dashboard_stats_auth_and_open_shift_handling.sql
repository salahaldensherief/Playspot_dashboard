-- 42_fix_dashboard_stats_auth_and_open_shift_handling.sql
-- Fixes:
-- 1. get_lounge_owner_dashboard_stats: Authorizes cashiers and lounge staff operators (private.can_operate_playspot_lounge) to view dashboard stats for their assigned lounge.
-- 2. open_lounge_shift & open_shift: Returns existing active open shift for a lounge if one is already open, preventing 23505 duplicate key violations on unique constraint "shifts_one_open_per_lounge_idx".

CREATE OR REPLACE FUNCTION public.get_lounge_owner_dashboard_stats(p_lounge_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_total_revenue NUMERIC := 0;
  v_total_bookings INT := 0;
  v_active_rooms INT := 0;
  v_total_rooms INT := 0;
  v_occupancy_rate NUMERIC := 0;
BEGIN
  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Invalid lounge_id parameter';
  END IF;

  IF NOT (public.is_super_admin() OR private.can_operate_playspot_lounge(p_lounge_id) OR public.is_lounge_member_or_admin(p_lounge_id)) THEN
    RAISE EXCEPTION 'Unauthorized: You do not have access to dashboard stats for this lounge' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(SUM(total_price), 0) INTO v_total_revenue
  FROM public.bookings
  WHERE lounge_id = p_lounge_id AND status::text != 'cancelled';

  SELECT COUNT(*) INTO v_total_bookings
  FROM public.bookings
  WHERE lounge_id = p_lounge_id;

  SELECT COUNT(DISTINCT room_id) INTO v_active_rooms
  FROM public.bookings
  WHERE lounge_id = p_lounge_id AND status = 'in_progress'::booking_status;

  SELECT COUNT(*) INTO v_total_rooms
  FROM public.rooms
  WHERE lounge_id = p_lounge_id AND is_active = true;

  IF v_total_rooms > 0 THEN
    v_occupancy_rate := ROUND((v_active_rooms::NUMERIC / v_total_rooms::NUMERIC) * 100, 1);
  END IF;

  RETURN jsonb_build_object(
    'total_revenue', v_total_revenue,
    'total_bookings', v_total_bookings,
    'active_rooms', v_active_rooms,
    'total_rooms', v_total_rooms,
    'occupancy_rate', v_occupancy_rate
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.open_lounge_shift(p_lounge_id uuid, p_starting_cash numeric DEFAULT 0, p_notes text DEFAULT NULL::text)
 RETURNS shifts
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_shift public.shifts%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required' USING ERRCODE = '28000';
  END IF;

  IF NOT (public.is_super_admin() OR private.can_operate_playspot_lounge(p_lounge_id) OR public.is_lounge_member_or_admin(p_lounge_id)) THEN
    RAISE EXCEPTION 'You are not allowed to open a shift for this lounge' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_shift
  FROM public.shifts
  WHERE lounge_id = p_lounge_id AND status = 'open' AND closed_at IS NULL
  ORDER BY opened_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN v_shift;
  END IF;

  INSERT INTO public.shifts (
    lounge_id,
    staff_user_id,
    cashier_id,
    status,
    starting_cash,
    notes,
    opened_at,
    start_time
  )
  VALUES (
    p_lounge_id,
    auth.uid(),
    auth.uid(),
    'open',
    GREATEST(COALESCE(p_starting_cash, 0), 0),
    p_notes,
    now(),
    now()
  )
  RETURNING * INTO v_shift;

  RETURN v_shift;
EXCEPTION
  WHEN unique_violation THEN
    SELECT * INTO v_shift
    FROM public.shifts
    WHERE lounge_id = p_lounge_id AND status = 'open' AND closed_at IS NULL
    ORDER BY opened_at DESC
    LIMIT 1;
    RETURN v_shift;
END;
$function$;

CREATE OR REPLACE FUNCTION public.open_shift(p_lounge_id uuid, p_opening_cash numeric)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_new public.shifts%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF NOT (public.is_super_admin() OR private.can_operate_playspot_lounge(p_lounge_id) OR public.is_lounge_member_or_admin(p_lounge_id)) THEN
    RAISE EXCEPTION 'You are not allowed to open a shift for this lounge' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_new
  FROM public.shifts
  WHERE lounge_id = p_lounge_id AND status = 'open' AND closed_at IS NULL
  ORDER BY opened_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN json_build_object(
      'id', v_new.id,
      'lounge_id', v_new.lounge_id,
      'cashier_id', v_new.cashier_id,
      'starting_cash', v_new.starting_cash,
      'status', v_new.status,
      'opened_at', v_new.opened_at
    );
  END IF;

  INSERT INTO public.shifts (lounge_id, cashier_id, staff_user_id, starting_cash, status, start_time, opened_at)
  VALUES (p_lounge_id, auth.uid(), auth.uid(), COALESCE(p_opening_cash, 0), 'open', now(), now())
  RETURNING * INTO v_new;

  RETURN json_build_object(
    'id', v_new.id,
    'lounge_id', v_new.lounge_id,
    'cashier_id', v_new.cashier_id,
    'starting_cash', v_new.starting_cash,
    'status', v_new.status,
    'opened_at', v_new.opened_at
  );
EXCEPTION
  WHEN unique_violation THEN
    SELECT * INTO v_new
    FROM public.shifts
    WHERE lounge_id = p_lounge_id AND status = 'open' AND closed_at IS NULL
    ORDER BY opened_at DESC
    LIMIT 1;

    RETURN json_build_object(
      'id', v_new.id,
      'lounge_id', v_new.lounge_id,
      'cashier_id', v_new.cashier_id,
      'starting_cash', v_new.starting_cash,
      'status', v_new.status,
      'opened_at', v_new.opened_at
    );
END;
$function$;
