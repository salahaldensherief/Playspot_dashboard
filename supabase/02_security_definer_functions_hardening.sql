-- =============================================================================
-- 02_security_definer_functions_hardening.sql
-- Hardening SECURITY DEFINER RPCs with Authentication & Authorization Checks
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Helper Security Functions (With Fixed search_path)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.platform_super_admins
    WHERE user_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (role = 'super_admin' OR role = 'superadmin')
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_lounge_admin(p_lounge_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN public.is_super_admin() OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (lounge_id = p_lounge_id OR role IN ('owner', 'manager', 'admin'))
  ) OR EXISTS (
    SELECT 1 FROM public.lounges
    WHERE id = p_lounge_id AND owner_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM public.lounge_staff
    WHERE lounge_id = p_lounge_id AND user_id = auth.uid()
  );
END;
$$;

-- REVOKE EXECUTE FROM PUBLIC / anon FOR ADMIN HELPERS
REVOKE EXECUTE ON FUNCTION public.is_super_admin FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_super_admin TO authenticated;

REVOKE EXECUTE ON FUNCTION public.is_lounge_admin FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_lounge_admin TO authenticated;


-- -----------------------------------------------------------------------------
-- 2. Global Dashboard Overview RPC (Super Admin Only)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_dashboard_overview()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_total_revenue NUMERIC := 0;
  v_total_bookings INT := 0;
  v_total_lounges INT := 0;
  v_total_users INT := 0;
BEGIN
  -- Strict Authorization: Only Super Admin allowed
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Global overview requires Super Admin privilege' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(SUM(total_price), 0) INTO v_total_revenue
  FROM public.bookings
  WHERE status != 'cancelled';

  SELECT COUNT(*) INTO v_total_bookings FROM public.bookings;
  SELECT COUNT(*) INTO v_total_lounges FROM public.lounges WHERE status != 'deleted';
  SELECT COUNT(*) INTO v_total_users FROM public.profiles;

  RETURN jsonb_build_object(
    'total_revenue', v_total_revenue,
    'total_bookings', v_total_bookings,
    'total_lounges', v_total_lounges,
    'total_users', v_total_users
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_dashboard_overview() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_dashboard_overview() TO authenticated;


-- -----------------------------------------------------------------------------
-- 3. Lounge Owner Dashboard Stats RPC (Lounge Owner / Staff / Super Admin)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_lounge_owner_dashboard_stats(
  p_lounge_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
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

  -- Authorization Check
  IF NOT public.is_lounge_admin(p_lounge_id) THEN
    RAISE EXCEPTION 'Unauthorized: You do not have access to dashboard stats for this lounge' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(SUM(total_price), 0) INTO v_total_revenue
  FROM public.bookings
  WHERE lounge_id = p_lounge_id AND status != 'cancelled';

  SELECT COUNT(*) INTO v_total_bookings
  FROM public.bookings
  WHERE lounge_id = p_lounge_id;

  SELECT COUNT(DISTINCT room_id) INTO v_active_rooms
  FROM public.bookings
  WHERE lounge_id = p_lounge_id AND status = 'in_progress';

  SELECT COUNT(*) INTO v_total_rooms
  FROM public.rooms
  WHERE lounge_id = p_lounge_id;

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
$$;

REVOKE EXECUTE ON FUNCTION public.get_lounge_owner_dashboard_stats(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_lounge_owner_dashboard_stats(UUID) TO authenticated;


-- -----------------------------------------------------------------------------
-- 4. Live Bookings With Items RPC (Authorized Lounge Staff / Admin)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_live_bookings_with_items(
  p_lounge_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Invalid lounge_id parameter';
  END IF;

  -- Authorization Check
  IF NOT public.is_lounge_admin(p_lounge_id) THEN
    RAISE EXCEPTION 'Unauthorized: You do not have permission to view live bookings for this lounge' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', b.id,
      'lounge_id', b.lounge_id,
      'user_id', b.user_id,
      'room_id', b.room_id,
      'start_time', b.start_time,
      'end_time', b.end_time,
      'duration_minutes', b.duration_minutes,
      'total_price', b.total_price,
      'addons_price', b.addons_price,
      'status', b.status,
      'created_at', b.created_at,
      'user_name', COALESCE(p.full_name, 'Guest'),
      'user_phone', p.phone,
      'room_name', COALESCE(r.name, 'Room'),
      'canteen_orders', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', co.id,
            'items', co.items,
            'total_price', co.total_price,
            'status', co.status,
            'created_at', co.created_at
          )
        ), '[]'::jsonb)
        FROM public.canteen_orders co
        WHERE co.booking_id = b.id
      )
    )
  ), '[]'::jsonb) INTO v_result
  FROM public.bookings b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id
  WHERE b.lounge_id = p_lounge_id AND b.status = 'in_progress'
  ORDER BY b.created_at DESC;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_live_bookings_with_items(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_live_bookings_with_items(UUID) TO authenticated;


-- -----------------------------------------------------------------------------
-- 5. Active Lounge Requests Page RPC (Authorized Staff Only)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_active_lounge_requests_page(
  p_lounge_id UUID,
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_offset INT;
  v_result JSONB;
  v_total INT;
BEGIN
  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Invalid lounge_id parameter';
  END IF;

  -- Authorization Check
  IF NOT public.is_lounge_admin(p_lounge_id) THEN
    RAISE EXCEPTION 'Unauthorized: You do not have permission to view active requests for this lounge' USING ERRCODE = '42501';
  END IF;

  v_offset := (p_page - 1) * p_page_size;

  WITH combined_requests AS (
    SELECT
      'sc_' || sc.id AS id,
      sc.lounge_id,
      sc.booking_id,
      'service_call' AS type,
      sc.request_type,
      sc.notes AS message,
      COALESCE(sc.status, 'pending') AS status,
      sc.created_at,
      COALESCE(p.full_name, 'Guest') AS user_name,
      p.phone AS user_phone,
      COALESCE(r.name, 'Room') AS room_name,
      NULL::JSONB AS items
    FROM public.service_calls sc
    LEFT JOIN public.bookings b ON sc.booking_id = b.id
    LEFT JOIN public.profiles p ON sc.user_id = p.id OR b.user_id = p.id
    LEFT JOIN public.rooms r ON sc.room_id = r.id OR b.room_id = r.id
    WHERE sc.lounge_id = p_lounge_id AND (sc.is_attended IS NOT TRUE AND sc.status != 'resolved')

    UNION ALL

    SELECT
      'canteen_' || co.id AS id,
      co.lounge_id,
      co.booking_id,
      'canteen_order' AS type,
      'canteen' AS request_type,
      'طلب كافيتريا' AS message,
      COALESCE(co.status, 'pending') AS status,
      co.created_at,
      COALESCE(p.full_name, 'Guest') AS user_name,
      p.phone AS user_phone,
      COALESCE(r.name, 'Room') AS room_name,
      co.items AS items
    FROM public.canteen_orders co
    LEFT JOIN public.bookings b ON co.booking_id = b.id
    LEFT JOIN public.profiles p ON co.user_id = p.id OR b.user_id = p.id
    LEFT JOIN public.rooms r ON b.room_id = r.id
    WHERE co.lounge_id = p_lounge_id AND (co.status = 'pending' OR co.status = 'new')
  )
  SELECT COUNT(*) INTO v_total FROM combined_requests;

  SELECT COALESCE(jsonb_build_object(
    'items', COALESCE(jsonb_agg(t), '[]'::jsonb),
    'total_count', v_total,
    'page', p_page,
    'page_size', p_page_size
  ), '{}'::jsonb) INTO v_result
  FROM (
    SELECT * FROM combined_requests
    ORDER BY created_at DESC
    LIMIT p_page_size OFFSET v_offset
  ) t;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_active_lounge_requests_page(UUID, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_active_lounge_requests_page(UUID, INT, INT) TO authenticated;


-- -----------------------------------------------------------------------------
-- 6. Place Canteen Order RPC (Authenticated & Owner/Staff or Customer of Booking)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.place_canteen_order(
  p_booking_id UUID,
  p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_lounge_id UUID;
  v_booking_user_id UUID;
  v_current_user_id UUID;
  v_order_id UUID;
  v_item JSONB;
  v_item_id UUID;
  v_qty INT;
  v_price NUMERIC;
  v_calculated_total NUMERIC := 0;
BEGIN
  v_current_user_id := auth.uid();
  IF v_current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated user request');
  END IF;

  IF p_booking_id IS NULL OR p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid input parameters');
  END IF;

  -- Fetch lounge_id and user_id from bookings
  SELECT lounge_id, user_id INTO v_lounge_id, v_booking_user_id
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_lounge_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Booking not found');
  END IF;

  -- Verify User Identity: Either the booking customer or lounge staff/admin
  IF v_current_user_id != v_booking_user_id AND NOT public.is_lounge_admin(v_lounge_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unauthorized to place canteen order for this booking');
  END IF;

  -- Loop through items to calculate total and reduce stock
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_item_id := (v_item->>'id')::UUID;
    v_qty := COALESCE((v_item->>'quantity')::INT, (v_item->>'qty')::INT, 1);
    v_price := COALESCE((v_item->>'price')::NUMERIC, (v_item->>'unit_price')::NUMERIC, 0);

    v_calculated_total := v_calculated_total + (v_price * v_qty);

    -- Reduce stock in extras if track_stock is enabled
    IF v_item_id IS NOT NULL THEN
      UPDATE public.extras
      SET stock_quantity = GREATEST(0, stock_quantity - v_qty),
          is_available = CASE
            WHEN track_stock = true AND (stock_quantity - v_qty) <= 0 THEN false
            ELSE is_available
          END
      WHERE id = v_item_id AND track_stock = true;
    END IF;
  END LOOP;

  -- Insert into canteen_orders table
  INSERT INTO public.canteen_orders (
    lounge_id,
    booking_id,
    user_id,
    items,
    total_price,
    status,
    created_at
  )
  VALUES (
    v_lounge_id,
    p_booking_id,
    v_booking_user_id,
    p_items,
    v_calculated_total,
    'completed',
    NOW()
  )
  RETURNING id INTO v_order_id;

  -- Atomically update total_price & addons_price on bookings
  UPDATE public.bookings
  SET
    total_price = COALESCE(total_price, 0) + v_calculated_total,
    addons_price = COALESCE(addons_price, 0) + v_calculated_total,
    updated_at = NOW()
  WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'total_price', v_calculated_total
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.place_canteen_order(UUID, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.place_canteen_order(UUID, JSONB) TO authenticated;
