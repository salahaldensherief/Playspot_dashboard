-- 36_fix_shifts_payouts_and_cash_reconciliation.sql
-- Fixes:
-- 1. close_shift_and_calculate_z_report: Deducts shift_expenses from expected_cash so Z-Report does not show false cash shortages equal to expenses.
-- 2. open_shift: Aligns shift opening permission check with open_lounge_shift using private.assert_lounge_operator or operator checks.
-- 3. cancel_payout & fail_payout: Releases locked payments (setting payout_id = NULL) when a payout is cancelled or fails, allowing lounge owners to re-claim funds.

CREATE OR REPLACE FUNCTION public.open_shift(p_lounge_id uuid, p_opening_cash numeric)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE v_new public.shifts;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_super_admin() THEN
    PERFORM private.assert_lounge_operator(p_lounge_id, false);
  END IF;

  IF COALESCE(p_opening_cash, 0) < 0 THEN
    RAISE EXCEPTION 'Opening cash cannot be negative.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.shifts
    WHERE cashier_id = auth.uid() AND lounge_id = p_lounge_id AND status = 'open'
  ) THEN
    RAISE EXCEPTION 'Cashier already has an open shift in this lounge.';
  END IF;

  INSERT INTO public.shifts (lounge_id, cashier_id, staff_user_id, starting_cash, status, start_time, opened_at)
  VALUES (p_lounge_id, auth.uid(), auth.uid(), COALESCE(p_opening_cash, 0), 'open', now(), now())
  RETURNING * INTO v_new;

  RETURN json_build_object(
    'id', v_new.id,
    'lounge_id', v_new.lounge_id,
    'cashier_id', v_new.cashier_id,
    'starting_cash', v_new.starting_cash,
    'status', v_new.status,
    'opened_at', v_new.opened_at
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.close_shift_and_calculate_z_report(p_shift_id uuid, p_actual_cash numeric, p_notes text DEFAULT ''::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'extensions', 'pg_temp'
AS $function$
DECLARE
    v_starting_cash NUMERIC := 0;
    v_cash_revenue NUMERIC := 0;
    v_digital_revenue NUMERIC := 0;
    v_expenses NUMERIC := 0;
    v_total_expected_cash NUMERIC := 0;
    v_total_revenue NUMERIC := 0;
    v_discrepancy NUMERIC := 0;
    v_closed_shift RECORD;
BEGIN
    SELECT COALESCE(starting_cash, 0) INTO v_starting_cash
    FROM public.shifts
    WHERE id = p_shift_id;

    SELECT COALESCE(SUM(amount), 0) INTO v_cash_revenue
    FROM public.shift_payments
    WHERE shift_id = p_shift_id AND payment_method = 'cash';

    SELECT COALESCE(SUM(amount), 0) INTO v_digital_revenue
    FROM public.shift_payments
    WHERE shift_id = p_shift_id AND payment_method <> 'cash';

    SELECT COALESCE(SUM(amount), 0) INTO v_expenses
    FROM public.shift_expenses
    WHERE shift_id = p_shift_id;

    v_total_revenue := v_cash_revenue + v_digital_revenue;
    v_total_expected_cash := v_starting_cash + v_cash_revenue - v_expenses;
    v_discrepancy := p_actual_cash - v_total_expected_cash;

    UPDATE public.shifts
    SET
        status = 'closed',
        closed_at = now(),
        expected_cash = v_total_expected_cash,
        actual_cash_counted = p_actual_cash,
        total_cash_sales = v_cash_revenue,
        total_digital_sales = v_digital_revenue,
        total_expenses = v_expenses,
        difference = v_discrepancy,
        notes = p_notes
    WHERE id = p_shift_id
    RETURNING * INTO v_closed_shift;

    RETURN json_build_object(
        'shift', row_to_json(v_closed_shift),
        'summary', json_build_object(
            'starting_cash', v_starting_cash,
            'cash_revenue', v_cash_revenue,
            'digital_revenue', v_digital_revenue,
            'total_revenue', v_total_revenue,
            'total_expenses', v_expenses,
            'expected_cash', v_total_expected_cash,
            'actual_cash', p_actual_cash,
            'discrepancy', v_discrepancy
        )
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_payout(p_payout_id uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin' AND is_active) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE public.payouts
  SET status = 'cancelled', cancelled_by = auth.uid(), cancelled_at = now(), cancelled_reason = p_reason
  WHERE id = p_payout_id AND status IN ('pending','approved','failed','needs_review');

  IF NOT FOUND THEN RAISE EXCEPTION 'Payout not found or cannot be cancelled'; END IF;

  UPDATE public.payments
  SET payout_id = NULL
  WHERE payout_id = p_payout_id;

  RETURN jsonb_build_object('success', true, 'payout_id', p_payout_id, 'status', 'cancelled');
END;
$function$;

CREATE OR REPLACE FUNCTION public.fail_payout(p_payout_id uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin' AND is_active) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE public.payouts
  SET status = 'failed', failure_reason = p_reason
  WHERE id = p_payout_id AND status IN ('approved','processing');

  IF NOT FOUND THEN RAISE EXCEPTION 'Payout not found or not processing'; END IF;

  UPDATE public.payments
  SET payout_id = NULL
  WHERE payout_id = p_payout_id;

  RETURN jsonb_build_object('success', true, 'payout_id', p_payout_id, 'status', 'failed');
END;
$function$;
