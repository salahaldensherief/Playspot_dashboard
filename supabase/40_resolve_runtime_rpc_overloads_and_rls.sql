-- 40_resolve_runtime_rpc_overloads_and_rls.sql
-- Fixes runtime errors reported during live app execution:
-- 1. Drops overloaded versions of get_all_bookings_admin and replaces with a single canonical function to eliminate PGRST203 parameter order ambiguity.
-- 2. Updates lounges_write_policy with_check to permit authorized lounge managers & staff operators to update lounge location, city, and properties.
-- 3. Grants execute permissions on get_active_lounge_requests_page and get_pending_extension_requests to authenticated role.

DROP FUNCTION IF EXISTS public.get_all_bookings_admin(text, uuid, integer, integer);
DROP FUNCTION IF EXISTS public.get_all_bookings_admin(uuid, text, integer, integer);

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
      AND (p_status IS NULL OR bk.status = p_status)
    ORDER BY bk.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) b
  LEFT JOIN public.profiles p ON b.user_id = p.id
  LEFT JOIN public.rooms r ON b.room_id = r.id;

  RETURN v_result;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_all_bookings_admin(uuid, text, integer, integer) TO authenticated;

DROP POLICY IF EXISTS "lounges_write_policy" ON public.lounges;
CREATE POLICY "lounges_write_policy" ON public.lounges
  FOR ALL
  TO authenticated
  USING (is_super_admin() OR (owner_id = auth.uid()) OR is_lounge_member_or_admin(id) OR private.can_operate_playspot_lounge(id))
  WITH CHECK (is_super_admin() OR (owner_id = auth.uid()) OR is_lounge_member_or_admin(id) OR private.can_operate_playspot_lounge(id));

GRANT EXECUTE ON FUNCTION public.get_active_lounge_requests_page TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_extension_requests TO authenticated;
