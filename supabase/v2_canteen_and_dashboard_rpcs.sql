-- ============================================================================
-- PLAYSPOT FULL SYSTEM MIGRATION: RLS, Security, Triggers, & RPC Fixes
-- Execute this script in Supabase SQL Editor (https://supabase.com/dashboard)
-- ============================================================================

-- 0. Dynamic Cleanup: Drop ALL overloaded versions of existing functions unambiguously
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT pg_proc.oid::regprocedure AS func_signature
    FROM pg_proc
    JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
    WHERE pg_namespace.nspname = 'public'
      AND proname IN (
        'is_super_admin',
        'is_lounge_admin',
        'place_canteen_order',
        'get_lounge_owner_dashboard_stats',
        'get_dashboard_overview',
        'get_live_bookings_with_items',
        'get_pending_extension_requests',
        'get_active_lounge_requests_page'
      )
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.func_signature || ' CASCADE';
  END LOOP;
END $$;

-- 1. Helper Security Functions (SECURITY DEFINER guarantees execution without RLS loops)
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
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
AS $$
BEGIN
  RETURN public.is_super_admin() OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (lounge_id = p_lounge_id OR role IN ('owner', 'manager', 'admin'))
  ) OR EXISTS (
    SELECT 1 FROM public.lounges
    WHERE id = p_lounge_id AND owner_id = auth.uid()
  );
END;
$$;

-- Grant execution permissions for helpers
GRANT EXECUTE ON FUNCTION public.is_super_admin TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_lounge_admin TO authenticated, anon;

-- 2. Schema Grants for Tables & Sequences
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated, anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO authenticated, anon;

-- 3. Atomic Canteen Order RPC with Stock Reduction & Booking Totals Update
CREATE OR REPLACE FUNCTION public.place_canteen_order(
  p_booking_id UUID,
  p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_lounge_id UUID;
  v_user_id UUID;
  v_order_id UUID;
  v_item JSONB;
  v_item_id UUID;
  v_qty INT;
  v_price NUMERIC;
  v_calculated_total NUMERIC := 0;
BEGIN
  IF p_booking_id IS NULL OR p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid input parameters');
  END IF;

  -- Fetch lounge_id and user_id from bookings
  SELECT lounge_id, user_id INTO v_lounge_id, v_user_id
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_lounge_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Booking not found');
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
    v_user_id,
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

-- 4. Lounge Owner Dashboard Stats RPC
CREATE OR REPLACE FUNCTION public.get_lounge_owner_dashboard_stats(
  p_lounge_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_revenue NUMERIC := 0;
  v_total_bookings INT := 0;
  v_active_rooms INT := 0;
  v_total_rooms INT := 0;
  v_occupancy_rate NUMERIC := 0;
BEGIN
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

-- 5. Global Dashboard Overview RPC
CREATE OR REPLACE FUNCTION public.get_dashboard_overview()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_revenue NUMERIC := 0;
  v_total_bookings INT := 0;
  v_total_lounges INT := 0;
  v_total_users INT := 0;
BEGIN
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

-- 6. Live Bookings With Items RPC
CREATE OR REPLACE FUNCTION public.get_live_bookings_with_items(
  p_lounge_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
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

-- 7. Pending Extension Requests RPC (Fixes Notification & Request Feeds)
CREATE OR REPLACE FUNCTION public.get_pending_extension_requests()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', 'ext_' || b.id,
      'booking_id', b.id,
      'lounge_id', b.lounge_id,
      'room_id', b.room_id,
      'room_name', COALESCE(r.name, 'Room'),
      'user_name', COALESCE(p.full_name, 'Guest'),
      'user_phone', p.phone,
      'requested_minutes', COALESCE(b.extension_minutes, 30),
      'extension_minutes', COALESCE(b.extension_minutes, 30),
      'extension_cost', COALESCE(b.extension_cost, 0),
      'status', COALESCE(b.extension_status, 'pending'),
      'created_at', COALESCE(b.updated_at, b.created_at)
    )
  ), '[]'::jsonb) INTO v_result
  FROM public.bookings b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id
  WHERE b.extension_status = 'pending';

  RETURN v_result;
END;
$$;

-- 8. Active Lounge Requests Page RPC (Combines Service Calls & Canteen Orders)
CREATE OR REPLACE FUNCTION public.get_active_lounge_requests_page(
  p_lounge_id UUID,
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_result JSONB;
  v_total INT;
BEGIN
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

-- Explicit Grants on RPCs
GRANT EXECUTE ON FUNCTION public.place_canteen_order TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_lounge_owner_dashboard_stats TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_dashboard_overview TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_live_bookings_with_items TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_pending_extension_requests TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_active_lounge_requests_page TO authenticated, anon;
