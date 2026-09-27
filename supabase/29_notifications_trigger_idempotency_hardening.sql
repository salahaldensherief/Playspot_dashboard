-- =============================================================================
-- 29_notifications_trigger_idempotency_hardening.sql
-- Harden SQL Functions generating In-App Notifications to Guarantee Idempotency
-- =============================================================================

-- 1. Harden award_points_for_booking against duplicate points & duplicate notifications
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
  -- Idempotency check: Skip if points were already awarded for this booking
  IF EXISTS (
    SELECT 1 FROM public.points_transactions
    WHERE reference_id = p_booking_id AND type = 'earn'
  ) THEN
    RAISE NOTICE 'Points already awarded for booking %', p_booking_id;
    RETURN;
  END IF;

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

  -- In-App Notification (Idempotent single emit)
  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    v_user_id,
    'Points Earned',
    'نقاط ولاء جديدة! 🎉',
    'New Loyalty Points Earned!',
    'تم إضافة ' || v_points || ' نقطة ولاء لحسابك مقابل حجزك',
    'تم إضافة ' || v_points || ' نقطة ولاء لحسابك مقابل حجزك',
    'You earned ' || v_points || ' loyalty points for your booking!',
    'loyalty_points',
    jsonb_build_object('booking_id', p_booking_id, 'points', v_points)
  );
END;
$$;


-- 2. Harden review_kyc against duplicate status notifications
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
  v_current_status TEXT;
  v_new_status TEXT := CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only Super Admin can review KYC';
  END IF;

  SELECT status INTO v_current_status
  FROM public.kyc_submissions
  WHERE user_id = p_user_id;

  IF v_current_status IS NULL THEN
    RAISE EXCEPTION 'KYC submission not found for user %', p_user_id;
  END IF;

  -- Idempotency check: Skip duplicate status update & notification if already in target status
  IF v_current_status = v_new_status THEN
    RAISE NOTICE 'KYC submission for user % is already in status %', p_user_id, v_new_status;
    RETURN;
  END IF;

  UPDATE public.kyc_submissions
  SET status = v_new_status,
      notes = p_notes,
      updated_at = NOW()
  WHERE user_id = p_user_id;

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

  -- In-App Notification (Triggered strictly on status transition)
  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    p_user_id,
    CASE WHEN p_approve THEN 'KYC Approved' ELSE 'KYC Rejected' END,
    CASE WHEN p_approve THEN 'تم توثيق الحساب (KYC)' ELSE 'تم رفض توثيق الحساب (KYC)' END,
    CASE WHEN p_approve THEN 'Your KYC verification has been approved' ELSE 'Your KYC verification has been rejected' END,
    CASE WHEN p_approve THEN 'تهانينا! تم اعتماد وتوثيق حسابك بنجاح' ELSE COALESCE('تم رفض طلب التوثيق: ' || p_notes, 'تم رفض طلب التوثيق') END,
    CASE WHEN p_approve THEN 'تهانينا! تم اعتماد وتوثيق حسابك بنجاح' ELSE COALESCE('تم رفض طلب التوثيق: ' || p_notes, 'تم رفض طلب التوثيق') END,
    CASE WHEN p_approve THEN 'Congratulations! Your KYC account verification was approved.' ELSE COALESCE('KYC verification rejected: ' || p_notes, 'KYC verification rejected.') END,
    CASE WHEN p_approve THEN 'kyc_approved' ELSE 'kyc_rejected' END,
    jsonb_build_object('approved', p_approve, 'notes', p_notes)
  );
END;
$$;

-- Grants
GRANT EXECUTE ON FUNCTION public.award_points_for_booking TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_kyc TO authenticated;
