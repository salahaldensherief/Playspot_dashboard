BEGIN;

CREATE OR REPLACE FUNCTION public.add_shift_expense(
  p_shift_id uuid,
  p_amount numeric,
  p_reason text,
  p_type text DEFAULT 'expense'
)
RETURNS public.shift_expenses
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','private','auth','pg_temp'
AS $$
DECLARE
  v_shift public.shifts%ROWTYPE;
  v_expense public.shift_expenses%ROWTYPE;
  v_type text := lower(btrim(coalesce(p_type,'expense')));
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Expense amount must be greater than zero'
      USING ERRCODE='22023';
  END IF;

  SELECT *
  INTO v_shift
  FROM public.shifts
  WHERE id = p_shift_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shift not found' USING ERRCODE='P0002';
  END IF;

  IF v_shift.status <> 'open' OR v_shift.closed_at IS NOT NULL THEN
    RAISE EXCEPTION 'Cannot add expense to a closed shift'
      USING ERRCODE='55000';
  END IF;

  IF NOT (
    public.is_super_admin()
    OR v_shift.cashier_id = auth.uid()
    OR public.is_lounge_member_or_admin(v_shift.lounge_id)
  ) THEN
    RAISE EXCEPTION 'Not authorized for this shift'
      USING ERRCODE='42501';
  END IF;

  IF v_type NOT IN ('cash_drop','expense','other') THEN
    v_type := 'expense';
  END IF;

  INSERT INTO public.shift_expenses(
    shift_id,
    lounge_id,
    amount,
    reason,
    type,
    expense_type,
    created_by
  )
  VALUES(
    v_shift.id,
    v_shift.lounge_id,
    p_amount,
    btrim(coalesce(p_reason,'')),
    v_type,
    v_type,
    auth.uid()
  )
  RETURNING * INTO v_expense;

  RETURN v_expense;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.add_shift_expense(uuid,numeric,text,text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.add_shift_expense(uuid,numeric,text,text)
TO authenticated, service_role;

DROP POLICY IF EXISTS "Cashiers manage own open-shift expenses"
ON public.shift_expenses;
DROP POLICY IF EXISTS "Managers manage lounge shift expenses"
ON public.shift_expenses;
DROP POLICY IF EXISTS shift_expenses_policy
ON public.shift_expenses;
DROP POLICY IF EXISTS shift_expenses_select_scope
ON public.shift_expenses;

CREATE POLICY shift_expenses_select_scope
ON public.shift_expenses
FOR SELECT
TO authenticated
USING (
  public.is_super_admin()
  OR public.is_lounge_member_or_admin(lounge_id)
  OR EXISTS (
    SELECT 1
    FROM public.shifts s
    WHERE s.id = shift_expenses.shift_id
      AND s.cashier_id = (select auth.uid())
  )
);

COMMIT;
