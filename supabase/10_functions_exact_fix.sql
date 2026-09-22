-- =============================================================================
-- 10_functions_exact_fix.sql
-- Fix redeem_points, check_room_availability & get_smart_filtered_lounges
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Fix redeem_points (Add Notification & Secure search_path)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.redeem_points(
  p_user_id UUID,
  p_redemption_option_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions, pg_temp
AS $$
DECLARE
  v_cost INT;
  v_balance INT;
  v_title TEXT;
  v_reward_type TEXT;
  v_reward_value NUMERIC;
  v_voucher_id UUID;
  v_code TEXT;
  v_is_super_admin BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  ) INTO v_is_super_admin;

  IF auth.uid() IS NULL OR (auth.uid() <> p_user_id AND NOT v_is_super_admin) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT points_cost, title, reward_type, reward_value
  INTO v_cost, v_title, v_reward_type, v_reward_value
  FROM public.redemption_options
  WHERE id = p_redemption_option_id AND is_active = true;

  IF v_cost IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'المكافأة غير متاحة');
  END IF;

  SELECT points INTO v_balance FROM public.profiles WHERE id = p_user_id FOR UPDATE;

  IF COALESCE(v_balance, 0) < v_cost THEN
    RETURN jsonb_build_object('success', false, 'error', 'رصيد النقاط غير كافٍ', 'current_balance', COALESCE(v_balance, 0), 'required', v_cost);
  END IF;

  INSERT INTO public.points_transactions (user_id, points, type, reference_id, description)
  VALUES (p_user_id, -v_cost, 'redeem', p_redemption_option_id, 'صرف: ' || v_title);

  UPDATE public.profiles SET points = points - v_cost WHERE id = p_user_id;

  v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  INSERT INTO public.user_vouchers (user_id, redemption_option_id, code, reward_type, reward_value, expires_at)
  VALUES (p_user_id, p_redemption_option_id, v_code, v_reward_type, v_reward_value, NOW() + INTERVAL '30 days')
  RETURNING id INTO v_voucher_id;

  -- In-App Notification Insertion
  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    p_user_id,
    'Reward Redeemed',
    'تم استبدال النقاط بمكافأة 🎁',
    'Reward Redeemed Successfully',
    'تم استبدال ' || v_cost || ' نقطة وتجهيز كود الخصم الخاص بك: ' || v_code,
    'تم استبدال ' || v_cost || ' نقطة وتجهيز كود الخصم الخاص بك: ' || v_code,
    'Successfully redeemed ' || v_cost || ' points. Voucher code: ' || v_code,
    'points_redeemed',
    jsonb_build_object('voucher_code', v_code, 'voucher_id', v_voucher_id, 'points_cost', v_cost)
  );

  RETURN jsonb_build_object(
    'success', true,
    'new_balance', v_balance - v_cost,
    'voucher_id', v_voucher_id,
    'voucher_code', v_code,
    'expires_in_days', 30
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 2. Fix check_room_availability (Valid Enum Cast & Timestamp Comparison)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_room_availability(
  p_room_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.room_id = p_room_id
      AND b.status IN ('in_progress'::public.booking_status, 'upcoming'::public.booking_status, 'pending'::public.booking_status)
      AND (
        (b.date + b.start_time) AT TIME ZONE 'UTC' < p_end_time
        AND
        (b.date + b.end_time) AT TIME ZONE 'UTC' > p_start_time
      )
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3. Fix get_smart_filtered_lounges (Geo-Distance & Smart Sorting)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT pg_proc.oid::regprocedure AS func_signature
    FROM pg_proc
    JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
    WHERE pg_namespace.nspname = 'public'
      AND proname = 'get_smart_filtered_lounges'
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.func_signature || ' CASCADE';
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.get_smart_filtered_lounges(
  p_lat NUMERIC DEFAULT NULL,
  p_lng NUMERIC DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions, pg_temp
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(l)), '[]'::jsonb) INTO v_result
  FROM (
    SELECT
      id, name, name_ar, name_en, image_url, rating, location, city, is_open,
      CASE
        WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL AND location_point IS NOT NULL THEN
          ROUND((ST_Distance(location_point, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) / 1000.0)::numeric, 2)
        ELSE NULL
      END AS distance_km
    FROM public.lounges
    WHERE status != 'deleted'
      AND (p_city IS NULL OR city = p_city)
    ORDER BY
      CASE
        WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL AND location_point IS NOT NULL THEN
          ST_Distance(location_point, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography)
        ELSE 0
      END ASC,
      rating DESC
    LIMIT p_limit
  ) l;

  RETURN v_result;
END;
$$;

-- Grants
GRANT EXECUTE ON FUNCTION public.redeem_points TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_room_availability TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_smart_filtered_lounges TO authenticated, anon;
