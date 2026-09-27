-- 41_fix_booking_enum_cast_and_live_session_permission.sql
-- Fixes runtime issues reported by live app log:
-- 1. Explicitly casts bk.status::text in get_all_bookings_admin to resolve 'operator does not exist: booking_status = text'.
-- 2. Permits authorized lounge staff (cashiers, managers, lounge operators) in get_live_bookings_with_items.

CREATE OR REPLACE FUNCTION public.get_all_bookings_admin(
  p_lounge_id uuid DEFAULT NULL::uuid,
  p_status text DEFAULT NULL::text,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_role text;
  v_own_lounge uuid;
  v_target_lounge uuid;
  v_result JSONB;
BEGIN
  SELECT role, lounge_id INTO v_role, v_own_lounge
  FROM public.profiles
  WHERE id = auth.uid();

  IF v_role IS NULL OR (v_role <> 'super_admin' AND v_own_lounge IS NULL) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF v_role = 'super_admin' THEN
    v_target_lounge := p_lounge_id;
  ELSE
    IF p_lounge_id IS NOT NULL AND p_lounge_id <> v_own_lounge THEN
      RAISE EXCEPTION 'Not authorized';
    END IF;
    v_target_lounge := v_own_lounge;
  END IF;

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
      'voucher_code', b.voucher_code,
      'discount_amount', b.discount_amount,
      'discount_percentage', b.discount_percentage,
      'discount_reason', b.discount_reason,
      'play_mode', b.play_mode,
      'room_price', b.room_price,
      'shift_id', b.shift_id,
      'created_at', b.created_at,
      'checked_in_at', b.checked_in_at,
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
    SELECT bk.*
    FROM public.bookings bk
    WHERE (v_target_lounge IS NULL OR bk.lounge_id = v_target_lounge)
      AND (p_status IS NULL OR p_status = '' OR bk.status::text = p_status)
    ORDER BY bk.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id;

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_live_bookings_with_items(p_lounge_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Invalid lounge_id parameter';
  END IF;

  IF NOT (public.is_super_admin() OR private.can_operate_playspot_lounge(p_lounge_id) OR public.is_lounge_member_or_admin(p_lounge_id)) THEN
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
    WHERE bk.lounge_id = p_lounge_id AND bk.status = 'in_progress'::booking_status
    ORDER BY bk.created_at DESC
  ) b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id;

  RETURN v_result;
END;
$function$;
