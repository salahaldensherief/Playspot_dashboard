-- Migration 17: Dashboard Integration Guide RPCs & Constraints
-- Implements Vouchers, Manual Discounts, Hold Slot Overlap Prevention,
-- Tournament Payments Row Locking, and Booking Lifecycle Statuses.

-- ==========================================
-- 1. BOOKINGS LIFECYCLE & REJECTION REASON
-- ==========================================

-- Ensure rejection_reason column exists on public.bookings
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Update status check constraint on public.bookings if constrained
DO $$
BEGIN
    ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_status_check;
    ALTER TABLE public.bookings ADD CONSTRAINT bookings_status_check
      CHECK (status IN ('pending', 'upcoming', 'in_progress', 'completed', 'cancelled', 'rejected'));
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not recreate bookings_status_check constraint: %', SQLERRM;
END $$;


-- ==========================================
-- 2. VOUCHERS & MANUAL DISCOUNTS RPCS
-- ==========================================

-- A. validate_voucher_by_code
CREATE OR REPLACE FUNCTION public.validate_voucher_by_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_clean_code TEXT;
  v_voucher RECORD;
  v_reward_type TEXT;
  v_reward_value NUMERIC;
  v_min_spend NUMERIC := 0;
BEGIN
  v_clean_code := UPPER(TRIM(p_code));
  IF v_clean_code IS NULL OR v_clean_code = '' THEN
    RETURN jsonb_build_object('valid', false, 'is_valid', false, 'error', 'يرجى إدخال كود القسيمة');
  END IF;

  -- 1. Check user_vouchers table
  SELECT * INTO v_voucher
  FROM public.user_vouchers
  WHERE UPPER(TRIM(code)) = v_clean_code
  LIMIT 1;

  IF v_voucher.id IS NOT NULL THEN
    IF COALESCE(v_voucher.is_used, false) = true THEN
      RETURN jsonb_build_object('valid', false, 'is_valid', false, 'error', 'تم استخدام هذه القسيمة من قبل');
    END IF;

    IF v_voucher.expires_at IS NOT NULL AND v_voucher.expires_at < NOW() THEN
      RETURN jsonb_build_object('valid', false, 'is_valid', false, 'error', 'هذه القسيمة منتهية الصلاحية');
    END IF;

    v_reward_type := COALESCE(v_voucher.reward_type, 'discount_fixed');
    v_reward_value := COALESCE(v_voucher.reward_value, 0);

    RETURN jsonb_build_object(
      'valid', true,
      'is_valid', true,
      'voucher_id', v_voucher.id,
      'code', v_clean_code,
      'reward_type', v_reward_type,
      'reward_value', v_reward_value,
      'discount_amount', v_reward_value,
      'min_spend', v_min_spend
    );
  END IF;

  -- 2. Fallback check on public.vouchers table if exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'vouchers') THEN
    EXECUTE 'SELECT id, reward_type, reward_value, min_spend, is_active, expires_at FROM public.vouchers WHERE UPPER(TRIM(code)) = $1 LIMIT 1'
    INTO v_voucher
    USING v_clean_code;

    IF v_voucher.id IS NOT NULL THEN
      IF COALESCE(v_voucher.is_active, true) = false THEN
        RETURN jsonb_build_object('valid', false, 'is_valid', false, 'error', 'القسيمة غير مفعلة');
      END IF;

      IF v_voucher.expires_at IS NOT NULL AND v_voucher.expires_at < NOW() THEN
        RETURN jsonb_build_object('valid', false, 'is_valid', false, 'error', 'هذه القسيمة منتهية الصلاحية');
      END IF;

      RETURN jsonb_build_object(
        'valid', true,
        'is_valid', true,
        'voucher_id', v_voucher.id,
        'code', v_clean_code,
        'reward_type', COALESCE(v_voucher.reward_type, 'discount_fixed'),
        'reward_value', COALESCE(v_voucher.reward_value, 0),
        'discount_amount', COALESCE(v_voucher.reward_value, 0),
        'min_spend', COALESCE(v_voucher.min_spend, 0)
      );
    END IF;
  END IF;

  RETURN jsonb_build_object('valid', false, 'is_valid', false, 'error', 'كود القسيمة غير صالح أو غير موجود');
END;
$$;


-- B. consume_voucher_by_code
CREATE OR REPLACE FUNCTION public.consume_voucher_by_code(
  p_code TEXT,
  p_booking_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_clean_code TEXT;
BEGIN
  v_clean_code := UPPER(TRIM(p_code));

  UPDATE public.user_vouchers
  SET is_used = true,
      used_at = NOW(),
      used_in_booking_id = p_booking_id
  WHERE UPPER(TRIM(code)) = v_clean_code;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'vouchers') THEN
    EXECUTE 'UPDATE public.vouchers SET is_active = false WHERE UPPER(TRIM(code)) = $1'
    USING v_clean_code;
  END IF;

  RETURN jsonb_build_object('success', true, 'code', v_clean_code, 'booking_id', p_booking_id);
END;
$$;


-- C. calculate_booking_total
CREATE OR REPLACE FUNCTION public.calculate_booking_total(
  p_room_id UUID,
  p_duration_hours NUMERIC,
  p_voucher_code TEXT DEFAULT NULL,
  p_manual_discount NUMERIC DEFAULT 0,
  p_manual_discount_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_room_rate NUMERIC := 0;
  v_base_subtotal NUMERIC := 0;
  v_voucher_validation JSONB;
  v_voucher_discount NUMERIC := 0;
  v_staff_discount NUMERIC := 0;
  v_final_total NUMERIC := 0;
  v_reward_type TEXT;
  v_reward_val NUMERIC;
BEGIN
  -- 1. Get room hourly rate
  SELECT COALESCE(price_per_hour, hourly_rate_single, 0)
  INTO v_room_rate
  FROM public.rooms
  WHERE id = p_room_id;

  v_base_subtotal := ROUND((COALESCE(p_duration_hours, 1) * v_room_rate)::NUMERIC, 2);

  -- 2. Calculate voucher discount
  IF p_voucher_code IS NOT NULL AND TRIM(p_voucher_code) != '' THEN
    v_voucher_validation := public.validate_voucher_by_code(p_voucher_code);
    IF (v_voucher_validation->>'valid')::BOOLEAN = true THEN
      v_reward_type := v_voucher_validation->>'reward_type';
      v_reward_val := (v_voucher_validation->>'reward_value')::NUMERIC;

      IF v_reward_type = 'percentage' THEN
        v_voucher_discount := ROUND((v_base_subtotal * (v_reward_val / 100.0))::NUMERIC, 2);
      ELSIF v_reward_type = 'free_hour' THEN
        v_voucher_discount := v_room_rate;
      ELSE
        v_voucher_discount := v_reward_val;
      END IF;
    END IF;
  END IF;

  -- 3. Calculate staff manual discount
  v_staff_discount := COALESCE(p_manual_discount, 0);

  -- 4. Calculate final total
  v_final_total := GREATEST(0, v_base_subtotal - v_voucher_discount - v_staff_discount);

  RETURN jsonb_build_object(
    'base_subtotal', v_base_subtotal,
    'voucher_discount', v_voucher_discount,
    'staff_manual_discount', v_staff_discount,
    'manual_discount_reason', COALESCE(p_manual_discount_reason, ''),
    'final_total', v_final_total
  );
END;
$$;


-- ==========================================
-- 3. HOLD SLOT & OVERLAP PREVENTION
-- ==========================================

-- Ensure booking_holds table exists
CREATE TABLE IF NOT EXISTS public.booking_holds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  user_id UUID,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for hold queries
CREATE INDEX IF NOT EXISTS idx_booking_holds_room_time ON public.booking_holds(room_id, start_time, end_time, expires_at);

-- verify_and_hold_slot
CREATE OR REPLACE FUNCTION public.verify_and_hold_slot(
  p_room_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ,
  p_user_id UUID DEFAULT NULL,
  p_hold_minutes INT DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_has_overlap BOOLEAN := false;
  v_expires_at TIMESTAMPTZ;
  v_date DATE;
  v_start_time_txt TEXT;
  v_end_time_txt TEXT;
BEGIN
  v_date := p_start_time::DATE;
  v_start_time_txt := to_char(p_start_time, 'HH24:MI:SS');
  v_end_time_txt := to_char(p_end_time, 'HH24:MI:SS');

  -- 1. Check overlap against existing bookings
  -- Considers 15-min interval granularity & active booking statuses ('pending', 'upcoming', 'in_progress')
  SELECT EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.room_id = p_room_id
      AND b.status IN ('pending', 'upcoming', 'in_progress')
      AND (
        (b.date IS NOT NULL AND b.date = v_date AND b.start_time::TIME < v_end_time_txt::TIME AND b.end_time::TIME > v_start_time_txt::TIME)
        OR
        (b.created_at IS NOT NULL AND b.created_at::DATE = v_date AND b.start_time::TIME < v_end_time_txt::TIME AND b.end_time::TIME > v_start_time_txt::TIME)
      )
  ) INTO v_has_overlap;

  IF v_has_overlap THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'SLOT_OVERLAP_CONFLICT',
      'message', 'The selected time slot overlaps with an existing booking or hold.'
    );
  END IF;

  -- 2. Check overlap against active temporary holds
  SELECT EXISTS (
    SELECT 1 FROM public.booking_holds h
    WHERE h.room_id = p_room_id
      AND h.expires_at > NOW()
      AND h.start_time < p_end_time
      AND h.end_time > p_start_time
      AND (p_user_id IS NULL OR h.user_id != p_user_id)
  ) INTO v_has_overlap;

  IF v_has_overlap THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'SLOT_OVERLAP_CONFLICT',
      'message', 'The selected time slot overlaps with an existing booking or hold.'
    );
  END IF;

  -- 3. Create temporary slot hold
  v_expires_at := NOW() + (p_hold_minutes || ' minutes')::INTERVAL;

  INSERT INTO public.booking_holds (room_id, user_id, start_time, end_time, expires_at)
  VALUES (p_room_id, p_user_id, p_start_time, p_end_time, v_expires_at);

  RETURN jsonb_build_object(
    'success', true,
    'hold_expires_at', to_char(v_expires_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
  );
END;
$$;


-- ==========================================
-- 4. TOURNAMENT PAYMENTS CONSTRAINT & LOCK
-- ==========================================

-- Ensure tournament_payments table exists
CREATE TABLE IF NOT EXISTS public.tournament_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  participant_id UUID NOT NULL REFERENCES public.tournament_participants(id) ON DELETE CASCADE,
  user_id UUID,
  amount NUMERIC NOT NULL DEFAULT 0,
  receipt_url TEXT,
  status TEXT DEFAULT 'under_review',
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tournament_id, participant_id)
);

-- submit_tournament_payment with FOR UPDATE row locking
CREATE OR REPLACE FUNCTION public.submit_tournament_payment(
  p_tournament_id UUID,
  p_participant_id UUID,
  p_amount NUMERIC DEFAULT 0,
  p_receipt_url TEXT DEFAULT NULL,
  p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_existing RECORD;
BEGIN
  -- Perform Row-Level Lock (FOR UPDATE)
  SELECT * INTO v_existing
  FROM public.tournament_payments
  WHERE tournament_id = p_tournament_id AND participant_id = p_participant_id
  FOR UPDATE;

  IF v_existing.id IS NOT NULL AND v_existing.status IN ('under_review', 'approved') THEN
    RETURN jsonb_build_object(
      'success', true,
      'already_submitted', true,
      'message', 'Payment receipt already submitted and under review.'
    );
  END IF;

  IF v_existing.id IS NOT NULL THEN
    UPDATE public.tournament_payments
    SET amount = p_amount,
        receipt_url = COALESCE(p_receipt_url, receipt_url),
        status = 'under_review',
        submitted_at = NOW()
    WHERE id = v_existing.id;
  ELSE
    INSERT INTO public.tournament_payments (
      tournament_id, participant_id, user_id, amount, receipt_url, status
    ) VALUES (
      p_tournament_id, p_participant_id, p_user_id, p_amount, p_receipt_url, 'under_review'
    );
  END IF;

  -- Update status in tournament_participants if exists
  UPDATE public.tournament_participants
  SET payment_status = 'pending_verification',
      registration_status = 'pending_verification'
  WHERE id = p_participant_id;

  RETURN jsonb_build_object(
    'success', true,
    'already_submitted', false,
    'message', 'Payment receipt submitted successfully.'
  );
END;
$$;


-- Grant execution permissions on all RPCs
GRANT EXECUTE ON FUNCTION public.validate_voucher_by_code(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.consume_voucher_by_code(TEXT, UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.calculate_booking_total(UUID, NUMERIC, TEXT, NUMERIC, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.verify_and_hold_slot(UUID, TIMESTAMPTZ, TIMESTAMPTZ, UUID, INT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.submit_tournament_payment(UUID, UUID, NUMERIC, TEXT, UUID) TO authenticated, anon;
