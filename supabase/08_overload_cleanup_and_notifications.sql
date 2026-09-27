-- =============================================================================
-- 08_overload_cleanup_and_notifications.sql
-- Drop Function Overloads & Add In-App Notifications for Key System Actions
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Drop All Duplicate Overloaded Variants for the 7 Functions
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
      AND proname IN (
        'check_room_availability',
        'get_current_user_role',
        'get_role_permissions',
        'request_staff_assistance',
        'start_booking_session',
        'submit_lounge_review',
        'get_smart_filtered_lounges'
      )
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.func_signature || ' CASCADE';
  END LOOP;
END $$;


-- -----------------------------------------------------------------------------
-- 2. Re-create Clean, Canonical Versions for the 7 Functions
-- -----------------------------------------------------------------------------

-- A. check_room_availability
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
    SELECT 1 FROM public.bookings
    WHERE room_id = p_room_id
      AND status IN ('in_progress', 'confirmed', 'upcoming')
      AND (
        (start_time < p_end_time AND end_time > p_start_time)
      )
  );
END;
$$;

-- B. get_current_user_role
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN 'anon';
  END IF;

  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = auth.uid();

  RETURN COALESCE(v_role, 'authenticated');
END;
$$;

-- C. get_role_permissions
CREATE OR REPLACE FUNCTION public.get_role_permissions(p_role TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_permissions JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(permission), '[]'::jsonb) INTO v_permissions
  FROM public.role_permissions
  WHERE role = p_role;

  RETURN v_permissions;
END;
$$;

-- D. request_staff_assistance
CREATE OR REPLACE FUNCTION public.request_staff_assistance(
  p_lounge_id UUID,
  p_room_id UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_call_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated request';
  END IF;

  INSERT INTO public.service_calls (
    lounge_id,
    room_id,
    user_id,
    notes,
    status,
    created_at
  )
  VALUES (
    p_lounge_id,
    p_room_id,
    auth.uid(),
    p_notes,
    'pending',
    NOW()
  )
  RETURNING id INTO v_call_id;

  RETURN jsonb_build_object('success', true, 'call_id', v_call_id);
END;
$$;

-- E. start_booking_session
CREATE OR REPLACE FUNCTION public.start_booking_session(p_booking_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_lounge_id UUID;
  v_room_id UUID;
BEGIN
  SELECT lounge_id, room_id INTO v_lounge_id, v_room_id
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_lounge_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Booking not found');
  END IF;

  IF NOT public.is_lounge_admin(v_lounge_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
  END IF;

  UPDATE public.bookings
  SET status = 'in_progress',
      checked_in_at = NOW(),
      updated_at = NOW()
  WHERE id = p_booking_id;

  IF v_room_id IS NOT NULL THEN
    UPDATE public.rooms
    SET status = 'occupied',
        is_available = false,
        updated_at = NOW()
    WHERE id = v_room_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'booking_id', p_booking_id);
END;
$$;

-- F. submit_lounge_review
CREATE OR REPLACE FUNCTION public.submit_lounge_review(
  p_lounge_id UUID,
  p_rating NUMERIC,
  p_comment TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_review_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated request';
  END IF;

  INSERT INTO public.lounge_reviews (
    lounge_id,
    user_id,
    rating,
    comment,
    created_at
  )
  VALUES (
    p_lounge_id,
    auth.uid(),
    p_rating,
    p_comment,
    NOW()
  )
  RETURNING id INTO v_review_id;

  -- Update average lounge rating
  UPDATE public.lounges
  SET rating = (SELECT ROUND(AVG(rating)::numeric, 1) FROM public.lounge_reviews WHERE lounge_id = p_lounge_id),
      total_reviews = (SELECT COUNT(*) FROM public.lounge_reviews WHERE lounge_id = p_lounge_id)
  WHERE id = p_lounge_id;

  RETURN jsonb_build_object('success', true, 'review_id', v_review_id);
END;
$$;

-- G. get_smart_filtered_lounges
CREATE OR REPLACE FUNCTION public.get_smart_filtered_lounges(
  p_city TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(l)), '[]'::jsonb) INTO v_result
  FROM (
    SELECT id, name, name_ar, name_en, image_url, rating, location, city, is_open
    FROM public.lounges
    WHERE status != 'deleted'
      AND (p_city IS NULL OR city = p_city)
    ORDER BY rating DESC
    LIMIT p_limit
  ) l;

  RETURN v_result;
END;
$$;

-- Grants
GRANT EXECUTE ON FUNCTION public.check_room_availability TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_current_user_role TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_role_permissions TO authenticated;
GRANT EXECUTE ON FUNCTION public.request_staff_assistance TO authenticated;
GRANT EXECUTE ON FUNCTION public.start_booking_session TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_lounge_review TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_smart_filtered_lounges TO authenticated, anon;


-- -----------------------------------------------------------------------------
-- 3. Add In-App Notifications Insertion to Key Functions
-- -----------------------------------------------------------------------------

-- A. Notification on KYC Review
CREATE OR REPLACE FUNCTION public.review_kyc(
  p_user_id UUID,
  p_approve BOOLEAN,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_kyc_updated INT;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only Super Admin can review KYC';
  END IF;

  UPDATE public.kyc_submissions
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      notes = p_notes,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  GET DIAGNOSTICS v_kyc_updated = ROW_COUNT;
  IF v_kyc_updated = 0 THEN
    RAISE EXCEPTION 'KYC submission not found for user %', p_user_id;
  END IF;

  IF p_approve THEN
    UPDATE public.lounges
    SET status = 'active', is_open = true, is_active = true
    WHERE owner_id = p_user_id;

    UPDATE public.profiles
    SET role = 'owner', is_active = true, is_setup_completed = true, updated_at = NOW()
    WHERE id = p_user_id;
  ELSE
    UPDATE public.lounges
    SET status = 'rejected', is_open = false, is_active = false
    WHERE owner_id = p_user_id;

    UPDATE public.profiles
    SET is_active = false, is_setup_completed = false, updated_at = NOW()
    WHERE id = p_user_id;
  END IF;

  -- In-App Notification
  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    p_user_id,
    CASE WHEN p_approve THEN 'KYC Approved' ELSE 'KYC Rejected' END,
    CASE WHEN p_approve THEN 'تم توثيق الحساب (KYC)' ELSE 'تم رفض توثيق الحساب (KYC)' END,
    CASE WHEN p_approve THEN 'Your KYC verification has been approved' ELSE 'Your KYC verification has been rejected' END,
    CASE WHEN p_approve THEN 'تهانينا! تم اعتماد وتوثيق حسابك بنجاح' ELSE COALESCE('تم رفض طلب التوثيق: ' || p_notes, 'تم رفض طلب التوثيق') END,
    CASE WHEN p_approve THEN 'تهانينا! تم اعتماد وتوثيق حسابك بنجاح' ELSE COALESCE('تم رفض طلب التوثيق: ' || p_notes, 'تم رفض طلب التوثيق') END,
    CASE WHEN p_approve THEN 'Congratulations! Your KYC account verification was approved.' ELSE COALESCE('KYC verification rejected: ' || p_notes, 'KYC verification rejected.') END,
    'kyc_status',
    jsonb_build_object('approved', p_approve, 'notes', p_notes)
  );
END;
$$;

-- B. Notification on Payout Approval
CREATE OR REPLACE FUNCTION public.approve_payout(
  p_payout_id UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_owner_id UUID;
  v_amount NUMERIC;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE public.payouts
  SET status = 'approved', approved_by = auth.uid(), approved_at = NOW(), notes = COALESCE(p_notes, notes)
  WHERE id = p_payout_id AND status = 'pending'
  RETURNING created_by, total_amount INTO v_owner_id, v_amount;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payout not found or not pending';
  END IF;

  -- In-App Notification for Lounge Owner
  IF v_owner_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
    VALUES (
      v_owner_id,
      'Payout Request Approved',
      'تم اعتماد طلب سحب الأرباح',
      'Payout Request Approved',
      'تمت الموافقة على طلب سحب الأرباح بقيمة ' || v_amount || ' ج.م',
      'تمت الموافقة على طلب سحب الأرباح بقيمة ' || v_amount || ' ج.م',
      'Your payout request for EGP ' || v_amount || ' has been approved.',
      'payout_status',
      jsonb_build_object('payout_id', p_payout_id, 'status', 'approved', 'amount', v_amount)
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'payout_id', p_payout_id, 'status', 'approved');
END;
$$;

-- C. Notification on Awarding Points
CREATE OR REPLACE FUNCTION public.award_points_for_booking(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_user_id UUID;
  v_amount NUMERIC;
  v_points INT;
BEGIN
  SELECT user_id, total_price INTO v_user_id, v_amount
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  v_points := GREATEST(1, ROUND(v_amount / 10.0)::INT);

  UPDATE public.profiles
  SET points = COALESCE(points, 0) + v_points
  WHERE id = v_user_id;

  INSERT INTO public.points_transactions (user_id, points, type, reference_id, description)
  VALUES (v_user_id, v_points, 'earn', p_booking_id, 'نقاط حجز رقم: ' || p_booking_id);

  -- In-App Notification
  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    v_user_id,
    'Points Earned',
    'نقاط ولاء جديدة! 🎉',
    'New Loyalty Points Earned!',
    'تم إضافة ' || v_points || ' نقطة ولاء لحسابك مقابل حجزك',
    'تم إضافة ' || v_points || ' نقطة ولاء لحسابك مقابل حجزك',
    'You earned ' || v_points || ' loyalty points for your booking!',
    'points_awarded',
    jsonb_build_object('booking_id', p_booking_id, 'points', v_points)
  );
END;
$$;
