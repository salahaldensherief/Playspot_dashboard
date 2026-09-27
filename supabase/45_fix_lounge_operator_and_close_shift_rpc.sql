-- 45_fix_lounge_operator_and_close_shift_rpc.sql
-- Fixes:
-- 1. private.assert_lounge_operator: Checks lounge_staff entries as well as profiles for cashiers and lounge staff.
-- 2. close_shift: Authorizes cashiers and lounge staff operators (private.can_operate_playspot_lounge) to close shifts for their lounge.

CREATE OR REPLACE FUNCTION private.assert_lounge_operator(p_lounge_id uuid, p_allow_cashier boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT p.role INTO v_role
  FROM public.profiles AS p
  WHERE p.id = auth.uid() AND COALESCE(p.is_active, true);

  IF v_role = 'super_admin' THEN
    RAISE EXCEPTION 'Platform super admins are not allowed to perform lounge operations' USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
       SELECT 1 FROM public.profiles AS p
       WHERE p.id = auth.uid() AND p.lounge_id = p_lounge_id
         AND COALESCE(p.is_active, true)
         AND p.role IN ('owner','lounge_admin','admin','manager')
     )
     AND NOT EXISTS (
       SELECT 1 FROM public.lounge_staff AS ls
       JOIN public.profiles AS p ON p.id = ls.user_id
       WHERE ls.user_id = auth.uid() AND ls.lounge_id = p_lounge_id
         AND COALESCE(p.is_active, true)
         AND ls.role IN ('lounge_owner','manager')
     )
     AND NOT (p_allow_cashier AND (
       EXISTS (
         SELECT 1 FROM public.profiles AS p
         WHERE p.id = auth.uid() AND p.lounge_id = p_lounge_id
           AND COALESCE(p.is_active, true)
           AND p.role IN ('cashier','staff')
       ) OR EXISTS (
         SELECT 1 FROM public.lounge_staff AS ls
         JOIN public.profiles AS p ON p.id = ls.user_id
         WHERE ls.user_id = auth.uid() AND ls.lounge_id = p_lounge_id
           AND COALESCE(p.is_active, true)
           AND ls.role IN ('cashier','staff')
       )
     )) THEN
    RAISE EXCEPTION 'User is not authorized for this lounge' USING ERRCODE = '42501';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.close_shift(p_shift_id uuid, p_actual_cash numeric, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_shift public.shifts;
  v_cash numeric := 0;
  v_digital numeric := 0;
  v_expenses numeric := 0;
  v_cash_expenses numeric := 0;
  v_expected numeric := 0;
  v_diff numeric := 0;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_actual_cash IS NULL OR p_actual_cash < 0 THEN
    RAISE EXCEPTION 'Actual cash cannot be negative.';
  END IF;

  SELECT * INTO v_shift
  FROM public.shifts
  WHERE id = p_shift_id
    AND status = 'open'
  FOR UPDATE;

  IF v_shift.id IS NULL THEN
    RAISE EXCEPTION 'Shift not found or already closed.';
  END IF;

  IF NOT (
    v_shift.cashier_id = auth.uid()
    OR v_shift.staff_user_id = auth.uid()
    OR private.can_operate_playspot_lounge(v_shift.lounge_id)
  ) THEN
    RAISE EXCEPTION 'Only the assigned cashier or manager can close this shift.';
  END IF;

  SELECT
    COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN payment_method <> 'cash' THEN amount ELSE 0 END), 0)
  INTO v_cash, v_digital
  FROM public.shift_payments
  WHERE shift_id = p_shift_id;

  SELECT
    COALESCE(SUM(amount), 0),
    COALESCE(SUM(CASE WHEN expense_type IN ('cash_drop', 'expense', 'other') THEN amount ELSE 0 END), 0)
  INTO v_expenses, v_cash_expenses
  FROM public.shift_expenses
  WHERE shift_id = p_shift_id;

  v_expected := COALESCE(v_shift.starting_cash, 0) + v_cash - v_cash_expenses;
  v_diff := p_actual_cash - v_expected;

  UPDATE public.shifts
  SET status = 'closed',
      closed_at = now(),
      end_time = now(),
      actual_cash_counted = p_actual_cash,
      expected_cash = v_expected,
      total_cash_sales = v_cash,
      total_digital_sales = v_digital,
      total_expenses = v_expenses,
      difference = v_diff,
      notes = COALESCE(p_notes, notes)
  WHERE id = p_shift_id;

  RETURN json_build_object(
    'success', true,
    'shift_id', p_shift_id,
    'starting_cash', COALESCE(v_shift.starting_cash, 0),
    'cash_sales', v_cash,
    'digital_sales', v_digital,
    'total_expenses', v_expenses,
    'expected_cash', v_expected,
    'actual_cash', p_actual_cash,
    'difference', v_diff,
    'status', 'closed'
  );
END;
$function$;
