BEGIN;

CREATE OR REPLACE FUNCTION public.get_lounge_owner_dashboard_stats(
  p_lounge_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_today_revenue numeric := 0;
  v_monthly_revenue numeric := 0;
  v_total_rooms integer := 0;
  v_occupied_rooms integer := 0;
  v_occupancy_rate numeric := 0;
  v_active_bookings integer := 0;
  v_open_shifts integer := 0;
  v_low_stock_items integer := 0;
  v_today date := (now() AT TIME ZONE 'Africa/Cairo')::date;
  v_month_start date := date_trunc(
    'month',
    now() AT TIME ZONE 'Africa/Cairo'
  )::date;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Invalid lounge_id parameter' USING ERRCODE = '22023';
  END IF;

  IF NOT (
    public.is_super_admin()
    OR private.can_operate_playspot_lounge(p_lounge_id)
    OR public.is_lounge_member_or_admin(p_lounge_id)
  ) THEN
    RAISE EXCEPTION 'Unauthorized: You do not have access to dashboard stats for this lounge'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(SUM(p.amount), 0)
  INTO v_today_revenue
  FROM public.payments AS p
  WHERE p.lounge_id = p_lounge_id
    AND p.status = 'completed'
    AND (p.paid_at AT TIME ZONE 'Africa/Cairo')::date = v_today;

  SELECT COALESCE(SUM(p.amount), 0)
  INTO v_monthly_revenue
  FROM public.payments AS p
  WHERE p.lounge_id = p_lounge_id
    AND p.status = 'completed'
    AND (p.paid_at AT TIME ZONE 'Africa/Cairo')::date >= v_month_start
    AND (p.paid_at AT TIME ZONE 'Africa/Cairo')::date <= v_today;

  SELECT COUNT(*)
  INTO v_total_rooms
  FROM public.rooms AS r
  WHERE r.lounge_id = p_lounge_id
    AND r.is_active IS TRUE
    AND COALESCE(r.status, 'available') <> 'deleted';

  SELECT COUNT(*)
  INTO v_occupied_rooms
  FROM public.rooms AS r
  WHERE r.lounge_id = p_lounge_id
    AND r.is_active IS TRUE
    AND r.status = 'occupied';

  SELECT COUNT(*)
  INTO v_active_bookings
  FROM public.bookings AS b
  WHERE b.lounge_id = p_lounge_id
    AND b.status = 'in_progress'::public.booking_status;

  SELECT COUNT(*)
  INTO v_open_shifts
  FROM public.shifts AS s
  WHERE s.lounge_id = p_lounge_id
    AND s.status = 'open'
    AND s.closed_at IS NULL;

  SELECT COUNT(*)
  INTO v_low_stock_items
  FROM public.extras AS e
  WHERE e.lounge_id = p_lounge_id
    AND e.is_active IS TRUE
    AND e.track_stock IS TRUE
    AND COALESCE(e.stock_quantity, 0) <= COALESCE(e.min_stock_alert, 0);

  IF v_total_rooms > 0 THEN
    v_occupancy_rate := ROUND(
      (v_occupied_rooms::numeric / v_total_rooms::numeric) * 100,
      1
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'lounge_id', p_lounge_id,
    'today_revenue', v_today_revenue,
    'monthly_revenue', v_monthly_revenue,
    'total_rooms', v_total_rooms,
    'occupied_rooms', v_occupied_rooms,
    'occupancy_rate', v_occupancy_rate,
    'active_bookings', v_active_bookings,
    'open_shifts', v_open_shifts,
    'low_stock_items', v_low_stock_items
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_lounge_owner_dashboard_stats(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_lounge_owner_dashboard_stats(uuid)
TO authenticated, service_role, supabase_auth_admin;

CREATE OR REPLACE FUNCTION public.get_revenue_over_time(
  p_lounge_id uuid DEFAULT NULL,
  p_period text DEFAULT 'month'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_is_super boolean := false;
  v_user_lounge_id uuid;
  v_target_lounge_id uuid;
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_period NOT IN ('day', 'week', 'month', 'quarter', 'year') THEN
    RAISE EXCEPTION 'Unsupported revenue period' USING ERRCODE = '22023';
  END IF;

  SELECT
    (p.role = 'super_admin'),
    p.lounge_id
  INTO v_is_super, v_user_lounge_id
  FROM public.profiles AS p
  WHERE p.id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found' USING ERRCODE = '42501';
  END IF;

  IF v_is_super THEN
    v_target_lounge_id := p_lounge_id;
  ELSE
    v_target_lounge_id := COALESCE(p_lounge_id, v_user_lounge_id);
    IF v_target_lounge_id IS NULL
       OR NOT private.is_lounge_member(v_target_lounge_id) THEN
      RAISE EXCEPTION 'Not authorized for this lounge' USING ERRCODE = '42501';
    END IF;
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'period', x.period,
        'revenue', x.revenue
      )
      ORDER BY x.period
    ),
    '[]'::jsonb
  )
  INTO v_result
  FROM (
    SELECT
      date_trunc(p_period, p.paid_at AT TIME ZONE 'Africa/Cairo') AS period,
      SUM(p.amount)::numeric AS revenue
    FROM public.payments AS p
    WHERE p.status = 'completed'
      AND (
        v_target_lounge_id IS NULL
        OR p.lounge_id = v_target_lounge_id
      )
    GROUP BY 1
  ) AS x;

  RETURN v_result;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_revenue_over_time(uuid, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_revenue_over_time(uuid, text)
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
