-- =============================================================================
-- 30_fix_stuck_shifts_and_rpcs.sql
-- Clean up stale/inconsistent shifts and standardize shift management RPCs
-- Playspot Dashboard - 2026
-- =============================================================================

-- 1. Clean up inconsistent shift states
-- Fix any shifts where closed_at IS NOT NULL but status IS 'open'
UPDATE public.shifts
SET status = 'closed'
WHERE closed_at IS NOT NULL AND status = 'open';

-- Fix any shifts where status = 'closed' but closed_at IS NULL
UPDATE public.shifts
SET closed_at = COALESCE(updated_at, NOW())
WHERE status = 'closed' AND closed_at IS NULL;

-- 2. Drop legacy function overloads for shift management
DROP FUNCTION IF EXISTS public.get_lounge_live_shift_overview(UUID);
DROP FUNCTION IF EXISTS public.open_lounge_shift(UUID, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.close_lounge_shift(UUID, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.blind_close_shift(UUID, UUID, NUMERIC, TEXT);

-- 3. Canonical open_lounge_shift Function
CREATE OR REPLACE FUNCTION public.open_lounge_shift(
  p_lounge_id UUID,
  p_starting_cash NUMERIC DEFAULT 0,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_cashier_id UUID := auth.uid();
  v_existing_id UUID;
  v_existing_cashier TEXT;
  v_new_shift_id UUID;
BEGIN
  -- Check if there's already an active open shift for this lounge
  SELECT s.id, p.full_name
  INTO v_existing_id, v_existing_cashier
  FROM public.shifts s
  LEFT JOIN public.profiles p ON s.cashier_id = p.id
  WHERE s.lounge_id = p_lounge_id AND (s.status = 'open' OR s.closed_at IS NULL)
  ORDER BY s.start_time DESC
  LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    RAISE EXCEPTION 'يوجد شفت مفتوح بالفعل لهذا الفرع (الكاشير: %). يرجى إغلاق الشيفت أولاً.', COALESCE(v_existing_cashier, 'الحالي');
  END IF;

  INSERT INTO public.shifts (
    lounge_id,
    cashier_id,
    starting_cash,
    status,
    start_time,
    notes
  ) VALUES (
    p_lounge_id,
    v_cashier_id,
    COALESCE(p_starting_cash, 0),
    'open',
    NOW(),
    p_notes
  ) RETURNING id INTO v_new_shift_id;

  RETURN jsonb_build_object(
    'success', true,
    'shift_id', v_new_shift_id
  );
END;
$$;

-- 4. Canonical blind_close_shift Function
CREATE OR REPLACE FUNCTION public.blind_close_shift(
  p_shift_id UUID,
  p_cashier_id UUID,
  p_counted_cash NUMERIC,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_shift RECORD;
  v_cash_sales NUMERIC := 0;
  v_digital_sales NUMERIC := 0;
  v_expenses NUMERIC := 0;
  v_expected_cash NUMERIC := 0;
  v_discrepancy NUMERIC := 0;
  v_closed_shift RECORD;
BEGIN
  SELECT * INTO v_shift
  FROM public.shifts
  WHERE id = p_shift_id;

  IF v_shift IS NULL THEN
    RAISE EXCEPTION 'الشيفت غير موجود.';
  END IF;

  -- Calculate expenses
  SELECT COALESCE(SUM(amount), 0) INTO v_expenses
  FROM public.shift_expenses
  WHERE shift_id = p_shift_id;

  -- Calculate sales from payments
  SELECT
    COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN payment_method != 'cash' THEN amount ELSE 0 END), 0)
  INTO v_cash_sales, v_digital_sales
  FROM public.payments
  WHERE shift_id = p_shift_id OR (lounge_id = v_shift.lounge_id AND created_at >= v_shift.start_time);

  v_expected_cash := COALESCE(v_shift.starting_cash, 0) + v_cash_sales - v_expenses;
  v_discrepancy := COALESCE(p_counted_cash, 0) - v_expected_cash;

  UPDATE public.shifts
  SET
    status = 'closed',
    closed_at = NOW(),
    end_time = NOW(),
    actual_cash = COALESCE(p_counted_cash, 0),
    cash_revenue = v_cash_sales,
    digital_revenue = v_digital_sales,
    expenses_total = v_expenses,
    expected_cash = v_expected_cash,
    discrepancy = v_discrepancy,
    notes = COALESCE(p_notes, notes)
  WHERE id = p_shift_id
  RETURNING * INTO v_closed_shift;

  RETURN row_to_json(v_closed_shift);
END;
$$;

-- 5. Canonical close_lounge_shift Function (lounge-level fallback)
CREATE OR REPLACE FUNCTION public.close_lounge_shift(
  p_lounge_id UUID,
  p_actual_cash_counted NUMERIC DEFAULT 0,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_shift_id UUID;
BEGIN
  SELECT id INTO v_shift_id
  FROM public.shifts
  WHERE lounge_id = p_lounge_id AND (status = 'open' OR closed_at IS NULL)
  ORDER BY start_time DESC
  LIMIT 1;

  IF v_shift_id IS NULL THEN
    RAISE EXCEPTION 'لا يوجد شفت مفتوح لهذا الفرع لإغلاقه.';
  END IF;

  RETURN public.blind_close_shift(v_shift_id, auth.uid(), p_actual_cash_counted, p_notes);
END;
$$;

-- 6. Canonical get_lounge_live_shift_overview Function
CREATE OR REPLACE FUNCTION public.get_lounge_live_shift_overview(p_lounge_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_shift RECORD;
  v_cash_in_drawer NUMERIC := 0;
  v_digital_payments NUMERIC := 0;
  v_active_sessions INT := 0;
  v_closed_bookings INT := 0;
BEGIN
  -- Find active open shift for lounge
  SELECT s.*, p.full_name, p.avatar_url, p.phone
  INTO v_shift
  FROM public.shifts s
  LEFT JOIN public.profiles p ON s.cashier_id = p.id
  WHERE s.lounge_id = p_lounge_id AND (s.status = 'open' OR s.closed_at IS NULL)
  ORDER BY s.start_time DESC
  LIMIT 1;

  IF v_shift IS NULL THEN
    RETURN jsonb_build_object('has_active_shift', false);
  END IF;

  -- Calculate cash and digital payments for this shift
  SELECT
    COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN payment_method != 'cash' THEN amount ELSE 0 END), 0)
  INTO v_cash_in_drawer, v_digital_payments
  FROM public.payments
  WHERE shift_id = v_shift.id OR (lounge_id = p_lounge_id AND created_at >= v_shift.start_time);

  v_cash_in_drawer := COALESCE(v_shift.starting_cash, 0) + v_cash_in_drawer;

  -- Calculate active sessions and closed bookings
  SELECT COUNT(*) INTO v_active_sessions
  FROM public.bookings
  WHERE lounge_id = p_lounge_id AND status IN ('active', 'open', 'ongoing');

  SELECT COUNT(*) INTO v_closed_bookings
  FROM public.bookings
  WHERE lounge_id = p_lounge_id AND (shift_id = v_shift.id OR created_at >= v_shift.start_time) AND status = 'completed';

  RETURN jsonb_build_object(
    'has_active_shift', true,
    'shift_id', v_shift.id,
    'cashier_name', COALESCE(v_shift.full_name, 'الكاشير'),
    'cashier_avatar', v_shift.avatar_url,
    'cashier_phone', v_shift.phone,
    'start_time', v_shift.start_time,
    'starting_cash', COALESCE(v_shift.starting_cash, 0),
    'cash_in_drawer', v_cash_in_drawer,
    'digital_payments', v_digital_payments,
    'active_sessions', v_active_sessions,
    'closed_bookings', v_closed_bookings
  );
END;
$$;

-- 7. Grant execution permissions
GRANT EXECUTE ON FUNCTION public.open_lounge_shift(UUID, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.blind_close_shift(UUID, UUID, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.close_lounge_shift(UUID, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_lounge_live_shift_overview(UUID) TO authenticated;
