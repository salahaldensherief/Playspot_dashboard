-- Migration 18: Include receipt_url & wallet details in Booking RPC payloads

-- 1. Update get_all_bookings_admin RPC
CREATE OR REPLACE FUNCTION public.get_all_bookings_admin(
  p_lounge_id UUID DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', b.id,
      'out_booking_id', b.id,
      'user_id', b.user_id,
      'lounge_id', b.lounge_id,
      'room_id', b.room_id,
      'user_name', COALESCE(b.user_name, p.full_name, 'Walk-in Customer'),
      'user_phone', COALESCE(b.user_phone, p.phone),
      'user_email', COALESCE(b.user_email, p.email),
      'room_name', COALESCE(r.name_ar, r.name_en, r.name, 'Room'),
      'out_room_name', COALESCE(r.name_ar, r.name_en, r.name, 'Room'),
      'controllers_count', r.controllers_count,
      'screen_size', r.screen_size,
      'out_booking_date', b.date,
      'date', b.date,
      'out_start_time', b.start_time,
      'start_time', b.start_time,
      'out_end_time', b.end_time,
      'end_time', b.end_time,
      'duration_minutes', b.duration_minutes,
      'status', b.status,
      'out_booking_status', b.status,
      'payment_status', b.payment_status,
      'out_payment_status', b.payment_status,
      'payment_method', b.payment_method,
      'out_payment_method', b.payment_method,
      'total_price', b.total_price,
      'out_total_price', b.total_price,
      'addons_price', b.addons_price,
      'out_addons_price', b.addons_price,
      'voucher_discount', b.voucher_discount,
      'voucher_code', b.voucher_code,
      'discount_amount', b.discount_amount,
      'discount_percentage', b.discount_percentage,
      'discount_reason', b.discount_reason,
      'play_mode', b.play_mode,
      'room_price', b.room_price,
      'shift_id', b.shift_id,
      'created_at', b.created_at,
      'checked_in_at', b.checked_in_at,
      'receipt_url', b.receipt_url,
      'out_receipt_url', b.receipt_url,
      'sender_wallet_phone', b.sender_wallet_phone,
      'expires_at', b.expires_at,
      'out_expires_at', b.expires_at,
      'rejection_reason', b.rejection_reason,
      'cancellation_reason', b.cancellation_reason,
      'cancelled_by', b.cancelled_by,
      'cancelled_at', b.cancelled_at,
      'out_visit_number', b.visit_num,
      'visit_number', b.visit_num,
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
      ),
      'extras', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', bi.id,
            'extra_id', bi.extra_id,
            'name', bi.name,
            'quantity', bi.quantity,
            'unit_price', bi.unit_price,
            'total_price', bi.total_price,
            'status', bi.status
          )
        ), '[]'::jsonb)
        FROM public.booking_items bi
        WHERE bi.booking_id = b.id
      )
    )
  ), '[]'::jsonb) INTO v_result
  FROM (
    SELECT
      bk.*,
      DENSE_RANK() OVER (
        PARTITION BY
          CASE
            WHEN bk.user_id IS NOT NULL AND TRIM(bk.user_id::text) != '' THEN bk.user_id::text
            WHEN bk.user_phone IS NOT NULL AND TRIM(bk.user_phone) != '' AND bk.user_phone != 'null' AND bk.user_phone != 'No Phone' THEN TRIM(bk.user_phone)
            ELSE bk.id::text
          END
        ORDER BY bk.created_at ASC
      ) AS visit_num
    FROM public.bookings bk
    WHERE (p_lounge_id IS NULL OR bk.lounge_id = p_lounge_id)
      AND (p_status IS NULL OR bk.status = p_status)
    ORDER BY bk.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_all_bookings_admin(UUID, TEXT, INT, INT) TO authenticated, anon;


-- 2. Update get_lounge_bookings_page RPC
CREATE OR REPLACE FUNCTION public.get_lounge_bookings_page(
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
  v_offset INT := ((GREATEST(p_page, 1) - 1) * GREATEST(p_page_size, 1));
  v_total_count INT;
  v_result JSONB;
BEGIN
  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'p_lounge_id cannot be NULL';
  END IF;

  SELECT COUNT(*) INTO v_total_count
  FROM public.bookings
  WHERE lounge_id = p_lounge_id;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'total_count', v_total_count,
      'page', GREATEST(p_page, 1),
      'page_size', GREATEST(p_page_size, 1),
      'data', jsonb_build_object(
        'id', b.id,
        'out_booking_id', b.id,
        'user_id', b.user_id,
        'lounge_id', b.lounge_id,
        'room_id', b.room_id,
        'user_name', COALESCE(b.user_name, p.full_name, 'Walk-in Customer'),
        'user_phone', COALESCE(b.user_phone, p.phone),
        'user_email', COALESCE(b.user_email, p.email),
        'room_name', COALESCE(r.name_ar, r.name_en, r.name, 'Room'),
        'out_room_name', COALESCE(r.name_ar, r.name_en, r.name, 'Room'),
        'controllers_count', r.controllers_count,
        'screen_size', r.screen_size,
        'out_booking_date', b.date,
        'date', b.date,
        'out_start_time', b.start_time,
        'start_time', b.start_time,
        'out_end_time', b.end_time,
        'end_time', b.end_time,
        'duration_minutes', b.duration_minutes,
        'status', b.status,
        'out_booking_status', b.status,
        'payment_status', b.payment_status,
        'out_payment_status', b.payment_status,
        'payment_method', b.payment_method,
        'out_payment_method', b.payment_method,
        'total_price', b.total_price,
        'out_total_price', b.total_price,
        'addons_price', b.addons_price,
        'out_addons_price', b.addons_price,
        'voucher_discount', b.voucher_discount,
        'voucher_code', b.voucher_code,
        'discount_amount', b.discount_amount,
        'discount_percentage', b.discount_percentage,
        'discount_reason', b.discount_reason,
        'play_mode', b.play_mode,
        'room_price', b.room_price,
        'shift_id', b.shift_id,
        'created_at', b.created_at,
        'checked_in_at', b.checked_in_at,
        'receipt_url', b.receipt_url,
        'out_receipt_url', b.receipt_url,
        'sender_wallet_phone', b.sender_wallet_phone,
        'expires_at', b.expires_at,
        'out_expires_at', b.expires_at,
        'rejection_reason', b.rejection_reason,
        'cancellation_reason', b.cancellation_reason,
        'cancelled_by', b.cancelled_by,
        'cancelled_at', b.cancelled_at,
        'out_visit_number', b.visit_num,
        'visit_number', b.visit_num,
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
        ),
        'extras', (
          SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
              'id', bi.id,
              'extra_id', bi.extra_id,
              'name', bi.name,
              'quantity', bi.quantity,
              'unit_price', bi.unit_price,
              'total_price', bi.total_price,
              'status', bi.status
            )
          ), '[]'::jsonb)
          FROM public.booking_items bi
          WHERE bi.booking_id = b.id
        )
      )
    )
  ), '[]'::jsonb) INTO v_result
  FROM (
    SELECT
      bk.*,
      DENSE_RANK() OVER (
        PARTITION BY
          CASE
            WHEN bk.user_id IS NOT NULL AND TRIM(bk.user_id::text) != '' THEN bk.user_id::text
            WHEN bk.user_phone IS NOT NULL AND TRIM(bk.user_phone) != '' AND bk.user_phone != 'null' AND bk.user_phone != 'No Phone' THEN TRIM(bk.user_phone)
            ELSE bk.id::text
          END
        ORDER BY bk.created_at ASC
      ) AS visit_num
    FROM public.bookings bk
    WHERE bk.lounge_id = p_lounge_id
    ORDER BY bk.created_at DESC
    LIMIT p_page_size
    OFFSET v_offset
  ) b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_lounge_bookings_page(UUID, INT, INT) TO authenticated, anon;


-- 3. Update get_live_bookings_with_items RPC
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

  IF NOT public.is_lounge_admin(p_lounge_id) THEN
    RAISE EXCEPTION 'Unauthorized: You do not have permission to view live bookings for this lounge' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', b.id,
      'out_booking_id', b.id,
      'lounge_id', b.lounge_id,
      'user_id', b.user_id,
      'room_id', b.room_id,
      'start_time', b.start_time,
      'end_time', b.end_time,
      'duration_minutes', b.duration_minutes,
      'total_price', b.total_price,
      'addons_price', b.addons_price,
      'status', b.status,
      'payment_status', b.payment_status,
      'payment_method', b.payment_method,
      'receipt_url', b.receipt_url,
      'out_receipt_url', b.receipt_url,
      'sender_wallet_phone', b.sender_wallet_phone,
      'expires_at', b.expires_at,
      'created_at', b.created_at,
      'user_name', COALESCE(b.user_name, p.full_name, 'Walk-in Customer'),
      'user_phone', COALESCE(b.user_phone, p.phone),
      'room_name', COALESCE(r.name_ar, r.name_en, r.name, 'Room'),
      'visit_number', b.visit_num,
      'out_visit_number', b.visit_num,
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
  FROM (
    SELECT
      bk.*,
      DENSE_RANK() OVER (
        PARTITION BY
          CASE
            WHEN bk.user_id IS NOT NULL AND TRIM(bk.user_id::text) != '' THEN bk.user_id::text
            WHEN bk.user_phone IS NOT NULL AND TRIM(bk.user_phone) != '' AND bk.user_phone != 'null' AND bk.user_phone != 'No Phone' THEN TRIM(bk.user_phone)
            ELSE bk.id::text
          END
        ORDER BY bk.created_at ASC
      ) AS visit_num
    FROM public.bookings bk
    WHERE bk.lounge_id = p_lounge_id AND bk.status = 'in_progress'
    ORDER BY bk.created_at DESC
  ) b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_live_bookings_with_items(UUID) TO authenticated, anon;
