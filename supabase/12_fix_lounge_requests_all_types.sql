-- =============================================================================
-- 12_fix_lounge_requests_all_types.sql
-- Fix get_active_lounge_requests_page to match via bookings.lounge_id
-- and include all client request sources (service_calls, canteen_orders,
-- client_requests, booking_items)
-- =============================================================================

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
  v_offset := (p_page - 1) * p_page_size;

  WITH combined_requests AS (
    -- 1. Service Calls (Staff Calls, Assistance, etc.)
    SELECT
      'sc_' || sc.id AS id,
      COALESCE(sc.lounge_id, b.lounge_id) AS lounge_id,
      sc.booking_id,
      'service_call' AS type,
      sc.request_type,
      COALESCE(sc.notes, 'طلب خدمة من العميل') AS message,
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
    WHERE (sc.lounge_id = p_lounge_id OR b.lounge_id = p_lounge_id)
      AND (sc.is_attended IS NOT TRUE AND COALESCE(sc.status, 'pending') NOT IN ('resolved', 'completed', 'attended'))

    UNION ALL

    -- 2. Canteen Orders
    SELECT
      'canteen_' || co.id AS id,
      COALESCE(co.lounge_id, b.lounge_id) AS lounge_id,
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
    WHERE (co.lounge_id = p_lounge_id OR b.lounge_id = p_lounge_id)
      AND (co.status IN ('pending', 'new', 'in_progress') AND COALESCE(co.is_attended, false) IS NOT TRUE)

    UNION ALL

    -- 3. General Client Requests
    SELECT
      'req_' || cr.id AS id,
      COALESCE(cr.lounge_id, b.lounge_id) AS lounge_id,
      cr.booking_id,
      'client_request' AS type,
      cr.type AS request_type,
      COALESCE(cr.body_ar, cr.title_ar, 'طلب من العميل') AS message,
      COALESCE(cr.status, 'pending') AS status,
      cr.created_at,
      COALESCE(p.full_name, 'Guest') AS user_name,
      p.phone AS user_phone,
      COALESCE(r.name, 'Room') AS room_name,
      NULL::JSONB AS items
    FROM public.client_requests cr
    LEFT JOIN public.bookings b ON cr.booking_id = b.id
    LEFT JOIN public.profiles p ON cr.user_id = p.id OR b.user_id = p.id
    LEFT JOIN public.rooms r ON cr.room_id = r.id OR b.room_id = r.id
    WHERE (cr.lounge_id = p_lounge_id OR b.lounge_id = p_lounge_id)
      AND (cr.is_attended IS NOT TRUE AND COALESCE(cr.status, 'pending') NOT IN ('resolved', 'completed', 'attended'))

    UNION ALL

    -- 4. Booking Items (Extra snacks/items ordered during playing)
    SELECT
      'item_' || bi.id AS id,
      b.lounge_id,
      bi.booking_id,
      'canteen_order' AS type,
      'extra_item' AS request_type,
      bi.name AS message,
      COALESCE(bi.status, 'pending') AS status,
      bi.created_at,
      COALESCE(p.full_name, 'Guest') AS user_name,
      p.phone AS user_phone,
      COALESCE(r.name, 'Room') AS room_name,
      jsonb_build_array(jsonb_build_object('name', bi.name, 'quantity', bi.quantity, 'price', bi.price, 'total_price', bi.total_price)) AS items
    FROM public.booking_items bi
    JOIN public.bookings b ON bi.booking_id = b.id
    LEFT JOIN public.profiles p ON b.user_id = p.id
    LEFT JOIN public.rooms r ON b.room_id = r.id
    WHERE b.lounge_id = p_lounge_id
      AND (bi.status = 'pending' AND COALESCE(bi.is_attended, false) IS NOT TRUE)
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

GRANT EXECUTE ON FUNCTION public.get_active_lounge_requests_page TO authenticated, anon;
