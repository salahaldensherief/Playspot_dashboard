BEGIN;

CREATE OR REPLACE FUNCTION private.platform_commission_rate()
RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO ''
AS $function$
  SELECT 0.15::numeric;
$function$;

REVOKE EXECUTE ON FUNCTION private.platform_commission_rate()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION private.platform_commission_rate()
TO service_role, supabase_auth_admin;

ALTER TABLE public.payments
ADD COLUMN IF NOT EXISTS commission_rate numeric;

UPDATE public.payments
SET commission_rate = CASE
  WHEN amount > 0 AND commission IS NOT NULL
    THEN round(commission / amount, 6)
  ELSE private.platform_commission_rate()
END
WHERE commission_rate IS NULL;

ALTER TABLE public.payments
ALTER COLUMN commission_rate DROP DEFAULT;

ALTER TABLE public.payments
ALTER COLUMN commission_rate SET NOT NULL;

ALTER TABLE public.payments
DROP CONSTRAINT IF EXISTS payments_commission_rate_valid;

ALTER TABLE public.payments
ADD CONSTRAINT payments_commission_rate_valid
CHECK (commission_rate >= 0 AND commission_rate <= 1);

CREATE OR REPLACE FUNCTION public.enforce_payment_financials()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_rate numeric := private.platform_commission_rate();
BEGIN
  IF NEW.amount IS NULL OR NEW.amount < 0 THEN
    RAISE EXCEPTION 'Payment amount must be non-negative'
      USING ERRCODE = '22023';
  END IF;

  NEW.commission_rate := v_rate;
  NEW.commission := round(NEW.amount * v_rate, 2);
  NEW.net_to_lounge := NEW.amount - NEW.commission;

  RETURN NEW;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.enforce_payment_financials()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.enforce_payment_financials()
TO service_role, supabase_auth_admin;

DROP TRIGGER IF EXISTS trg_enforce_payment_financials_insert
ON public.payments;

CREATE TRIGGER trg_enforce_payment_financials_insert
BEFORE INSERT ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.enforce_payment_financials();

DROP TRIGGER IF EXISTS trg_enforce_payment_financials_update
ON public.payments;

CREATE TRIGGER trg_enforce_payment_financials_update
BEFORE UPDATE OF amount, commission, net_to_lounge, commission_rate
ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.enforce_payment_financials();

-- Keep payout aggregation on the snapshotted payment truth. The fallback only
-- exists for pre-migration rows and should become unreachable once every row
-- has canonical commission/net values.
CREATE OR REPLACE FUNCTION public.get_pending_payouts_overview()
RETURNS TABLE(
  lounge_id uuid,
  lounge_name text,
  pending_amount numeric,
  total_transactions bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    p.lounge_id,
    COALESCE(l.name_ar, l.name_en, l.name)::text,
    COALESCE(SUM(p.net_to_lounge), 0),
    COUNT(*)
  FROM public.payments AS p
  JOIN public.lounges AS l ON l.id = p.lounge_id
  WHERE p.status = 'completed'
    AND p.payout_id IS NULL
  GROUP BY p.lounge_id, COALESCE(l.name_ar, l.name_en, l.name)
  HAVING COALESCE(SUM(p.net_to_lounge), 0) > 0;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_pending_payouts_overview()
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_pending_payouts_overview()
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
