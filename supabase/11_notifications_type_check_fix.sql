-- =============================================================================
-- 11_notifications_type_check_fix.sql
-- Fix Notification Types to Match notifications_type CHECK Constraint Exactly
-- =============================================================================

-- 1. Fix redeem_points (use type = 'loyalty_points')
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

  -- In-App Notification (Type strictly matching CHECK constraint 'loyalty_points')
  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    p_user_id,
    'Reward Redeemed',
    'تم استبدال النقاط بمكافأة 🎁',
    'Reward Redeemed Successfully',
    'تم استبدال ' || v_cost || ' نقطة وتجهيز كود الخصم الخاص بك: ' || v_code,
    'تم استبدال ' || v_cost || ' نقطة وتجهيز كود الخصم الخاص بك: ' || v_code,
    'Successfully redeemed ' || v_cost || ' points. Voucher code: ' || v_code,
    'loyalty_points',
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


-- 2. Fix award_points_for_booking (use type = 'loyalty_points')
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

  -- In-App Notification (Type strictly matching CHECK constraint 'loyalty_points')
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


-- 3. Fix review_kyc (use type = 'kyc_approved' / 'kyc_rejected')
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

  -- In-App Notification (Type strictly matching CHECK constraint 'kyc_approved' / 'kyc_rejected')
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


-- 4. Fix approve_payout (use type = 'payout')
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

  -- In-App Notification (Type strictly matching CHECK constraint 'payout')
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
      'payout',
      jsonb_build_object('payout_id', p_payout_id, 'status', 'approved', 'amount', v_amount)
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'payout_id', p_payout_id, 'status', 'approved');
END;
$$;

-- Grants
GRANT EXECUTE ON FUNCTION public.redeem_points TO authenticated;
GRANT EXECUTE ON FUNCTION public.award_points_for_booking TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_kyc TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_payout TO authenticated;
