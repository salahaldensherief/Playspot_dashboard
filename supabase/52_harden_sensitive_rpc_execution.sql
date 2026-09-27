-- CI baseline: platform hardening safety net
BEGIN;

REVOKE EXECUTE ON FUNCTION public.create_lounge_admin(uuid, text, text, text)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.create_lounge_admin(uuid, text, text, text)
TO service_role, supabase_auth_admin;


REVOKE EXECUTE ON FUNCTION public.create_lounge_with_admin(
  text, text, text, text, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.create_lounge_with_admin(
  text, text, text, text, text
) TO authenticated, service_role, supabase_auth_admin;

REVOKE EXECUTE ON FUNCTION public.get_all_bookings_admin(
  uuid, text, integer, integer
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_all_bookings_admin(
  uuid, text, integer, integer
) TO authenticated, service_role, supabase_auth_admin;

REVOKE EXECUTE ON FUNCTION public.get_current_user_role()
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_current_user_role()
TO authenticated, service_role, supabase_auth_admin;

REVOKE EXECUTE ON FUNCTION public.is_lounge_member_or_admin(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_lounge_member_or_admin(uuid)
TO authenticated, service_role, supabase_auth_admin;

CREATE OR REPLACE FUNCTION public.broadcast_promo_notification(
  p_promo_id uuid,
  p_lounge_id uuid,
  p_title_ar text,
  p_title_en text,
  p_body_ar text,
  p_body_en text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_count integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  PERFORM private.assert_lounge_operator(p_lounge_id, false);

  WITH inserted_rows AS (
    INSERT INTO public.notifications (
      user_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      metadata,
      is_read,
      created_at
    )
    SELECT
      p.id,
      p_title_ar,
      p_title_en,
      p_body_ar,
      p_body_en,
      'offer',
      jsonb_build_object('promo_id', p_promo_id, 'lounge_id', p_lounge_id),
      false,
      now()
    FROM public.profiles AS p
    WHERE p.is_active = true
    RETURNING id
  )
  SELECT count(*) INTO v_count
  FROM inserted_rows;

  RETURN v_count;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.broadcast_promo_notification(
  uuid, uuid, text, text, text, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.broadcast_promo_notification(
  uuid, uuid, text, text, text, text
) TO authenticated, service_role, supabase_auth_admin;

CREATE OR REPLACE FUNCTION public.send_topic_notification(
  p_topic_key text,
  p_title_ar text,
  p_title_en text,
  p_body_ar text,
  p_body_en text,
  p_type text DEFAULT 'info',
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_count integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  WITH inserted_rows AS (
    INSERT INTO public.notifications (
      user_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      is_read,
      metadata
    )
    SELECT
      p.id,
      p_title_ar,
      p_title_en,
      p_body_ar,
      p_body_en,
      p_type,
      false,
      jsonb_build_object('topic', p_topic_key) || COALESCE(p_metadata, '{}'::jsonb)
    FROM public.profiles AS p
    WHERE p.is_active = true
    RETURNING id
  )
  SELECT count(*) INTO v_count
  FROM inserted_rows;

  RETURN v_count;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.send_topic_notification(
  text, text, text, text, text, text, jsonb
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.send_topic_notification(
  text, text, text, text, text, text, jsonb
) TO authenticated, service_role, supabase_auth_admin;

CREATE OR REPLACE FUNCTION public.get_lounge_bookings_page(
  p_lounge_id uuid,
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_page integer := GREATEST(COALESCE(p_page, 1), 1);
  v_page_size integer := LEAST(GREATEST(COALESCE(p_page_size, 20), 1), 100);
  v_offset integer;
  v_total_count integer;
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'p_lounge_id cannot be NULL' USING ERRCODE = '22023';
  END IF;

  PERFORM private.assert_lounge_operator(p_lounge_id, true);

  v_offset := (v_page - 1) * v_page_size;

  SELECT count(*)
  INTO v_total_count
  FROM public.bookings
  WHERE lounge_id = p_lounge_id;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'total_count', v_total_count,
        'page', v_page,
        'page_size', v_page_size,
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
          'out_visit_number', b.visit_num,
          'visit_number', b.visit_num,
          'canteen_orders', (
            SELECT COALESCE(
              jsonb_agg(
                jsonb_build_object(
                  'id', co.id,
                  'items', co.items,
                  'total_price', co.total_price,
                  'status', co.status,
                  'created_at', co.created_at
                )
              ),
              '[]'::jsonb
            )
            FROM public.canteen_orders AS co
            WHERE co.booking_id = b.id
          ),
          'extras', (
            SELECT COALESCE(
              jsonb_agg(
                jsonb_build_object(
                  'id', bi.id,
                  'extra_id', bi.extra_id,
                  'name', bi.name,
                  'quantity', bi.quantity,
                  'unit_price', bi.unit_price,
                  'total_price', bi.total_price,
                  'status', bi.status
                )
              ),
              '[]'::jsonb
            )
            FROM public.booking_items AS bi
            WHERE bi.booking_id = b.id
          )
        )
      )
    ),
    '[]'::jsonb
  )
  INTO v_result
  FROM (
    SELECT
      bk.*,
      DENSE_RANK() OVER (
        PARTITION BY
          CASE
            WHEN bk.user_id IS NOT NULL AND btrim(bk.user_id::text) <> ''
              THEN bk.user_id::text
            WHEN bk.user_phone IS NOT NULL
              AND btrim(bk.user_phone) <> ''
              AND bk.user_phone <> 'null'
              AND bk.user_phone <> 'No Phone'
              THEN btrim(bk.user_phone)
            ELSE bk.id::text
          END
        ORDER BY bk.created_at ASC
      ) AS visit_num
    FROM public.bookings AS bk
    WHERE bk.lounge_id = p_lounge_id
    ORDER BY bk.created_at DESC
    LIMIT v_page_size
    OFFSET v_offset
  ) AS b
  LEFT JOIN public.profiles AS p ON b.user_id = p.id
  LEFT JOIN public.rooms AS r ON b.room_id = r.id;

  RETURN v_result;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_lounge_bookings_page(uuid, integer, integer)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_lounge_bookings_page(uuid, integer, integer)
TO authenticated, service_role, supabase_auth_admin;

REVOKE EXECUTE ON FUNCTION public.submit_tournament_payment(
  uuid, uuid, uuid, numeric, text, text
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.submit_tournament_payment(
  uuid, uuid, uuid, numeric, text, text
) TO service_role, supabase_auth_admin;

COMMIT;
